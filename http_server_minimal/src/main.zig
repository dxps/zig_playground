const std = @import("std");
const builtin = @import("builtin");
const net = std.net;
const Socket = @import("socket.zig").Socket;
const read_request = @import("request.zig").read_request;
const parse_request = @import("request.zig").parse_request;

const stdout = std.io.getStdOut().writer();
// The alternative - that can be more performant - is this:
// const stdout_file = std.io.getStdOut().writer();
// var bw = std.io.bufferedWriter(stdout_file);
// const stdout = bw.writer();
// try stdout.print("Something to log ...\n", .{});
// try bw.flush(); // Don't forget to flush!

pub fn main() !void {
    const socket = try Socket.init();
    try stdout.print("Socket address: {any}\n", .{socket._address});
    var server = try socket._address.listen(.{});

    const conn = try server.accept();
    try stdout.print("Accepted connection from '{any}'.\n", .{conn.address});

    var buff: [1024]u8 = [_]u8{0} ** 1024;
    _ = try read_request(conn, &buff);
    const request = parse_request(&buff);
    try stdout.print("Request: {any}\n", .{request});
}
