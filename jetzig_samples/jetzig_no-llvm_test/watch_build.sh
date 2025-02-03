#!/bin/sh

## This script looks for code changes and trigger the build.
## It uses the new Zig 0.14 incremental build feature.

## .zig-cache is removed as a workaround to get rid of the following build error
## that happens in a second iteration of this script.
##
## install
## └─ install jetzig_no-llvm_test
##    └─ zig build-exe jetzig_no-llvm_test Debug native
##       └─ run routes (routes.zig)
##          └─ zig build-exe routes Debug native
##             └─ run manifest (zmpl.manifest.zig) failure
## error: failed to spawn and capture stdio from /home/dxps/.../jetzig_no-llvm_test/.zig-cache/o/176c3a57418caa948485961eb149cc0c/manifest: FileBusy
## Build Summary: 8/14 steps succeeded; 1 failed

rm -rf .zig-cache

zig build --watch -fincremental

