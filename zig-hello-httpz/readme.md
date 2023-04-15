## A _hello world_ like into `http.zig`

This is a starting point of playing with [http.zig](https://github.com/karlseguin/http.zig/), an HTTP/1.1 server for zig.

<br/>

### Setup

1. Use Zig ver. 0.11 (or newer), since this example and its `httpz` dependency both are using native Zig module.
2. The `httpz` dependency is declared in `build.zig` file by providing a full path to the location where the starting point file of `http.zig` project exists. This path must point (correctly reflect) your local setup, aka where you cloned (`git clone git@github.com:karlseguin/http.zig.git`) that project's repo.

<br/>

### Run

Use the classic `zig build run` to run it.

<br/>
