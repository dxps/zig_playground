const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const handleConnection = @import("handlers.zig").handleConnection;
const initLog = @import("log.zig").initLog;
const initStore = @import("handlers.zig").initStore;
const log = @import("log.zig").log;
const Store = @import("datastore.zig").Store;

const CliConfig = struct {
    dir: []const u8,
    dbfilename: []const u8,
};

pub fn main() !void {

    // Logging init.
    const stdout = std.io.getStdOut().writer();
    initLog(stdout);

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    defer _ = gpa.deinit();

    const cli_flags = getDirAndDbfilenameArgs(a) catch
        CliConfig{ .dir = "/tmp", .dbfilename = "store.db" };
    log("dir='{s}', dbfilename='{s}'.\n", .{
        cli_flags.dir,
        cli_flags.dbfilename,
    });

    initStore(a, cli_flags.dir, cli_flags.dbfilename);

    // Start the server.
    try runServer();
}

fn runServer() !void {
    var alloc: std.heap.ThreadSafeAllocator = .{
        .child_allocator = std.heap.page_allocator,
    };

    const address = try net.Address.resolveIp("127.0.0.1", 6379);
    var listener = try address.listen(.{ .reuse_address = true });
    defer listener.deinit();

    var pool: std.Thread.Pool = undefined;
    try pool.init(.{
        .allocator = alloc.child_allocator,
        .n_jobs = 4,
    });
    defer pool.deinit();

    while (true) {
        const connection = try listener.accept();

        log("Accepted new connection from '{any}'.\n", .{connection.address});
        try pool.spawn(handleConnection, .{
            connection,
            alloc.allocator(),
        });
    }
}

/// Get the value of `--dir` and `--dbfilename` arguments passed at the command line.
fn getDirAndDbfilenameArgs(a: Allocator) !CliConfig {
    const args = try std.process.argsAlloc(a);
    defer std.process.argsFree(a, args);

    if (args.len < 5 or !std.mem.eql(u8, args[1], "--dir") or !std.mem.eql(u8, args[3], "--dbfilename")) {
        return error.InvalidArguments;
    }
    const dir = try a.dupe(u8, args[2]);
    const dbfilename = try a.dupe(u8, args[4]);

    return .{ .dir = dir, .dbfilename = dbfilename };
}
