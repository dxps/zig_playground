## zcat

A minimal `cat` implementation (that reads from stdin and writes to stdout) written in [Zig](https://ziglang.org/).

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
