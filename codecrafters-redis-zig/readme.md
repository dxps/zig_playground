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
2. `ECHO` use case:
    1. Use `redis-cli ECHO "Hello World!"`
3. `SET` use case:
    1. Use `redis-cli SET foo bar`
    2. Use `redis-cli SET foo bar px 2000` to set a key with a TTL (expires in two seconds).
4. `GET` use case:
    1. Use `redis-cli GET foo`
