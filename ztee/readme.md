## ztee

A Zig based `tee` implementation. Its primary function is to read from standard input and duplicate that content to files and the console (aka stdout), while completely ignoring standard error.

<br/>

### Usage

Using `zig build run`:

```shell
zig run src/main.zig -- /tmp/ztee.log
```

<br/>

### Test

A dedicated test utility is included:

```shell
zig run src/test.zig | zig run src/main.zig -- /tmp/ztee.log
```
