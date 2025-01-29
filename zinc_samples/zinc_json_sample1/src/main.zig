const std = @import("std");
const log = @import("log.zig").log;
const initLog = @import("log.zig").initLog;
const zinc = @import("zinc");

pub fn main() !void {

    // Logging init.
    const stdout = std.io.getStdOut().writer();
    initLog(stdout);

    const port = 8181;
    // API Server init.
    var z = try zinc.init(.{ .port = port });

    var router = z.getRouter();
    try router.get("/", helloWorld);

    log("API Server starts listening on port {} ...\n", .{port});
    try z.run();
}

fn helloWorld(ctx: *zinc.Context) anyerror!void {
    try ctx.json(.{ .message = "Hello, World!" }, .{});
}
