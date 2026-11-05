# BCApps #11015 — PDF final-artifact probe

Test-only proof of the interaction between report `OnPreRendering` / `additionalDocuments`,
`ReportManagement.OnAfterDocumentReady`, and the PDF returned by `Report.SaveAs`.

Objects (Tests-Report, W1):
- Report **139597 PDF Post-Render Probe**, with a minimal RDLC layout.
- Test codeunit **139598 PDF Post-Render Probe Test**.

Run **both** test methods in codeunit 139598:

1. `CompletedPdfIncludesAppendixBeforeDocumentReady`
2. `DocumentReadyReplacementIsReturnedAfterAppend`

The probe's Integer filter controls its behavior: **2** produces a baseline PDF;
**1** produces the same report with a separately rendered customer-report PDF
appended from `OnPreRendering`. The test creates a customer, renders the actual
appendix separately to count its pages, and computes its expected page count as
baseline + appendix. It captures the completed-event PDF, records its SHA-256
hash, and compares the returned `Report.SaveAs` bytes. The second test
replaces the event's combined PDF with a known baseline PDF and confirms that
the returned bytes match that replacement exactly.

The subscriber is bound manually and filters by the dedicated probe report ID;
it does not modify production reports. No production source is changed.

Interpretation:
- A matching page count at `OnAfterDocumentReady` establishes that appended
  pages were already present in the artifact presented to this event.
- Exact SHA-256 parity between event bytes and returned PDF rules out
  downstream byte changes for this tested `Report.SaveAs` route.
- Exact parity with a *different* replacement PDF demonstrates that
  `TargetStream` + `Success := true` is honored for this route.

Limitations:
- These tests cover the stream-based `Report.SaveAs` route only, not user-
  initiated downloads, printing, email, or `Report Selections` attachment flows.
- They do not establish an unconditional platform contract for all rendering
  formats, platform versions, or additional post-processing features.
- Test results require an AL compile/run on a configured Business Central test
  installation; the GitHub source commit alone is not execution evidence.
