const std = @import("std");

pub fn main(init: std.process.Init) !void {
    // 1. Allocate buffers for the streams.
    var out_buf: [4096]u8 = undefined;
    var err_buf: [4096]u8 = undefined;

    // 2. Initialize buffered writers.
    var stdout_impl = std.Io.File.stdout().writer(init.io, &out_buf);
    var stderr_impl = std.Io.File.stderr().writer(init.io, &err_buf);

    // 3. Get the generic writer interfaces.
    const stdout = &stdout_impl.interface;
    const stderr = &stderr_impl.interface;

    var i: usize = 0;
    while (i < 5) : (i += 1) {
        try stdout.print("STDOUT: This is stdout message #{d}\n", .{i});
        try stderr.print("STDERR: This is stderr warning #{d}\n", .{i});
    }

    // 4. Flush.
    try stdout.flush();
    try stderr.flush();
}
