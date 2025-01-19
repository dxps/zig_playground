const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const printout = @import("printout.zig").printout;

pub fn main() !void {
    const address = try net.Address.resolveIp("127.0.0.1", 4221);
    var listener = try address.listen(.{
        .reuse_address = true,
    });
    defer listener.deinit();

    printout("Listening to 127.0.0.1:4221 ...\n", .{});

    const conn = try listener.accept();
    printout("Received connection from {}.\n", .{conn.address});
    const stream = conn.stream;

    // Allocate a buffer to read into.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const a = gpa.allocator();
    const buff = try a.alloc(u8, 512);
    defer a.free(buff);

    _ = stream.read(buff) catch |err| {
        printout("Failed to read from client stream: {}\n", .{err});
    };

    // First line of the request, containing request's: "{http-method} {url_path} {http_version}".
    var buff_iter = std.mem.splitAny(u8, buff, "\r\n");
    const first_line = buff_iter.next().?;

    var line_iter = std.mem.splitAny(u8, first_line, " ");
    if (!std.mem.startsWith(u8, line_iter.next().?, "GET")) {
        try respond_not_found(stream);
        return;
    }

    const url_path = line_iter.next().?;

    if (std.mem.eql(u8, url_path, "/")) {
        try respond_ok(stream);
        return;
    }

    if (url_path.len < 6) {
        try respond_not_found(stream);
        return;
    }

    if (std.mem.eql(u8, url_path[0..6], "/echo/")) {
        try respond_ok_with_text_and_body(a, stream, url_path[6..]); // the body is the text after the "/echo/".
    }
    if (std.mem.eql(u8, url_path[0..], "/user-agent")) {
        // Walking through the next lines of the request, which are the http headers.
        var header_line = buff_iter.next();
        while (header_line != null) {
            line_iter = std.mem.splitAny(u8, header_line.?, " ");
            const header_name = lowercase(a, line_iter.next().?);
            if (!std.mem.startsWith(u8, header_name, "user-agent")) {
                header_line = buff_iter.next();
            } else {
                const user_agent = line_iter.next().?;
                printout("Responding with header user-agent value: {s}\n", .{user_agent});
                try respond_ok_with_text_and_body(a, stream, user_agent);
                break;
            }
        }
    } else {
        try respond_not_found(stream);
    }
}

fn respond_ok(stream: anytype) !void {
    try stream.writeAll("HTTP/1.1 200 OK\r\n\r\n");
}

fn respond_ok_with_text_and_body(a: Allocator, stream: anytype, body: []const u8) !void {
    const res = try std.fmt.allocPrint(a, "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: {d}\r\n\r\n{s}", .{ body.len, body });
    try stream.writeAll(res);
}

fn respond_not_found(stream: anytype) !void {
    try stream.writeAll("HTTP/1.1 404 Not Found\r\n\r\n");
}

fn lowercase(a: Allocator, line: []const u8) []const u8 {
    const tmp: []u8 = a.alloc(u8, line.len) catch unreachable;
    return std.ascii.lowerString(tmp, line);
}
