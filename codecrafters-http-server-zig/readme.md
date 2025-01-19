# Build Your Own HTTP server in Zig

This the CodeCrafters' challenge of [Build Your Own HTTP server](https://app.codecrafters.io/courses/http-server/overview) in [Zig](https://ziglang.org/) programming language.

[![progress-banner](https://backend.codecrafters.io/progress/http-server/28494212-4c3e-44cf-9cff-c613ef267821)](https://app.codecrafters.io/users/codecrafters-bot?r=2qF)

[HTTP](https://en.wikipedia.org/wiki/Hypertext_Transfer_Protocol) is the
protocol that powers the web. In this challenge, you'll build a HTTP/1.1 server
that is capable of serving multiple clients.

Along the way you'll learn about TCP servers,
[HTTP request syntax](https://www.w3.org/Protocols/rfc2616/rfc2616-sec5.html),
and more.

<br/>

## Setup

-   Ensure you have `zig (0.14)` installed locally
-   Run `./your_program.sh` to run your program, which is implemented in
    `src/main.zig`.

<br/>

## Usage

```bash
curl -i http://localhost:4221/ # must respond with OK
curl -i http://localhost:4221/echo/abc # must respond with OK and body: abc
```
