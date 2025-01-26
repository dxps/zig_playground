# Build Your Own HTTP server in Zig

This the CodeCrafters' challenge of [Build Your Own HTTP server](https://app.codecrafters.io/courses/http-server/overview) in [Zig](https://ziglang.org/) programming language.

![progress-banner](https://backend.codecrafters.io/progress/http-server/28494212-4c3e-44cf-9cff-c613ef267821)

[HTTP](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol) is the
protocol that powers the web. In this challenge, you'll build a HTTP/1.1 server
that is capable of serving multiple clients.

Along the way you'll learn about TCP servers,
[HTTP request syntax](https://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html),
and more.

<br/>

## Setup & Run

-   Ensure you have `zig 0.12 or 0.13` installed locally.
-   Run `./your_program.sh` to run your program.
-   For the case of serving files, use `zig-0.12 build run -- --directory /tmp/test`<br/>
    (`/tmp/test` is just an example.)

Notes: I had to use zig 0.12 due to an external limitation.

<br/>

## Usage

### Get / and /echo

To access the root (`/`) and `/echo` routes, use:

```bash
curl -i http://localhost:4221/              # responds with OK (HTTP 200)
curl -i http://localhost:4221/echo/abc      # responds with OK (HTTP 200) and body: abc
```

On `/echo`, if you send `Accept-Encoding: gzip` header, the response will consider it (include `Content-Encoding: gzip` header).

### Get /user-agent

To access `/user-agent` GET API operation that returns the `User-Agent` header provided in the request, use:

```bash
curl --header "User-Agent: foobar/1.2.3" http://localhost:4221/user-agent  # responds with OK (HTTP 200) and body: foobar/1.2.3
```

### Files - Get & Post

To serve files:

-   Start the app using `zig-0.12 build run -- --directory /tmp/test` (as also previously mentioned)
-   Use `curl -v http://localhost:4221/files/foo` and it will return the content of the file (in this example `/tmp/test/foo` file) if it exists (with `Content-Type: application/octet-stream` header), or 404 if it doesn't exist

To write files:

-   Start the app using `zig-0.12 build run -- --directory /tmp/test` (as also previously mentioned)
-   Use `curl -v --data "123456789" -H "Content-type: application/octe678t-stream" http://localhost:4221/files/foo2` <br/>
    Of course, you may test the result by getting it back, using `curl -v http://localhost:4221/files/foo2`
