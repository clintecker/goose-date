#!/usr/bin/env python3
"""Checks date::format_time against Python's datetime.

Run from the package root:
    python3 -I test/check-rfc3339.py
It formats 100,000 random times in years 1 to 9999, plus both ends of
that range, with test/rfc3339/print_times.goose and with
datetime.fromtimestamp(t, timezone.utc).isoformat(), whose "+00:00" is
written "Z". It prints one line per difference and exits 1 on any.
"""
import random, subprocess, sys
from datetime import datetime, timezone

FIRST = int(datetime(1, 1, 1, tzinfo=timezone.utc).timestamp())
LAST = int(datetime(9999, 12, 31, 23, 59, 59, tzinfo=timezone.utc).timestamp())

rng = random.Random(168)
times = [FIRST, LAST, -1, 0] + [rng.randint(FIRST, LAST) for _ in range(100000)]
run = subprocess.run(["goose", "run", "test/rfc3339/print_times.goose"],
                     input="".join(f"{t}\n" for t in times),
                     capture_output=True, text=True)
got = run.stdout.splitlines()
if run.returncode != 0 or len(got) != len(times):
    print(f"print_times exited {run.returncode} with {len(got)} of {len(times)} lines")
    print(run.stderr[-2000:])
    sys.exit(1)
bad = 0
for t, g in zip(times, got):
    want = datetime.fromtimestamp(t, timezone.utc).isoformat().replace("+00:00", "Z")
    if g != want:
        bad += 1
        print(f"DIFF {t}: goose {g}, python {want}")
print(f"same {len(times) - bad} of {len(times)} times")
sys.exit(1 if bad else 0)
