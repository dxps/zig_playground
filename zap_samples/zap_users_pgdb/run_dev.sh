#!/bin/sh


## Not used for now. It may be helpful, but when properly dealing with "zig build --watch"
## (that is terminating it when this script is terminated).
## nodemon --watch ./zig-out/bin/zap_users_pgdb --exec "killall -HUP zap_users_pgdb && ./zig-out/bin/zap_users_pgdb"

nodemon --watch . --ext zig --exec "killall -HUP zap_users_pgdb 2>/dev/null ; clear ; zig build run -freference-trace=30"

