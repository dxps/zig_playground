## A _hello world_ like using `http.zig`

This is a starting point of playing with [http.zig](https://github.com/karlseguin/http.zig/), an HTTP/1.1 server for zig.

<br/>

### Setup

1. Use Zig ver. 0.11 (or newer).
    - This project and its `httpz` dependency are both using Zig modules.
    - And this capability was introduced in version 0.11.0 of Zig.
2. The `httpz` dependency is declared in `build.zig` file.
    - See `const httpz_module = b.addModule("httpz", ...` line where the full path to where `http.zig` project exists.
    - Note that full path must be provided. A relative path does not work.
    - This path would be the place where you cloned (`git clone git@github.com:karlseguin/http.zig.git`) the `httpz` project repo.

<br/>

### Run

Use the classic `zig build run` to run it.

<br/>
