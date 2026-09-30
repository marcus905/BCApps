codeunit 144999 "CalcDate Month Tests"
{
    Subtype = Test;

    [Test]
    procedure Current30X3FMCanSkipMonth()
    begin
        Assert.AreEqual(
            DMY2Date(31, 3, 2026),
            CalcDate('<30D+CM>', DMY2Date(31, 1, 2026)),
            'The current 30-days-end-of-month formula should demonstrate the month-skipping behavior.');
    end;

    [Test]
    procedure CalcDateMonthAdditionFromMonthEnd()
    begin
        Assert.AreEqual(
            DMY2Date(28, 2, 2026),
            CalcDate('<1M>', DMY2Date(31, 1, 2026)),
            '31 January 2026 + 1M should resolve to the last valid day of February.');
        Assert.AreEqual(
            DMY2Date(29, 2, 2024),
            CalcDate('<1M>', DMY2Date(31, 1, 2024)),
            '31 January 2024 + 1M should resolve to leap day.');
        Assert.AreEqual(
            DMY2Date(30, 4, 2026),
            CalcDate('<1M>', DMY2Date(31, 3, 2026)),
            '31 March 2026 + 1M should resolve to the last valid day of April.');
        Assert.AreEqual(
            DMY2Date(30, 9, 2026),
            CalcDate('<1M>', DMY2Date(31, 8, 2026)),
            '31 August 2026 + 1M should resolve to the last valid day of September.');
    end;

    [Test]
    procedure CalcDateMonthEndProgression()
    begin
        VerifyMonthEndProgression(
            DMY2Date(31, 1, 2026),
            DMY2Date(28, 2, 2026),
            DMY2Date(31, 3, 2026),
            DMY2Date(30, 4, 2026));
        VerifyMonthEndProgression(
            DMY2Date(31, 1, 2024),
            DMY2Date(29, 2, 2024),
            DMY2Date(31, 3, 2024),
            DMY2Date(30, 4, 2024));
        VerifyMonthEndProgression(
            DMY2Date(31, 3, 2026),
            DMY2Date(30, 4, 2026),
            DMY2Date(31, 5, 2026),
            DMY2Date(30, 6, 2026));
        VerifyMonthEndProgression(
            DMY2Date(31, 8, 2026),
            DMY2Date(30, 9, 2026),
            DMY2Date(31, 10, 2026),
            DMY2Date(30, 11, 2026));
    end;

    [Test]
    procedure CalcDateFourTermExpressionEvaluation()
    begin
        Assert.AreEqual(
            DMY2Date(31, 3, 2027),
            CalcDate('<CM+1M+1D+CM>', DMY2Date(3, 2, 2027)),
            'The runtime should evaluate the four-term expression as observed in the posted-payment test.');
        Assert.AreEqual(
            DMY2Date(30, 4, 2027),
            CalcDate('<CM+2M+1D+CM>', DMY2Date(3, 2, 2027)),
            'The runtime should evaluate the four-term expression as observed in the posted-payment test.');
    end;

    local procedure VerifyMonthEndProgression(StartDate: Date; ExpectedFirstMonthEnd: Date; ExpectedSecondMonthEnd: Date; ExpectedThirdMonthEnd: Date)
    begin
        Assert.AreEqual(
            ExpectedFirstMonthEnd,
            CalcDate('<CM+1M+CM>', StartDate),
            'CM+1M+CM did not return the end of the first following month.');
        Assert.AreEqual(
            ExpectedSecondMonthEnd,
            CalcDate('<CM+2M+CM>', StartDate),
            'CM+2M+CM did not return the end of the second following month.');
        Assert.AreEqual(
            ExpectedThirdMonthEnd,
            CalcDate('<CM+3M+CM>', StartDate),
            'CM+3M+CM did not return the end of the third following month.');
    end;

    var
        Assert: Codeunit Assert;
}
