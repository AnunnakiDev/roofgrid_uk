enum LabourFlowStep {
  project,
  materials,
  sections,
  quote,
  results;

  static const labels = [
    'Project',
    'Materials',
    'Sections',
    'Quote',
    'Results',
  ];

  String get label => labels[index];

  LabourFlowStep? get next {
    final nextIndex = index + 1;
    if (nextIndex >= LabourFlowStep.values.length) return null;
    return LabourFlowStep.values[nextIndex];
  }

  LabourFlowStep? get previous {
    if (index == 0) return null;
    return LabourFlowStep.values[index - 1];
  }
}