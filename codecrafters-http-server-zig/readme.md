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

On `/echo`:

-   If you send `Accept-Encoding: gzip` header, the response will consider it (include `Content-Encoding: gzip` header).
-   If you send multiple compression schemes:
    -   If provided compression schemes are all invalid, the response won't consider any of them.<br/>
        Ex: `curl -v -H "Accept-Encoding: invalid-encoding" http://localhost:4221/echo/abc`
    -   If provided compression schemes contain `gizp`, this will be considered in the response.<br/>
        Ex: `curl -v -H "Accept-Encoding: invalid-encoding-1, gzip, invalid-encoding-2" http://localhost:4221/echo/abc`<br/>
        Or use `curl -v -H "Accept-Encoding: gzip" http://localhost:4221/echo/abc | hexdump -C`

Complete example of using `/echo` with compressed response:

```shell
❯ curl -v -H "Accept-Encoding: gzip" http://localhost:4221/echo/abc | hexdump -C
*   Trying 127.0.0.1:4221...
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* Connected to localhost (127.0.0.1) port 4221 (#0)
> GET /echo/abc HTTP/1.1
> Host: localhost:4221
> User-Agent: curl/7.81.0
> Accept: */*
> Accept-Encoding: gzip
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Type: text/plain
< Content-Encoding: gzip
< Content-Length: 23
<
{ [23 bytes data]
100    23  100    23    0     0  33093      0 --:--:-- --:--:-- --:--:-- 23000
* Connection #0 to host localhost left intact
00000000  1f 8b 08 00 00 00 00 00  00 03 4b 4c 4a 06 00 c2  |..........KLJ...|
00000010  41 24 35 03 00 00 00                              |A$5....|
00000017
❯
```

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
