// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

// BCApps#11015: verify the relative ordering of OnPreRendering's additionalDocuments and
// ReportManagement.OnAfterDocumentReady, plus PDF replacement through TargetStream.
// This is diagnostic test-only code; no production behavior is changed.
codeunit 139598 "PDF Post-Render Probe Test"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;
    EventSubscriberInstance = Manual;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        CryptographyManagement: Codeunit "Cryptography Management";
        ReplacementPdf: Codeunit "Temp Blob";
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
        CaptureEnabled: Boolean;
        ReplacePdf: Boolean;
        EventSeen: Boolean;
        EventPageCount: Integer;
        EventHash: Text;
        EventDocumentType: Text;

    [Test]
    procedure CompletedPdfIncludesAppendixBeforeDocumentReady()
    var
        BaselinePdf: Codeunit "Temp Blob";
        OutputPdf: Codeunit "Temp Blob";
        ExpectedPageCount: Integer;
    begin
        EnsureCustomer();
        SaveProbe(2, BaselinePdf);
        ExpectedPageCount := PageCount(BaselinePdf) + RenderAppendixPageCount();
        Assert.IsTrue(ExpectedPageCount > PageCount(BaselinePdf), 'An appendix PDF must contain at least one page.');

        StartCapture(false);
        BindSubscription(this);
        SaveProbe(1, OutputPdf);
        UnbindSubscription(this);
        StopCapture();

        Assert.IsTrue(EventSeen, 'OnAfterDocumentReady was not raised for the probe report.');
        Assert.AreEqual('application/pdf', EventDocumentType, 'The event must expose a PDF.');
        Assert.AreEqual(ExpectedPageCount, EventPageCount, 'OnAfterDocumentReady did not see the combined PDF.');
        Assert.AreEqual(ExpectedPageCount, PageCount(OutputPdf), 'Report.SaveAs did not return all appended pages.');
        Assert.AreEqual(EventHash, ContentHash(OutputPdf), 'PDF bytes changed after OnAfterDocumentReady.');
    end;

    [Test]
    procedure DocumentReadyReplacementIsReturnedAfterAppend()
    var
        BaselinePdf: Codeunit "Temp Blob";
        OutputPdf: Codeunit "Temp Blob";
        ReplacementIn: InStream;
        ReplacementOut: OutStream;
        BaselinePageCount: Integer;
        ExpectedCombinedPages: Integer;
    begin
        EnsureCustomer();
        SaveProbe(2, BaselinePdf);
        BaselinePageCount := PageCount(BaselinePdf);
        ExpectedCombinedPages := BaselinePageCount + RenderAppendixPageCount();
        Assert.IsTrue(ExpectedCombinedPages > BaselinePageCount, 'The appendix must increase the page count.');

        Clear(ReplacementPdf);
        ReplacementPdf.CreateOutStream(ReplacementOut);
        BaselinePdf.CreateInStream(ReplacementIn);
        CopyStream(ReplacementOut, ReplacementIn);

        StartCapture(true);
        BindSubscription(this);
        SaveProbe(1, OutputPdf);
        UnbindSubscription(this);
        StopCapture();

        Assert.IsTrue(EventSeen, 'OnAfterDocumentReady was not raised for the probe report.');
        Assert.AreEqual('application/pdf', EventDocumentType, 'The event must expose a PDF.');
        Assert.AreEqual(ExpectedCombinedPages, EventPageCount, 'The event did not receive the appended PDF before replacement.');
        Assert.AreEqual(BaselinePageCount, PageCount(OutputPdf), 'The replacement PDF did not reach the final output.');
        Assert.AreEqual(ContentHash(BaselinePdf), ContentHash(OutputPdf), 'Report.SaveAs did not return the exact replacement PDF bytes.');
    end;

    local procedure EnsureCustomer()
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
    end;

    local procedure SaveProbe(NumberFilter: Integer; var Pdf: Codeunit "Temp Blob")
    var
        NumberRec: Record Integer;
        RecordRef: RecordRef;
        OutputStream: OutStream;
    begin
        NumberRec.SetRange(Number, NumberFilter);
        RecordRef.GetTable(NumberRec);
        Pdf.CreateOutStream(OutputStream);
        if not Report.SaveAs(Report::"PDF Post-Render Probe", '', ReportFormat::Pdf, OutputStream, RecordRef) then
            Error('The PDF post-render probe report failed to render for Number %1.', NumberFilter);
    end;

    local procedure RenderAppendixPageCount(): Integer
    var
        Customer: Record Customer;
        CustomerRef: RecordRef;
        Pdf: Codeunit "Temp Blob";
        PdfOut: OutStream;
    begin
        Customer.FindFirst();
        Customer.SetRecFilter();
        CustomerRef.GetTable(Customer);
        Pdf.CreateOutStream(PdfOut);
        if not Report.SaveAs(Report::"Test Report - Default=RDLC", '', ReportFormat::Pdf, PdfOut, CustomerRef) then
            Error('The PDF appendix report failed to render.');
        exit(PageCount(Pdf));
    end;

    local procedure PageCount(var Pdf: Codeunit "Temp Blob"): Integer
    var
        PdfDocument: Codeunit "PDF Document";
        PdfIn: InStream;
    begin
        Pdf.CreateInStream(PdfIn);
        exit(PdfDocument.GetPdfPageCount(PdfIn));
    end;

    local procedure ContentHash(var Pdf: Codeunit "Temp Blob"): Text
    var
        PdfIn: InStream;
    begin
        Pdf.CreateInStream(PdfIn);
        exit(CryptographyManagement.GenerateHash(PdfIn, HashAlgorithmType::SHA256));
    end;

    local procedure StartCapture(ShouldReplace: Boolean)
    begin
        CaptureEnabled := true;
        ReplacePdf := ShouldReplace;
        EventSeen := false;
        EventPageCount := 0;
        EventHash := '';
        EventDocumentType := '';
    end;

    local procedure StopCapture()
    begin
        CaptureEnabled := false;
        ReplacePdf := false;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterDocumentReady', '', false, false)]
    local procedure CaptureOnAfterDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    var
        ObservedPdf: Codeunit "Temp Blob";
        CopyIn: InStream;
        ObservedOut: OutStream;
        SharedIn: InStream;
        DocumentTypeToken: JsonToken;
    begin
        if (not CaptureEnabled) or (ObjectId <> Report::"PDF Post-Render Probe") or Success then
            exit;

        if ObjectPayload.Get('documenttype', DocumentTypeToken) then
            EventDocumentType := DocumentTypeToken.AsValue().AsText();

        SharedIn := DocumentStream;
        if SharedIn.Position > 1 then
            SharedIn.ResetPosition();
        ObservedPdf.CreateOutStream(ObservedOut);
        CopyStream(ObservedOut, SharedIn);

        EventPageCount := PageCount(ObservedPdf);
        EventHash := ContentHash(ObservedPdf);
        EventSeen := true;

        if ReplacePdf then
            ReplacementPdf.CreateInStream(CopyIn)
        else
            ObservedPdf.CreateInStream(CopyIn);
        CopyStream(TargetStream, CopyIn);
        Success := true;
    end;
}
