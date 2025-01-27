# Build Your Own Redis in Zig

This is my solution to ["Build Your Own Redis" Challenge](https://codecrafters.io/challenges/redis).

In this challenge, you'll build a toy Redis clone that's capable of handling
basic commands like `PING`, `SET` and `GET`. Along the way we'll learn about
event loops, the Redis protocol and more.

<br/>

# Setup & Run

1. Ensure you have `zig (0.13+)` installed locally.
2. Use `./your_program.sh` or `./run.sh` to run the Redis server.

<br/>

# Usage

1. `PING` use case:
    1. Use `redis-cli PING` or `echo -e "PING\nPING" | redis-cli`
