import 'hero_export_models.dart';

/// The UI decision required before an export artifact may be saved or shared.
enum ExportProceedDecision { allowed, confirmationRequired, blocked }

/// Keeps report severity policy independent from Flutter widgets and file I/O.
class HeroExportWorkflow {
  HeroExportWorkflow._();

  static ExportProceedDecision decisionFor(ExportReport report) {
    if (report.hasErrors) return ExportProceedDecision.blocked;
    if (report.hasWarnings) return ExportProceedDecision.confirmationRequired;
    return ExportProceedDecision.allowed;
  }
}
