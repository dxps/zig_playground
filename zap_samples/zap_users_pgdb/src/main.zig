const std = @import("std");
const builtin = @import("builtin");
const initLog = @import("log.zig").initLog;
const log = @import("log.zig").log;
const db = @import("db.zig");

pub fn main() !void {

    // Logging init.
    const stdout = std.io.getStdOut().writer();
    initLog(stdout);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const a = if (builtin.mode == .Debug) gpa.allocator() else std.heap.c_allocator;

    try db.init(a);
    defer db.pool.deinit();

    const serverVersion = try db.getServerVersion();
    log("Connected to PosgreSQL version '{s}'.\n", .{serverVersion});
}
