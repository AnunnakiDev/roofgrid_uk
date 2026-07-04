import 'package:flutter/material.dart';

enum SaveResultAction {
  updateExisting,
  saveAsNew,
}

class SaveResultDialogResult {
  final String projectName;
  final SaveResultAction action;

  const SaveResultDialogResult({
    required this.projectName,
    required this.action,
  });
}

Future<SaveResultDialogResult?> showSaveResultDialog({
  required BuildContext context,
  String title = 'Save Calculation',
  String? initialProjectName,
  bool allowUpdateExisting = false,
}) {
  final projectNameController =
      TextEditingController(text: initialProjectName ?? '');
  var saveAction = allowUpdateExisting
      ? SaveResultAction.updateExisting
      : SaveResultAction.saveAsNew;

  return showDialog<SaveResultDialogResult>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a project name for this calculation.'),
            const SizedBox(height: 16),
            TextField(
              controller: projectNameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            if (allowUpdateExisting) ...[
              const SizedBox(height: 16),
              Text(
                'Save options',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              RadioListTile<SaveResultAction>(
                title: const Text('Update existing result'),
                value: SaveResultAction.updateExisting,
                groupValue: saveAction,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => saveAction = value);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              RadioListTile<SaveResultAction>(
                title: const Text('Save as new result'),
                value: SaveResultAction.saveAsNew,
                groupValue: saveAction,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => saveAction = value);
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = projectNameController.text.trim();
              if (name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please enter a project name'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
                return;
              }
              Navigator.pop(
                dialogContext,
                SaveResultDialogResult(
                  projectName: name,
                  action: saveAction,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}