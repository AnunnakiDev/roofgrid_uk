import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_quote_sync_entry.dart';
import 'package:roofgrid_uk/app/labour_pricing/services/labour_quotes_sync_queue_storage.dart';

void main() {
  group('LabourQuotesSyncQueueStorage', () {
    late Box<Map> box;
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('labour_sync_queue_test_');
      Hive.init(tempDir.path);
      box = await Hive.openBox<Map>('test_labour_quotes_sync_queue');
      await box.clear();
    });

    tearDown(() async {
      if (box.isOpen) {
        await box.clear();
        await box.close();
      }
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('enqueue and load round-trips entries', () async {
      final entry = LabourQuoteSyncEntry(
        quoteId: 'q1',
        operation: LabourQuoteSyncOperation.save,
        queuedAt: DateTime(2026, 4, 1, 10),
      );

      await LabourQuotesSyncQueueStorage.enqueue(box, entry);
      final loaded = LabourQuotesSyncQueueStorage.loadFromBox(box);

      expect(loaded, hasLength(1));
      expect(loaded.first.quoteId, 'q1');
      expect(loaded.first.operation, LabourQuoteSyncOperation.save);
      expect(loaded.first.queuedAt, entry.queuedAt);
    });

    test('enqueue replaces prior op for same quote id', () async {
      await LabourQuotesSyncQueueStorage.enqueue(
        box,
        LabourQuoteSyncEntry(
          quoteId: 'q1',
          operation: LabourQuoteSyncOperation.save,
          queuedAt: DateTime(2026, 4, 1),
        ),
      );
      await LabourQuotesSyncQueueStorage.enqueue(
        box,
        LabourQuoteSyncEntry(
          quoteId: 'q1',
          operation: LabourQuoteSyncOperation.delete,
          queuedAt: DateTime(2026, 4, 2),
        ),
      );

      final loaded = LabourQuotesSyncQueueStorage.loadFromBox(box);

      expect(loaded, hasLength(1));
      expect(loaded.first.operation, LabourQuoteSyncOperation.delete);
    });

    test('dequeueHead removes first entry in fifo order', () async {
      await LabourQuotesSyncQueueStorage.enqueue(
        box,
        LabourQuoteSyncEntry(
          quoteId: 'q1',
          operation: LabourQuoteSyncOperation.save,
          queuedAt: DateTime(2026, 4, 1),
        ),
      );
      await LabourQuotesSyncQueueStorage.enqueue(
        box,
        LabourQuoteSyncEntry(
          quoteId: 'q2',
          operation: LabourQuoteSyncOperation.delete,
          queuedAt: DateTime(2026, 4, 2),
        ),
      );

      final afterFirst = await LabourQuotesSyncQueueStorage.dequeueHead(box);
      expect(afterFirst, hasLength(1));
      expect(afterFirst.first.quoteId, 'q2');

      final afterSecond = await LabourQuotesSyncQueueStorage.dequeueHead(box);
      expect(afterSecond, isEmpty);
    });

    test('removeForQuote clears matching pending ops', () async {
      await LabourQuotesSyncQueueStorage.enqueue(
        box,
        LabourQuoteSyncEntry(
          quoteId: 'q1',
          operation: LabourQuoteSyncOperation.save,
          queuedAt: DateTime(2026, 4, 1),
        ),
      );
      await LabourQuotesSyncQueueStorage.enqueue(
        box,
        LabourQuoteSyncEntry(
          quoteId: 'q2',
          operation: LabourQuoteSyncOperation.delete,
          queuedAt: DateTime(2026, 4, 2),
        ),
      );

      final remaining =
          await LabourQuotesSyncQueueStorage.removeForQuote(box, 'q1');

      expect(remaining, hasLength(1));
      expect(remaining.first.quoteId, 'q2');
    });
  });
}