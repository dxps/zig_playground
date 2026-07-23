const std = @import("std");
const Io = std.Io;

const zcat = @import("zcat");

pub fn main(init: std.process.Init) !u8 {
    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const ally = gpa.allocator();

    const cwd = std.Io.Dir.cwd();

    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    const args = try init.minimal.args.toSlice(ally);
    defer ally.free(args);

    for (args[1..]) |filepath| {
        const max_bytes = 16 * 1024 * 1024;
        const text = cwd.readFileAlloc(init.io, filepath, ally, .limited(max_bytes)) catch |err| switch (err) {
            error.FileNotFound => {
                std.debug.print("Error: file not found '{s}'.\n", .{filepath});
                continue;
            },
            else => {
                std.debug.print("Error: failed reading file: {s}: {s}\n", .{ filepath, @errorName(err) });
                continue;
            },
        };
        defer ally.free(text);

        try stdout.writeAll(text);
    }

    try stdout.flush();
    return 0;
}
