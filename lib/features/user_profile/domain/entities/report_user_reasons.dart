class ReportUserReason {
  final String key;
  final String label;

  const ReportUserReason({required this.key, required this.label});
}

const List<ReportUserReason> kReportUserReasons = [
  ReportUserReason(key: 'dislike', label: "I just don't like it"),
  ReportUserReason(
    key: 'bullying',
    label: 'Bullying or unwanted contact',
  ),
  ReportUserReason(
    key: 'self_harm',
    label: 'Suicide, self-injury or eating disorders',
  ),
  ReportUserReason(
    key: 'substance_abuse',
    label: 'Substance abuse or addiction',
  ),
  ReportUserReason(
    key: 'harassment',
    label: 'Harassment or discrimination',
  ),
  ReportUserReason(
    key: 'violence',
    label: 'Violence or threats of violence',
  ),
];
