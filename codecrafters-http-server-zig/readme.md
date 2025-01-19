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

## Setup

-   Ensure you have `zig 0.12 or 0.13 or 0.14` installed locally.
-   Run `./your_program.sh` to run your program.

<br/>

## Usage

```bash
curl -i http://localhost:4221/              # responds with OK (HTTP 200)
curl -i http://localhost:4221/echo/abc      # responds with OK (HTTP 200) and body: abc
curl --header "User-Agent: foobar/1.2.3" http://localhost:4221/user-agent  # responds with OK (HTTP 200) and body: foobar/1.2.3
```
