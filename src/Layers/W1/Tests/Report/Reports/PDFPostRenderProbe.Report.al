// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

// Diagnostic report for BCApps#11015. An Integer filter of 1 appends one PDF; 2 is the baseline.
// The appended PDF is created from an unrelated test report to avoid recursive OnPreRendering.
report 139597 "PDF Post-Render Probe"
{
    DefaultRenderingLayout = ProbeLayout;

    dataset
    {
        dataitem(ProbeRow; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = filter(1..2));
            RequestFilterFields = Number;

            column(ColumnName; Number)
            {
            }
        }
    }

    rendering
    {
        layout(ProbeLayout)
        {
            Type = RDLC;
            LayoutFile = 'Layouts/PDFPostRenderProbe.rdl';
        }
    }

    trigger OnPreRendering(var RenderingPayload: JsonObject)
    var
        Customer: Record Customer;
        CustomerRef: RecordRef;
        PdfDocument: Codeunit "PDF Document";
        Appendix: Codeunit "Temp Blob";
        AppendixOut: OutStream;
        AppendixIn: InStream;
    begin
        if ProbeRow.GetFilter(Number) <> '1' then
            exit;

        // Generate a real PDF as the appendix rather than relying on a server-side fixture.
        if not Customer.FindFirst() then
            Error('The PDF post-render probe requires at least one customer.');
        Customer.SetRecFilter();
        CustomerRef.GetTable(Customer);

        Appendix.CreateOutStream(AppendixOut);
        if not Report.SaveAs(Report::"Test Report - Default=RDLC", '', ReportFormat::Pdf, AppendixOut, CustomerRef) then
            Error('Could not render the PDF post-render probe appendix.');

        Appendix.CreateInStream(AppendixIn);
        PdfDocument.AddStreamToAppend(AppendixIn);
        RenderingPayload := PdfDocument.ToJson(RenderingPayload);
    end;
}
