enum OrgJobStatus {
  surveyed,
  quoted,
  won,
  onSite,
  complete,
}

extension OrgJobStatusLabels on OrgJobStatus {
  String get label {
    switch (this) {
      case OrgJobStatus.surveyed:
        return 'Surveyed';
      case OrgJobStatus.quoted:
        return 'Quoted';
      case OrgJobStatus.won:
        return 'Won';
      case OrgJobStatus.onSite:
        return 'On site';
      case OrgJobStatus.complete:
        return 'Complete';
    }
  }
}

OrgJobStatus orgJobStatusFromName(String? raw) {
  final needle = raw?.trim().toLowerCase();
  if (needle == null || needle.isEmpty) return OrgJobStatus.surveyed;
  return OrgJobStatus.values.firstWhere(
    (value) => value.name.toLowerCase() == needle,
    orElse: () => OrgJobStatus.surveyed,
  );
}