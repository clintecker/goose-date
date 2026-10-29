# clintecker/goose-date

Civil dates and RFC 3339 times for [Goose](https://github.com/aardappel/goose), in UTC. Pure Goose over `i64`: no allocation, no C, nothing shared between threads.

```goose
import date from "clintecker/goose-date@v1";

var out: u8[>..] = [];
date::format_time(out, 1792843200);                                // 2026-10-24T12:00:00Z
let t, ok = date::parse_time("2026-10-24 07:00:00.250-05:00");     // 1792843200, true
let y, m, d = date::civil_from_days(date::days_from_civil(2028, 2, 28) + 1);   // 2028, 2, 29
```

`test/example.goose` is this example with asserts.

## Functions

Times are seconds since 1970-01-01T00:00:00Z. Day numbers count days from 1970-01-01, which is day 0.

| Function | What it does |
|---|---|
| `days_from_civil(y, m, d) -> i64` | the day number of a date in the proleptic Gregorian calendar, for any year |
| `civil_from_days(z) -> i64, i64, i64` | the year, month and day of a day number |
| `days_in(y, m) -> i64` | the number of days in month `m` of year `y` |
| `weekday(z) -> i64` | the day of the week of a day number, 0 for Sunday as cron counts |
| `date_ok(y, m, d) -> bool` | true for a date that exists, in years 0 to 9999 |
| `format_civil(out, t, sep, seconds)` | appends `2026-10-24 12:00:00`, with `sep` between the date and the clock; `seconds` false leaves off `:SS` |
| `format_time(out, t)` | appends RFC 3339 in UTC: `2026-10-24T12:00:00Z` |
| `parse_time(s) -> i64, bool` | reads RFC 3339 with `T`, `t` or a space, an optional fraction (dropped), and `Z`, `z` or `+HH:MM`/`-HH:MM`; `false` for anything else |
| `digits(s, at, n) -> i64` | the `n`-digit number at `s[at..]`, or -1 when a byte is not a digit or the field runs past the end |

Text is appended to a builder the caller passes, and a parse returns a trailing `bool`, as Goose's stdlib does. `leap_ok`, `punctuated`, `clock_ok`, `zone_offset` and `past_fraction` are `parse_time`'s helpers; Goose has no private functions, so they are visible, but they are not part of the interface and may change.

## Limits

- UTC only: no local time and no time zones by name, which need the C library and a zone database.
- Formatting pads the year to 4 digits; `format_time` is exact for years 0 to 9999 and `parse_time` reads only those.
- A leap second is accepted only at 23:59:60 UTC on June 30 or December 31, and reads as 23:59:59 of that day, as POSIX time counts it. Whether that day had one is not checked.

## Tests

`test/*.goose` are assert programs, run from this directory with `goose run test/date_test.goose`. `test/check-rfc3339.py` compares `format_time` with Python's `datetime` on 100,004 times in years 1 to 9999.

MIT licence (LICENSE).
