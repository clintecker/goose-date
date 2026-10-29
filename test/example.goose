// The README's example, run by make pkg-test so it keeps compiling.
import std;
import date from "..";

fn main() {
    var out: u8[>..] = [];
    date::format_time(out, 1792843200);
    assert(out == "2026-10-24T12:00:00Z");

    let t, ok = date::parse_time("2026-10-24 07:00:00.250-05:00");
    assert(ok && t == 1792843200);

    let y, m, d = date::civil_from_days(date::days_from_civil(2028, 2, 28) + 1);
    assert(y == 2028 && m == 2 && d == 29);
    assert(date::weekday(date::days_from_civil(2026, 10, 24)) == 6);   // a Saturday
}
