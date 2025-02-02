## Testing the new Jetzig implementation

A minimal test using Jetzig's [no-llvm](https://github.com/jetzig-framework/jetzig/tree/no-llvm) branch, whose purpose is to improve the build times between code changes.

<br/>

### Start

#### Setup

-   Use Jetzig's [no-llvm](https://github.com/jetzig-framework/jetzig/tree/no-llvm) branch for Jetzig CLI.
-   Use Zig version 0.14.

#### Run

You can start it in "development mode" (it restarts the server on code changes) using `./run_dev.sh`.<br/>
Otherwise, the standard `zig build run` should do the job.
