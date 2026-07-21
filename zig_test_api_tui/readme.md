# API operation tester

A dependency-free HTTP smoke tester for Zig `0.17.0-dev`. It cycles fairly
through the configured operations, waits a random interval before each call, compares the HTTP status,
updates an ANSI terminal dashboard, and writes the results to a JSON file.
Results are elements of a JSON array and are flushed after every call.

<br/>

## Config

The configuration fields are:

- `min_interval_ms`, `max_interval_ms`: inclusive random delay bounds.
- `max_wait_ms`: maximum time allowed for one HTTP call, including its response body.
- `run_count`: total number of randomly selected calls.
- `output_file`: JSON result file, truncated at startup.
- `operations`: each has `name`, `url`, uppercase HTTP `method`, optional
  `headers`, optional JSON `body`, and `expected_status`. Object and array bodies
  are JSON-encoded; string bodies are sent as raw text.

Each object in the JSON array includes the operation, its UTC `start_time` in
`YYYY-MM-DD HH:mm:ss.SSS` format, expected and actual status, elapsed
milliseconds, pass/fail state, and a Zig error name when transport failed. When
the actual HTTP status differs from `expected_status`, it also includes the
response body in `response_body`.

<br/>

## Run

```sh
mise exec -- zig build test
mise exec -- zig build run -- config.example.json
```

<br/>

## Build

You may first run tests using:

```sh
mise exec -- zig build test
```

Cross-compile release executables for Apple Silicon macOS, x86-64 Linux, and x86-64 Windows can be done using:

```sh
mise exec -- zig build -Doptimize=ReleaseSafe -Dtarget=aarch64-macos -p zig-out/dist/macos-aarch64
mise exec -- zig build -Doptimize=ReleaseSafe -Dtarget=x86_64-linux -p zig-out/dist/linux-x86_64
mise exec -- zig build -Doptimize=ReleaseSafe -Dtarget=x86_64-windows -p zig-out/dist/windows-x86_64
```

The resulting executables are:

- `zig-out/dist/macos-aarch64/bin/api_test_tui`
- `zig-out/dist/linux-x86_64/bin/api_test_tui`
- `zig-out/dist/windows-x86_64/bin/api_test_tui.exe`

For an Intel Mac, replace `aarch64-macos` with `x86_64-macos`. For ARM64
Linux, replace `x86_64-linux` with `aarch64-linux` and use a different prefix.
