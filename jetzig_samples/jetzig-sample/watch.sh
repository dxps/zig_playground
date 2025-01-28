#!/bin/sh

## inotifywait comes with inotify-tools package.
## See https://github.com/inotify-tools/inotify-tools/wiki for more info.

##inotifywait -r -m -e modify ./zig-out/bin | 
##   while read file_path file_event file_name; do 
##       ## echo ${file_path}${file_name} event: ${file_event}
##       echo "Detected binary change, restarting the app ..."
##       killall -9 jetzig-sample 
##       ./zig-out/bin/jetzig-sample
##   done

inotifywait -mq --format '%e' ./zig-out/bin/jetzig-sample | while IFS= read -r events
 do
   echo "Detected events: $events"
   echo "Restarting the app ..."
   killall -9 jetzig-sample 
   ./zig-out/bin/jetzig-sample
 done

