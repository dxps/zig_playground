const std = @import("std");

fn _printout(comptime format: []const u8, args: anytype) void {
    std.io.getStdOut().writer().print(format, args) catch |err| {
        std.log.err("Failed to print to stdout: {}", .{err});
    };
}
pub const printout: fn (comptime format: []const u8, args: anytype) void = _printout;
