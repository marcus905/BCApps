# BCApps #11015 PDF post-render diagnostic, round two

Run all four tests in codeunit 139598.

1. `AppendixReachesFinalPdfWithoutSubscriber` confirms an appendix is appended by the platform without any subscriber.
2. `DocumentReadyPassivelyObservesPreAppendPdf` captures the event PDF but leaves `Success` and `TargetStream` unchanged, and checks the returned PDF contains the appendix.
3. `DocumentReadyReplacementIsReturnedAfterAppend` replaces the event PDF with a baseline; checks whether appending still occurs after replacement.
4. `DocumentReadyReplacementWithoutAppend` replaces a report with a distinct PDF without any appendix, checking byte-for-byte equality.

The original run had event page count 1 versus expected final 2, but its subscriber always set `Success := true`, even for observation. These tests separate those behaviors and make the output observable.

Only the test codeunit and this README are changed. The test does not establish email, print or archive behavior.
