const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const filename = "/tmp/empty.txt";

    const file = std.Io.Dir.createFileAbsolute(io, filename, .{
        .exclusive = true, // fail if file already exists
    }) catch |err| switch (err) {
        error.PathAlreadyExists => blk: {
            std.debug.print(
                "File {s} already exists, emptying it.\n",
                .{filename},
            );

            break :blk try std.Io.Dir.createFileAbsolute(io, filename, .{
                .truncate = true,
            });
        },
        else => return err,
    };
    defer file.close(io);

    std.debug.print("File {s} is now empty.\n", .{filename});
}
