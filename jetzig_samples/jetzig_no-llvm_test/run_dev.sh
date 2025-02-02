#!/bin/sh

## Using `nodemon` to detect file changes and trigger the recompilation and restart.
## This can be installed using `npm i -g nodemon`.
## An alternative to `nodemon` may be [entr](https://github.com/eradman/entr).

## Not used for now. It may be helpful, but when properly dealing with "zig build --watch"
## (that is terminating it when this script is terminated).
## nodemon --watch ./zig-out/bin/jetzig_no-llvm_test --exec "killall -HUP jetzig_no-llvm_test && ./zig-out/bin/jetzig_no-llvm_test"


nodemon --watch . --ext zig --exec "killall -HUP jetzig_no-llvm_test 2>/dev/null ; clear ; zig build run -freference-trace=30"

