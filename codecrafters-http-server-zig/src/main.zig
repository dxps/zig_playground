const std = @import("std");
const net = std.net;

fn _printout(comptime format: []const u8, args: anytype) void {
    std.io.getStdOut().writer().print(format, args) catch |err| {
        std.log.err("Failed to print to stdout: {}", .{err});
    };
}
const printout: fn (comptime format: []const u8, args: anytype) void = _printout;

pub fn main() !void {
    const address = try net.Address.resolveIp("127.0.0.1", 4221);
    var listener = try address.listen(.{
        .reuse_address = true,
    });
    defer listener.deinit();

    printout("Listening to 127.0.0.1:4221 ...\n", .{});

    _ = try listener.accept();
    printout("Client connected!\n", .{});
}
