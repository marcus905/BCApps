// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Import;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;

/// <summary>
/// Provides a supported persistence entry point for purchase drafts created by structured E-Document readers.
/// </summary>
codeunit 6245 "E-Doc. Purchase Draft Writer"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Replaces the standard purchase draft for an E-Document with the supplied parsed header and lines.
    /// Existing lines are removed with their deletion triggers, including associated purchase-order matches.
    /// The E-Document linkage and persisted line numbers are assigned by the standard draft utility.
    /// Replacement does not update import-processing status; previously prepared edits and matches may be lost.
    /// This does not perform vendor, item, unit-of-measure, VAT, or purchase-order resolution;
    /// those operations remain part of the subsequent Prepare Draft stage.
    /// </summary>
    /// <param name="EDocument">The existing incoming E-Document whose purchase draft is to be replaced.</param>
    /// <param name="TempEDocPurchaseHeader">The temporary record holding the parsed header fields. Its current values are used; inserting it into the temporary table is not required.</param>
    /// <param name="TempEDocPurchaseLine">The temporary lines holding parsed line fields. Insert each line into this buffer before calling. Only records visible through its current filters are persisted, in the buffer's current key order.</param>
    procedure PersistDraft(EDocument: Record "E-Document"; var TempEDocPurchaseHeader: Record "E-Document Purchase Header" temporary; var TempEDocPurchaseLine: Record "E-Document Purchase Line" temporary)
    var
        ExistingEDocument: Record "E-Document";
        EDocPurchaseDraftUtility: Codeunit "E-Doc. Purchase Draft Utility";
        InvalidEDocumentErr: Label 'The E-Document must exist before its purchase draft can be persisted.';
        IncomingEDocumentRequiredErr: Label 'Purchase draft persistence requires an incoming E-Document.';
    begin
        if (EDocument."Entry No" = 0) or (not ExistingEDocument.Get(EDocument."Entry No")) then
            Error(InvalidEDocumentErr);
        if ExistingEDocument.Direction <> ExistingEDocument.Direction::Incoming then
            Error(IncomingEDocumentRequiredErr);
        EDocPurchaseDraftUtility.PersistDraft(ExistingEDocument, TempEDocPurchaseHeader, TempEDocPurchaseLine);
    end;
}
