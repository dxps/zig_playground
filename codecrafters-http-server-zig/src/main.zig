const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const cli = @import("zig-cli");
const handle_connection = @import("handlers.zig").handle_connection;
const log = @import("log.zig").log;
const initLog = @import("log.zig").initLog;

var files_directory: []const u8 = "/tmp";

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    initLog(stdout);

    // The CLI setup.
    var r = try cli.AppRunner.init(std.heap.page_allocator);
    const app = cli.App{
        .command = cli.Command{ .name = "http-server", .options = &.{
            .{
                .long_name = "directory",
                .help = "The directory to server the files from",
                .value_ref = r.mkRef(&files_directory),
            },
        }, .target = cli.CommandTarget{
            .action = cli.CommandAction{ .exec = run_server },
        } },
    };
    return r.run(&app);
}

fn run_server() !void {
    var alloc: std.heap.ThreadSafeAllocator = .{
        .child_allocator = std.heap.page_allocator,
    };

    const address = try net.Address.resolveIp("127.0.0.1", 4221);
    var listener = try address.listen(.{
        .reuse_address = true,
    });
    defer listener.deinit();

    var pool: std.Thread.Pool = undefined;

    try pool.init(std.Thread.Pool.Options{
        .allocator = alloc.child_allocator,
        .n_jobs = 4,
    });
    defer pool.deinit();

    log("Serving files from '{s}' directory.\n", .{files_directory});

    while (true) {
        const connection = try listener.accept();
        try pool.spawn(handle_connection, .{
            connection,
            files_directory,
            alloc.allocator(),
        });
    }
}
