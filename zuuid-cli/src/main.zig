const std = @import("std");
const Io = std.Io;
const Writer = Io.Writer;

const zuuid = @import("zuuid");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const sout = stdout(io);
    defer sout.flush() catch {};

    var count: usize = 1;
    var use_uppercase = false;

    var iter = init.minimal.args.iterate();
    defer iter.deinit();
    // Skip the first argument, which is the program name.
    _ = iter.next();
    while (iter.next()) |arg| {
        if (std.mem.eql(u8, arg, "-u")) {
            use_uppercase = true;
        } else if (std.mem.eql(u8, arg, "-n")) {
            // If `-n` is found, the "next" argument must be a number.
            if (iter.next()) |num_str| {
                count = try std.fmt.parseInt(usize, num_str, 10);
            } else {
                try sout.print("Error: -n requires a number argument.\n", .{});
                return error.InvalidArgs;
            }
        }
    }

    var buf: [37]u8 = undefined; // 36 characters (for UUID) + new line character (`\n`).
    var i: usize = 0;
    while (i < count) : (i += 1) {
        const id = zuuid.Uuid.v4(io);
        const s = if (use_uppercase)
            std.fmt.bufPrint(&buf, "{f}\n", .{id.fmtUpper()}) catch unreachable
        else
            std.fmt.bufPrint(&buf, "{f}\n", .{id}) catch unreachable;
        try sout.writeAll(s);
    }

    try sout.flush();
}

fn stdout(io: Io) *Writer {
    var buffer: [4096]u8 = undefined;
    var stdout_impl = std.Io.File.stdout().writer(io, &buffer);
    return &stdout_impl.interface;
}
