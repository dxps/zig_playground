# Zig API operation tester

A dependency-free HTTP smoke tester for Zig `0.17.0-dev`. It cycles fairly
through the configured operations, waits a random interval before each call, compares the HTTP status,
updates an ANSI terminal dashboard, and appends the full result to a JSON Lines
file. The output file is flushed after every call.

## Run

```sh
mise exec -- zig build test
mise exec -- zig build run -- config.example.json
```

The configuration fields are:

- `min_interval_ms`, `max_interval_ms`: inclusive random delay bounds.
- `run_count`: total number of randomly selected calls.
- `output_file`: JSONL result file, truncated at startup.
- `operations`: each has `name`, `url`, uppercase Zig HTTP `method`, optional
  `headers`, optional string `body`, and `expected_status`.

Each JSONL record includes the operation, expected and actual status, elapsed
milliseconds, pass/fail state, and a Zig error name when transport failed.
