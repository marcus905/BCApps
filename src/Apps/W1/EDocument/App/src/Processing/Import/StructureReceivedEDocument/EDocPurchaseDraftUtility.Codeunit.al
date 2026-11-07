// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;

/// <summary>
/// Persists purchase drafts populated by first-party and external structured E-Document readers.
/// </summary>
codeunit 6234 "E-Doc. Purchase Draft Utility"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Replaces the standard purchase draft for an existing incoming E-Document using parsed header and line buffers.
    /// Existing draft lines are deleted with triggers, removing their associated purchase-order matches.
    /// The E-Document linkage and persisted line numbers are assigned by this utility.
    /// Only temporary lines visible through the caller's current filters are persisted in key order.
    /// This operation does not update import-processing status or execute the Prepare/Finish Draft stages.
    /// Replacement discards previous draft edits and matches unless they are included in the supplied buffers.
    /// </summary>
    /// <param name="EDocument">An existing incoming E-Document.</param>
    /// <param name="TempEDocPurchaseHeader">The temporary header's current field values; it need not be inserted into the temporary table.</param>
    /// <param name="TempEDocPurchaseLine">Temporary staging lines to persist. Only records matching the current filters are included; an empty selection removes existing lines.</param>
    procedure PersistDraft(EDocument: Record "E-Document"; var TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary; var TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary)
    var
        EDocumentPurchaseHeader: Record "E-Document Purchase Header";
        EDocumentPurchaseLine: Record "E-Document Purchase Line";
        ExistingEDocument: Record "E-Document";
        InvalidEDocumentErr: Label 'The E-Document must exist before its purchase draft can be persisted.';
        IncomingEDocumentRequiredErr: Label 'Purchase draft persistence requires an incoming E-Document.';
    begin
        if (EDocument."Entry No" = 0) or (not ExistingEDocument.Get(EDocument."Entry No")) then
            Error(InvalidEDocumentErr);
        if ExistingEDocument.Direction <> ExistingEDocument.Direction::Incoming then
            Error(IncomingEDocumentRequiredErr);

        // Clean up old data, since we are re-reading data
        EDocumentPurchaseHeader.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocumentPurchaseHeader.DeleteAll();
        EDocumentPurchaseLine.SetRange("E-Document Entry No.", EDocument."Entry No");
        EDocumentPurchaseLine.DeleteAll(true);

        EDocumentPurchaseHeader := TempEDocPurchaseHeader;
        EDocumentPurchaseHeader."E-Document Entry No." := EDocument."Entry No";
        EDocumentPurchaseHeader.Insert();
        OnInsertedEDocumentPurchaseHeader(EDocument, EDocumentPurchaseHeader);

        if TempEDocPurchaseLine.FindSet() then begin
            repeat
                EDocumentPurchaseLine := TempEDocPurchaseLine;
                EDocumentPurchaseLine."E-Document Entry No." := EDocument."Entry No";
                EDocumentPurchaseLine."Line No." := EDocumentPurchaseLine.GetNextLineNo(EDocument."Entry No");
                EDocumentPurchaseLine.Insert();
            until TempEDocPurchaseLine.Next() = 0;

            OnInsertedEDocumentPurchaseLines(EDocument, EDocumentPurchaseHeader, EDocumentPurchaseLine);
        end;
    end;

    [InternalEvent(false, false)]
    local procedure OnInsertedEDocumentPurchaseHeader(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header")
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnInsertedEDocumentPurchaseLines(EDocument: Record "E-Document"; EDocumentPurchaseHeader: Record "E-Document Purchase Header"; EDocumentPurchaseLine: Record "E-Document Purchase Line")
    begin
    end;
}
