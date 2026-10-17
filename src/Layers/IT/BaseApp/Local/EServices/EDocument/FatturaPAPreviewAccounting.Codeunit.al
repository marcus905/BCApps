namespace Microsoft.EServices.EDocument;

using Microsoft.EServices.EDocument;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Receivables;

codeunit 12281 "FatturaPA Preview Accounting"
{
    procedure AddVATRows(
        var TempFatturaLine: Record "Fattura Line" temporary;
        var TempVATEntry: Record "VAT Entry" temporary)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ReversedVATPostingSetup: Record "VAT Posting Setup";
        VATNature: Code[4];
    begin
        TempVATEntry.Reset();
        TempVATEntry.SetRange(Type, TempVATEntry.Type::Sale);

        if TempVATEntry.FindSet() then
            repeat
                VATPostingSetup.Get(TempVATEntry."VAT Bus. Posting Group", TempVATEntry."VAT Prod. Posting Group");
                begin
                    if not ((VATPostingSetup."VAT Calculation Type" = VATPostingSetup."VAT Calculation Type"::"Full VAT") and
                        ReversedVATPostingSetup.Get(VATPostingSetup."Reversed VAT Bus. Post. Group", VATPostingSetup."Reversed VAT Prod. Post. Group"))
                    then begin
                        VATNature := VATPostingSetup."VAT Transaction Nature";
                        AccumulateVAT(
                            TempFatturaLine, TempVATEntry."VAT %", VATNature,
                            Abs(TempVATEntry.Base + TempVATEntry."Unrealized Base"),
                            Abs(TempVATEntry.Amount + TempVATEntry."Unrealized Amount"),
                            TempVATEntry."VAT Identifier");
                    end;
                end;
            until TempVATEntry.Next() = 0;
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

    local procedure AccumulateVAT(
        var TempFatturaLine: Record "Fattura Line" temporary;
        VATPercent: Decimal;
        VATNature: Code[10];
        VATBase: Decimal;
        VATAmount: Decimal;
        VATIdentifier: Code[20])
    var
        LastLineNo: Integer;
    begin
        TempFatturaLine.Reset();
        TempFatturaLine.SetRange(
            "Line Type",
            TempFatturaLine."Line Type"::VAT);
        TempFatturaLine.SetRange("VAT %", VATPercent);
        TempFatturaLine.SetRange("VAT Transaction Nature", VATNature);

        if TempFatturaLine.FindFirst() then begin
            TempFatturaLine."VAT Base" += VATBase;
            TempFatturaLine."VAT Amount" += VATAmount;
            TempFatturaLine.Modify();
            exit;
        end;

        TempFatturaLine.Reset();
        TempFatturaLine.SetRange(
            "Line Type",
            TempFatturaLine."Line Type"::VAT);
        if TempFatturaLine.FindLast() then
            LastLineNo := TempFatturaLine."Line No.";

        TempFatturaLine.Init();
        TempFatturaLine."Line Type" := TempFatturaLine."Line Type"::VAT;
        TempFatturaLine."Line No." := LastLineNo + 1;
        TempFatturaLine."VAT %" := VATPercent;
        TempFatturaLine."VAT Transaction Nature" := VATNature;
        TempFatturaLine."VAT Base" := VATBase;
        TempFatturaLine."VAT Amount" := VATAmount;
        TempFatturaLine.Description := 'I';
        TempFatturaLine."VAT Nature Description" :=
            CopyStr(VATIdentifier, 1, MaxStrLen(TempFatturaLine."VAT Nature Description"));
        TempFatturaLine.Insert();

        TempFatturaLine.Reset();
    end;
}
