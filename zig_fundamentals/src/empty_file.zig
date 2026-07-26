const std = @import("std");
const createFileAbsolute = std.Io.Dir.createFileAbsolute;

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const filename = "/tmp/empty.txt";

    var existed = false;

    const file = createFileAbsolute(io, filename, .{
        .exclusive = true, // fail if file already exists
    }) catch |err| switch (err) {
        error.PathAlreadyExists => existing_file: {
            existed = true;

            break :existing_file try createFileAbsolute(io, filename, .{ .truncate = true });
        },
        else => return err,
    };
    defer file.close(io);

    if (!existed) {
        std.debug.print("File {s} was created as empty.\n", .{filename});
    } else {
        std.debug.print("File {s} already exists, it was made empty.\n", .{filename});
    }
}
