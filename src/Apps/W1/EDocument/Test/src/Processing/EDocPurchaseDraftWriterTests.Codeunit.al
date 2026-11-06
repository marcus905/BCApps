// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;

codeunit 139878 "E-Doc Purchase Draft Writer Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EDocPurchaseDraftWriter: Codeunit "E-Doc. Purchase Draft Writer";

    [Test]
    procedure PersistsHeaderAndLinesWithStandardLinkageAndLineNumbers()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
        SavedLines: Record "E-Document Purchase Line";
    begin
        CreateEDocument(EDocument);
        TempHeader."Vendor Company Name" := 'External supplier';
        TempHeader."Sales Invoice No." := 'INV-100';
        AddTempLine(TempLines, 30000, 'Third line');
        AddTempLine(TempLines, 10000, 'First line');

        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        Assert.IsTrue(SavedHeader.Get(EDocument."Entry No"), 'Purchase draft header was not persisted.');
        Assert.AreEqual('External supplier', SavedHeader."Vendor Company Name", 'Vendor name must be preserved.');
        Assert.AreEqual('INV-100', SavedHeader."Sales Invoice No.", 'Invoice number must be preserved.');
        SavedLines.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.AreEqual(2, SavedLines.Count(), 'Both purchase draft lines must be persisted.');
        Assert.IsTrue(SavedLines.FindFirst(), 'Expected first persisted line.');
        Assert.AreEqual(10000, SavedLines."Line No.", 'First line must use standard numbering.');
        Assert.AreEqual('First line', SavedLines.Description, 'First line must follow temporary key order.');
        Assert.IsTrue(SavedLines.Next() <> 0, 'Expected second persisted line.');
        Assert.AreEqual(20000, SavedLines."Line No.", 'Second line must use standard numbering.');
        Assert.AreEqual('Third line', SavedLines.Description, 'Second line must follow temporary key order.');
    end;

    [Test]
    procedure ReimportReplacesPreviousHeaderAndLines()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
        SavedLines: Record "E-Document Purchase Line";
    begin
        CreateEDocument(EDocument);
        TempHeader."Vendor Company Name" := 'Old supplier';
        AddTempLine(TempLines, 10000, 'Old line');
        AddTempLine(TempLines, 20000, 'Another old line');
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        TempHeader."Vendor Company Name" := 'New supplier';
        TempLines.DeleteAll();
        AddTempLine(TempLines, 50000, 'Replacement line');
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        Assert.IsTrue(SavedHeader.Get(EDocument."Entry No"), 'Replacement header must exist.');
        Assert.AreEqual('New supplier', SavedHeader."Vendor Company Name", 'Header must be replaced.');
        SavedLines.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.AreEqual(1, SavedLines.Count(), 'Previous lines must be removed.');
        Assert.IsTrue(SavedLines.FindFirst(), 'Replacement line must exist.');
        Assert.AreEqual(10000, SavedLines."Line No.", 'Line numbering must restart after replacement.');
        Assert.AreEqual('Replacement line', SavedLines.Description, 'Replacement line must be persisted.');
    end;

    [Test]
    procedure EmptyLineBufferRemovesPreviousLines()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedLines: Record "E-Document Purchase Line";
    begin
        CreateEDocument(EDocument);
        AddTempLine(TempLines, 10000, 'Previous line');
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        TempLines.DeleteAll();
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        SavedLines.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.IsTrue(SavedLines.IsEmpty(), 'An empty buffer must replace, not retain, previous lines.');
    end;

    [Test]
    procedure PersistingAnotherDocumentDoesNotChangeExistingDraft()
    var
        FirstEDocument: Record "E-Document";
        SecondEDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
        SavedLines: Record "E-Document Purchase Line";
    begin
        CreateEDocument(FirstEDocument);
        CreateEDocument(SecondEDocument);
        TempHeader."Vendor Company Name" := 'First supplier';
        AddTempLine(TempLines, 10000, 'First document line');
        EDocPurchaseDraftWriter.PersistDraft(FirstEDocument, TempHeader, TempLines);

        TempHeader."Vendor Company Name" := 'Second supplier';
        TempLines.DeleteAll();
        AddTempLine(TempLines, 10000, 'Second document line');
        EDocPurchaseDraftWriter.PersistDraft(SecondEDocument, TempHeader, TempLines);

        Assert.IsTrue(SavedHeader.Get(FirstEDocument."Entry No"), 'First header must remain.');
        Assert.AreEqual('First supplier', SavedHeader."Vendor Company Name", 'First header must not change.');
        Assert.IsTrue(SavedHeader.Get(SecondEDocument."Entry No"), 'Second header must exist.');
        Assert.AreEqual('Second supplier', SavedHeader."Vendor Company Name", 'Second header must be independent.');
        SavedLines.SetRange("E-Document Entry No.", FirstEDocument."Entry No");
        Assert.IsTrue(SavedLines.FindFirst(), 'First line must remain.');
        Assert.AreEqual('First document line', SavedLines.Description, 'First line must not change.');
        SavedLines.SetRange("E-Document Entry No.", SecondEDocument."Entry No");
        Assert.IsTrue(SavedLines.FindFirst(), 'Second line must exist.');
        Assert.AreEqual('Second document line', SavedLines.Description, 'Second line must be independent.');
    end;

    [Test]
    procedure PersistDraftDoesNotModifyTemporaryInputs()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
    begin
        CreateEDocument(EDocument);
        TempHeader."Vendor Company Name" := 'Unchanged supplier';
        AddTempLine(TempLines, 30000, 'Unchanged line');

        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        Assert.AreEqual(0, TempHeader."E-Document Entry No.", 'Input header linkage must not be overwritten.');
        Assert.AreEqual('Unchanged supplier', TempHeader."Vendor Company Name", 'Input header must remain intact.');
        Assert.IsTrue(TempLines.Get(0, 30000), 'Original temporary line key must remain intact.');
        Assert.AreEqual('Unchanged line', TempLines.Description, 'Input line must remain intact.');
    end;

    [Test]
    procedure RejectsMissingEDocumentWithoutWritingDraft()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
    begin
        EDocument."Entry No" := 0;
        asserterror EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);
        Assert.ExpectedError('The E-Document must exist');
    end;

    [Test]
    procedure RejectsOutboundEDocumentWithoutWritingDraft()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
    begin
        EDocument.Init();
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Insert(true);

        asserterror EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);
        Assert.ExpectedError('requires an incoming E-Document');
        Assert.IsFalse(SavedHeader.Get(EDocument."Entry No"), 'No purchase draft must be written.');
    end;

    [Test]
    procedure RejectsProcessedEDocumentWithoutOverwritingDraft()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
    begin
        CreateEDocument(EDocument);
        TempHeader."Vendor Company Name" := 'Original draft';
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);
        EDocument.Status := EDocument.Status::Processed;
        EDocument.Modify();

        TempHeader."Vendor Company Name" := 'Must not replace';
        asserterror EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);
        Assert.ExpectedError('processed or linked E-Document');
        Assert.IsTrue(SavedHeader.Get(EDocument."Entry No"), 'Original draft must remain.');
        Assert.AreEqual('Original draft', SavedHeader."Vendor Company Name", 'Processed document draft must not be overwritten.');
    end;

    [Test]
    procedure RejectsFilteredLinesWithoutOverwritingDraft()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
    begin
        CreateEDocument(EDocument);
        TempHeader."Vendor Company Name" := 'Original draft';
        AddTempLine(TempLines, 10000, 'Original line');
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        TempHeader."Vendor Company Name" := 'Must not replace';
        TempLines.SetRange("Line No.", 20000);
        asserterror EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);
        Assert.ExpectedError('must be unfiltered');
        Assert.IsTrue(SavedHeader.Get(EDocument."Entry No"), 'Original draft must remain.');
        Assert.AreEqual('Original draft', SavedHeader."Vendor Company Name", 'Filtered buffer must not overwrite existing draft.');
    end;

    [Test]
    procedure AllowsReplacementOfPreparedButUnprocessedDraft()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        CreateEDocument(EDocument);
        EDocumentServiceStatus.Init();
        EDocumentServiceStatus."E-Document Entry No" := EDocument."Entry No";
        EDocumentServiceStatus."E-Document Service Code" := '';
        EDocumentServiceStatus."Import Processing Status" := Enum::"Import E-Doc. Proc. Status"::"Draft Ready";
        EDocumentServiceStatus.Insert();

        TempHeader."Vendor Company Name" := 'Replacement draft';
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        Assert.IsTrue(SavedHeader.Get(EDocument."Entry No"), 'Replacement draft header must exist.');
        Assert.AreEqual('Replacement draft', SavedHeader."Vendor Company Name", 'Unprocessed draft can be replaced.');
    end;

    local procedure CreateEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument.Direction := EDocument.Direction::Incoming;
        EDocument.Insert(true);
    end;

    local procedure AddTempLine(var TempLines: Record "E-Document Purchase Line" temporary; LineNo: Integer; Description: Text[100])
    begin
        TempLines.Init();
        TempLines."E-Document Entry No." := 0;
        TempLines."Line No." := LineNo;
        TempLines.Description := Description;
        TempLines.Insert();
    end;
}
