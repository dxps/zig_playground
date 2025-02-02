const std = @import("std");
const pg = @import("pg");

pub var pool: *pg.Pool = undefined;

pub fn init(a: std.mem.Allocator) !void {
    pool = try pg.Pool.init(a, .{
        .size = 5,
        .connect = .{
            .host = "localhost",
            .port = 5456,
        },
        .auth = .{
            .username = "zig",
            .password = "cool",
            .database = "zig_samples",
            .application_name = "zap_users_pgdb",
            .timeout = 5_000,
        },
    });
}

pub fn getServerVersion() ![]const u8 {
    var conn = try pool.acquire();
    defer conn.release();
    var row = (try conn.row("SELECT setting from pg_settings WHERE name = 'server_version'", .{})) orelse unreachable;
    defer row.deinit() catch {};

    return row.get([]const u8, 0);
}
