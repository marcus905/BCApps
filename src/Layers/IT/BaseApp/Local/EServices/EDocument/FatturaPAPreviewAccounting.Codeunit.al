namespace Microsoft.EServices.EDocument;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Receivables;

codeunit 12281 "FatturaPA Preview Accounting"
{
    procedure AddVATRows(
        var TempFatturaLine: Record "Fattura Line" temporary;
        var TempVATEntry: Record "VAT Entry" temporary;
        CustomerNo: Code[20];
        IsInvoice: Boolean)
    var
        FatturaDocHelper: Codeunit "Fattura Doc. Helper";
        VATPostingSetup: Record "VAT Posting Setup";
        ReversedVATPostingSetup: Record "VAT Posting Setup";
        VATEntryCount: Integer;
        IsSplitPayment: Boolean;
    begin
        TempVATEntry.Reset();
        TempVATEntry.SetRange(Type, TempVATEntry.Type::Sale);
        if TempVATEntry.FindSet() then
            repeat
                VATPostingSetup.Get(TempVATEntry."VAT Bus. Posting Group", TempVATEntry."VAT Prod. Posting Group");
                if (VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Full VAT") and
                   ReversedVATPostingSetup.Get(VATPostingSetup."Reversed VAT Bus. Post. Group", VATPostingSetup."Reversed VAT Prod. Post. Group")
                then
                    TempVATEntry.Mark(true)
                else begin
                    VATEntryCount += 1;
                    if VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Full VAT" then
                        IsSplitPayment := true;
                end;
            until TempVATEntry.Next() = 0;

        TempVATEntry.MarkedOnly(true);
        // Marked records are reversed VAT entries excluded by the standard helper.
        TempVATEntry.MarkedOnly(false);
        TempVATEntry.Reset();
        TempVATEntry.SetRange(Type, TempVATEntry.Type::Sale);
        if TempVATEntry.FindSet() then
            repeat
                if not TempVATEntry.Mark() then
                    FatturaDocHelper.InsertPreviewVATFatturaLine(
                        TempFatturaLine, TempVATEntry, CustomerNo, IsInvoice, IsSplitPayment, VATEntryCount);
            until TempVATEntry.Next() = 0;
        TempVATEntry.ClearMarks();
        TempVATEntry.Reset();
    end;

    procedure AddPaymentRows(
        var TempFatturaLine: Record "Fattura Line" temporary;
        var TempCustLedgEntry: Record "Cust. Ledger Entry" temporary;
        var TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary)
    var
        Amount: Decimal;
    begin
        TempCustLedgEntry.Reset();
        if TempCustLedgEntry.FindSet() then
            repeat
                Amount := GetInitialEntryAmount(
                    TempCustLedgEntry."Entry No.",
                    TempDtldCustLedgEntry);

                AddPayment(
                    TempFatturaLine,
                    TempCustLedgEntry."Due Date",
                    Abs(Amount));
            until TempCustLedgEntry.Next() = 0;
    end;

    local procedure GetInitialEntryAmount(
        CustLedgEntryNo: Integer;
        var TempDtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry" temporary): Decimal
    var
        Total: Decimal;
    begin
        TempDtldCustLedgEntry.Reset();
        TempDtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgEntryNo);
        TempDtldCustLedgEntry.SetRange(
            "Entry Type",
            TempDtldCustLedgEntry."Entry Type"::"Initial Entry");

        if TempDtldCustLedgEntry.FindSet() then
            repeat
                Total += TempDtldCustLedgEntry.Amount;
            until TempDtldCustLedgEntry.Next() = 0;

        exit(Total);
    end;

    local procedure AddPayment(
        var TempFatturaLine: Record "Fattura Line" temporary;
        DueDate: Date;
        Amount: Decimal)
    var
        LineNo: Integer;
    begin
        TempFatturaLine.Reset();
        TempFatturaLine.SetRange(
            "Line Type",
            TempFatturaLine."Line Type"::Payment);
        if TempFatturaLine.FindLast() then
            LineNo := TempFatturaLine."Line No.";

        TempFatturaLine.Init();
        TempFatturaLine."Line Type" := TempFatturaLine."Line Type"::Payment;
        TempFatturaLine."Line No." := LineNo + 1;
        TempFatturaLine."Due Date" := DueDate;
        TempFatturaLine.Amount := Amount;
        TempFatturaLine.Insert();

        TempFatturaLine.Reset();
    end;

}
