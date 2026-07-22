const std = @import("std");
const Io = std.Io;

const zcat = @import("zcat");

pub fn main(init: std.process.Init) !u8 {
    const filepath = "meow.txt";

    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const ally = gpa.allocator();

    const cwd = std.Io.Dir.cwd();
    const max_bytes = 16 * 1024 * 1024;
    const text = cwd.readFileAlloc(init.io, filepath, ally, .limited(max_bytes)) catch |err| switch (err) {
        error.FileNotFound => {
            std.debug.print("File not found: {s}\n", .{filepath});
            return 1;
        },
        else => {
            std.debug.print("Error reading file: {s}: {s}\n", .{ filepath, @errorName(err) });
            return 2;
        },
    };
    defer ally.free(text);

    const stdout_file = std.Io.File.stdout();
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = stdout_file.writer(init.io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll(text);
    try stdout.flush();
    return 0;
}
