#!/bin/sh

## Using `nodemon` to detect file changes and trigger the recompilation and restart.
## This can be installed using `npm i -g nodemon`.
## An alternative to `nodemon` may be [entr](https://github.com/eradman/entr).
## This watches just for the binary change.
## In another terminal, `zig build --watch -fincremental` should run.

EXE=jetzig_no-llvm_test
FILEPATH=./zig-out/bin/$EXE

clear
echo ">>> Starting up $FILE ..."
$FILEPATH &

FILE_TIME1=$(stat -c %Y $FILEPATH)
FILE_TIME2=$(stat -c %Y $FILEPATH)

while true; do 
    FILE_TIME2=$(stat -c %Y $FILEPATH)
    if [ $FILE_TIME1 -lt $FILE_TIME2 ]; then
        clear
        echo ">>> $FILE got updated. Starting it again ..."
        killall -HUP $EXE
        $FILEPATH &
        FILE_TIME1=$FILE_TIME2
    else 
        sleep 1
    fi
done
