// Civil dates in the proleptic Gregorian calendar, and RFC 3339 times, in
// UTC. The day arithmetic is Howard Hinnant's
// (https://howardhinnant.github.io/date_algorithms.html): day 0 is
// 1970-01-01. Text is appended to a builder the caller passes, and a parse
// returns a trailing bool, as Goose's stdlib does. README.md lists the
// functions; leap_ok, punctuated, clock_ok, zone_offset and past_fraction
// are parse_time's helpers.
namespace date;
import std;

// The day number of year `y0`, month `m` (1-12), day `d` (1-31).
fn days_from_civil(y0: i64, m: i64, d: i64) -> i64 {
    let y = if m <= 2 { y0 - 1 } else { y0 };
    let era = (if y >= 0 { y } else { y - 399 }) / 400;
    let yoe = y - era * 400;
    let doy = (153 * (if m > 2 { m - 3 } else { m + 9 }) + 2) / 5 + d - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    return era * 146097 + doe - 719468;
}

// The year, month and day of day number `z0`.
fn civil_from_days(z0: i64) -> i64, i64, i64 {
    let z = z0 + 719468;
    let era = (if z >= 0 { z } else { z - 146096 }) / 146097;
    let doe = z - era * 146097;
    let yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    return yoe + era * 400 + (if m <= 2 { 1 } else { 0 }), m, d;
}

// The number of days in month `m` (1-12) of year `y`.
fn days_in(y: i64, m: i64) -> i64 {
    return days_from_civil(if m == 12 { y + 1 } else { y }, m % 12 + 1, 1) - days_from_civil(y, m, 1);
}

// The day of the week of day number `z`: 0 is Sunday, as cron counts.
fn weekday(z: i64) -> i64 {
    return (z + 4) % 7;
}

// Year 0 to 9999, month 1 to 12, and a day the month has.
fn date_ok(y: i64, m: i64, d: i64) -> bool {
    return y >= 0 && y <= 9999 && m >= 1 && m <= 12 && d >= 1 && d <= days_in(y, m);
}

// The UTC time `t`, seconds since the epoch, as 2026-10-24<sep>12:00:00,
// or 2026-10-24<sep>12:00 without `seconds`. Tools build their own layouts
// on it.
fn format_civil(out: u8[>..]&, t: i64, sep: u8, seconds: bool) {
    let y, m, d = civil_from_days(div_euclid(t, 86400));
    let s = t % 86400;
    format_int(out, y, 10, 4, '0');
    for f, i in [m, d, s / 3600, s / 60 % 60, s % 60] {
        guard i < 4 || seconds else { break; }
        out.push(match i { 0, 1 => '-', 2 => sep, _ => ':' });
        format_int(out, f, 10, 2, '0');
    }
}

// The UTC time `t` in RFC 3339: 2026-10-24T12:00:00Z.
fn format_time(out: u8[>..]&, t: i64) {
    format_civil(out, t, 'T', true);
    out.push('Z');
}

// Seconds since the epoch of an RFC 3339 time such as 2026-10-24T12:34:56Z
// or 2026-10-24 07:34:56.250-05:00; the fraction is dropped. A leap second
// is accepted only at 23:59:60 UTC on June 30 or December 31.
fn parse_time(s: const u8[:]) -> i64, bool {
    guard punctuated(s) else { return 0, false; }
    let y = digits(s, 0, 4);
    let mo = digits(s, 5, 2);
    let d = digits(s, 8, 2);
    let h = digits(s, 11, 2);
    let mi = digits(s, 14, 2);
    let sec = digits(s, 17, 2);
    let off, zoned = zone_offset(s[19..]);
    guard zoned && date_ok(y, mo, d) && clock_ok(h, mi, sec) else { return 0, false; }
    let t = days_from_civil(y, mo, d) * 86400 + h * 3600 + mi * 60 + sec - off;
    guard sec < 60 || leap_ok(t, y) else { return 0, false; }
    // As POSIX time does, a leap second repeats 23:59:59, so it stays in
    // June 30's or December 31's window.
    return if sec == 60 { t - 1 } else { t }, true;
}

// Second 60 is a leap second only at 23:59:60 UTC on June 30 or December
// 31, so t, which counts it as the next second, is the midnight UTC that
// starts July 1 or January 1. The UTC year is y, or one off for a zone.
fn leap_ok(t: i64, y: i64) -> bool {
    guard t % 86400 == 0 else { return false; }
    let day = t / 86400;
    return day == days_from_civil(y, 7, 1) || day == days_from_civil(y, 1, 1) || day == days_from_civil(y + 1, 1, 1);
}

// The separators of YYYY-MM-DDTHH:MM:SS are where they belong.
fn punctuated(s: const u8[:]) -> bool {
    s.len >= 20 && s[4] == '-' && s[7] == '-' && s[13] == ':' && s[16] == ':' && contains("Tt ", s[10])
}

// 60 seconds is a leap second; leap_ok checks the date.
fn clock_ok(h: i64, mi: i64, sec: i64) -> bool { h >= 0 && h < 24 && mi >= 0 && mi < 60 && sec >= 0 && sec <= 60 }

// The zone offset in seconds of what follows the seconds field: an
// optional fraction, then Z or +HH:MM / -HH:MM. false if it is neither.
fn zone_offset(z: const u8[:]) -> i64, bool {
    let rest = z[past_fraction(z)..];
    if rest == "Z" || rest == "z" { return 0, true; }
    guard rest.len == 6 && contains("+-", rest[0]) && rest[3] == ':' else { return 0, false; }
    let h = digits(rest, 1, 2);
    let m = digits(rest, 4, 2);
    guard clock_ok(h, m, 0) else { return 0, false; }
    return (if rest[0] == '-' { -1 } else { 1 }) * (h * 3600 + m * 60), true;
}

// Where the zone starts in what follows the seconds field: past an
// optional fraction such as .250, which is dropped.
fn past_fraction(z: const u8[:]) -> i64 {
    guard z.len > 0 && z[0] == '.' else { return 0; }
    var i = 1;
    while i < z.len && z[i] >= '0' && z[i] <= '9' { i++; }
    return i;
}

// The n-digit number at s[at..], or -1 if any of those bytes is not a digit.
fn digits(s: const u8[:], at: i64, n: i64) -> i64 {
    guard at >= 0 && at + n <= s.len else { return -1; }
    var v = 0;
    for c in s[at..at + n] { guard c >= '0' && c <= '9' else { return -1; } v = v * 10 + (c - '0'); }
    return v;
}
