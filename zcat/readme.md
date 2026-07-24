## zcat

A minimal `cat` implementation (that reads from stdin and writes to stdout) written in [Zig](https://ziglang.org/).

<br/>

## Build

Besides the standard build, there are options for reader and writer buffers sizes to compile a version that is appropriate for your needs (such as embedded, or systems with large memory). For example, to build a release with 8k reader and writer buffer, run:

```shell
zig build -Dtarget=x86_64-linux -Doptimize=ReleaseFast \
    -Dreader-buffer-size=8192 \
    -Dwriter-buffer-size=8192
```

<br/>

## Usage

Using the classic build and run approach, you just have to pass as arguments one or more files.

Example:

```shell
❯ zig build run -- meow.txt fake woof.txt
Error: file not found 'fake'.
Meeoowwww!
Woof!
❯
```

Or, using the binary:

```shell
❯ ./zig-out/bin/zcat meow.txt woof.txt
Meeoowwww!
Woof!
❯
```
