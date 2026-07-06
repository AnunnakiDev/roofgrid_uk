import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roofgrid_uk/app/labour_pricing/models/labour_flow_step.dart';
import 'package:roofgrid_uk/app/labour_pricing/providers/labour_pricing_provider.dart';

class LabourFlowNotifier extends Notifier<LabourFlowStep> {
  @override
  LabourFlowStep build() => LabourFlowStep.project;

  void goTo(LabourFlowStep step) {
    state = step;
  }

  void reset() {
    state = LabourFlowStep.project;
  }

  String? validationMessageForAdvance() {
    final pricing = ref.read(labourPricingProvider);
    switch (state) {
      case LabourFlowStep.project:
        return null;
      case LabourFlowStep.materials:
        return null;
      case LabourFlowStep.sections:
        if (pricing.project.sections.isEmpty) {
          return 'Add at least one roof section';
        }
        return null;
      case LabourFlowStep.quote:
        return null;
      case LabourFlowStep.results:
        return null;
    }
  }

  bool canAdvance() => validationMessageForAdvance() == null;

  bool advance() {
    if (!canAdvance()) return false;
    final next = state.next;
    if (next == null) return false;
    state = next;
    return true;
  }

  bool retreat() {
    final previous = state.previous;
    if (previous == null) return false;
    state = previous;
    return true;
  }
}

final labourFlowProvider =
    NotifierProvider<LabourFlowNotifier, LabourFlowStep>(
  LabourFlowNotifier.new,
);