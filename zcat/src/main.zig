const std = @import("std");

const zcat = @import("zcat");

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stderr_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writerStreaming(init.io, &stdout_buffer);
    var stderr_writer = std.Io.File.stderr().writerStreaming(init.io, &stderr_buffer);
    const stdout = &stdout_writer.interface;
    const stderr = &stderr_writer.interface;

    var gpa = std.heap.DebugAllocator(.{}).init;
    defer _ = gpa.deinit();
    const ally = gpa.allocator();

    const args = try init.minimal.args.toSlice(ally);
    defer ally.free(args);

    const cwd = std.Io.Dir.cwd();

    for (args[1..]) |filepath| {
        const file = cwd.openFile(init.io, filepath, .{}) catch {
            stderr.print("Error: could not open file '{s}'.\n", .{filepath}) catch {};
            stderr.flush() catch {};
            continue;
        };
        defer file.close(init.io);

        var file_buffer: [1024]u8 = undefined;
        var file_reader = file.reader(init.io, &file_buffer);
        const reader = &file_reader.interface;

        _ = try reader.streamRemaining(stdout);
    }

    try stdout.flush();
}
