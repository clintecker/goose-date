// Reads one number of seconds since the epoch per line on stdin and prints
// date::format_time of each, for test/check-rfc3339.py.
import std;
import os;
import date from "../..";

fn main() {
    var line: u8[>..] = [];
    var out: u8[>..] = [];
    loop {
        line.clear();
        guard read_line(line) else { break; }
        let t, ok = parse_int(line);
        assert(ok);
        date::format_time(out, t);
        out.push('\n');
    }
    write_stdout(out);
}
