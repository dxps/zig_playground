# Zig API operation tester

A dependency-free HTTP smoke tester for Zig `0.17.0-dev`. It cycles fairly
through the configured operations, waits a random interval before each call, compares the HTTP status,
updates an ANSI terminal dashboard, and writes the results to a JSON file.
Results are elements of a JSON array and are flushed after every call.

## Run

```sh
mise exec -- zig build test
mise exec -- zig build run -- config.example.json
```

The configuration fields are:

- `min_interval_ms`, `max_interval_ms`: inclusive random delay bounds.
- `max_wait_ms`: maximum time allowed for one HTTP call, including its response body.
- `run_count`: total number of randomly selected calls.
- `output_file`: JSON result file, truncated at startup.
- `operations`: each has `name`, `url`, uppercase HTTP `method`, optional
  `headers`, optional JSON `body`, and `expected_status`. Object and array bodies
  are JSON-encoded; string bodies are sent as raw text.

Each object in the JSON array includes the operation, expected and actual status, elapsed
milliseconds, pass/fail state, and a Zig error name when transport failed. When
the actual HTTP status differs from `expected_status`, it also includes the
response body in `response_body`.
