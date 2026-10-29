// Asserts over date.goose: known dates, leap days, a round
// trip over 400 years, and RFC 3339 times both ways. Run from the package root by make pkg-test
// through `goose run`.
import std;
import date from "..";

fn main() {
    assert(date::days_from_civil(1970, 1, 1) == 0);
    assert(date::days_from_civil(2000, 3, 1) == 11017);
    assert(date::days_from_civil(1969, 12, 31) == -1);
    assert(date::weekday(0) == 4);                                   // a Thursday
    assert(date::weekday(date::days_from_civil(2026, 11, 1)) == 0); // a Sunday
    assert(date::weekday(-1) == 3);                                  // 1969-12-31, a Wednesday
    assert(date::weekday(-5) == 6);                                  // % is Euclidean in Goose
    assert(date::weekday(date::days_from_civil(1900, 1, 1)) == 1); // a Monday
    let y, m, d = date::civil_from_days(date::days_from_civil(2028, 2, 29));
    assert(y == 2028 && m == 2 && d == 29);
    let y2, m2, d2 = date::civil_from_days(date::days_from_civil(2100, 2, 28) + 1);
    assert(y2 == 2100 && m2 == 3 && d2 == 1);                         // 2100 is not a leap year
    assert(date::days_in(2028, 2) == 29 && date::days_in(2100, 2) == 28 && date::days_in(2000, 2) == 29);
    assert(date::days_in(2026, 12) == 31 && date::days_in(2026, 4) == 30 && date::days_in(1969, 1) == 31);
    let start = date::days_from_civil(1900, 1, 1);
    for z in start..start + 146097 {
        let yy, mm, dd = date::civil_from_days(z);
        assert(date::days_from_civil(yy, mm, dd) == z);
    }
    times();
}

// format_time(t) as a string.
fn rfc(t: i64) -> u8[>..] {
    var b: u8[>..] = [];
    date::format_time(b, t);
    return b;
}

// parse_time(s), or -1 when it refuses s; -1 is not a time any case uses.
fn parsed(s: const u8[:]) -> i64 {
    let t, ok = date::parse_time(s);
    return if ok { t } else { -1 };
}

fn times() {
    let year0 = -62167219200;                                         // 0000-01-01T00:00:00Z
    let end = date::days_from_civil(10000, 1, 1) * 86400 - 1;        // 9999-12-31T23:59:59Z
    assert(rfc(0) == "1970-01-01T00:00:00Z");
    assert(rfc(-1) == "1969-12-31T23:59:59Z");
    assert(rfc(1792843200) == "2026-10-24T12:00:00Z");
    assert(rfc(year0) == "0000-01-01T00:00:00Z");
    assert(rfc(end) == "9999-12-31T23:59:59Z");
    assert(rfc(951782400) == "2000-02-29T00:00:00Z");
    var b: u8[>..] = [];
    date::format_civil(b, 1792843200 + 59, ' ', false);
    assert(b == "2026-10-24 12:00");                                  // seconds dropped, not rounded

    assert(parsed("2026-10-24T12:00:00Z") == 1792843200);
    assert(parsed("2026-10-25T02:00:00+14:00") == 1792843200);       // the largest offset in use
    assert(parsed("2026-10-24 07:00:00.250-05:00") == 1792843200);   // space, fraction dropped
    assert(parsed("0000-01-01T00:00:00Z") == year0);
    assert(parsed("9999-12-31T23:59:59Z") == end);
    assert(parsed("1970-01-01t00:00:01z") == 1);                      // lower case t and z
    assert(parsed("2000-02-29T00:00:00Z") == 951782400);
    assert(parsed("2100-02-29T00:00:00Z") == -1);                     // 2100 is not a leap year
    assert(parsed("2026-10-24T12:00:00") == -1);                      // no zone
    assert(parsed("2026-10-24T12:00:00+1400") == -1);                 // offset without a colon
    assert(parsed("2026-10-24T24:00:00Z") == -1);
    assert(parsed("2026-10-24T12:00:00+24:00") == -1);

    // A leap second reads as 23:59:59 of its day, and only at 23:59:60 UTC
    // on June 30 or December 31.
    assert(parsed("2016-12-31T23:59:60Z") == 1483228799);
    assert(parsed("2017-01-01T00:59:60+01:00") == 1483228799);        // 23:59:60 UTC
    assert(parsed("2016-06-30T23:59:60Z") == date::days_from_civil(2016, 7, 1) * 86400 - 1);
    assert(parsed("2016-12-31T23:59:60+01:00") == -1);                // 22:59:60 UTC
    assert(parsed("2016-03-31T23:59:60Z") == -1);
    assert(parsed("2016-12-31T12:00:60Z") == -1);

    assert(date::date_ok(0, 1, 1) && date::date_ok(9999, 12, 31) && date::date_ok(2000, 2, 29));
    assert(!date::date_ok(2100, 2, 29) && !date::date_ok(10000, 1, 1) && !date::date_ok(-1, 12, 31));
    assert(!date::date_ok(2026, 0, 1) && !date::date_ok(2026, 13, 1) && !date::date_ok(2026, 4, 31));
}
