const std = @import("std");
const Connection = std.net.Server.Connection;

const Map = std.static_string_map.StaticStringMap;
const MethodMap = Map(Method).initComptime(.{
    .{ "GET", Method.GET },
});

pub const Method = enum {
    GET,

    pub fn init(text: []const u8) !Method {
        return MethodMap.get(text).?;
    }

    pub fn is_supported(m: []const u8) bool {
        const method = MethodMap.get(m);
        if (method) |_| {
            return true;
        } else {
            return false;
        }
    }
};

pub const Request = struct {
    method: Method,
    version: []const u8,
    uri: []const u8,

    pub fn init(method: Method, uri: []const u8, version: []const u8) Request {
        return Request{
            .method = method,
            .uri = uri,
            .version = version,
        };
    }
};

pub fn read_request(conn: Connection, buff: []u8) !void {
    const reader = conn.stream.reader();
    _ = try reader.read(buff);
}

pub fn parse_request(text: []u8) Request {
    const line_index = std.mem.indexOfScalar(u8, text, '\n') orelse text.len;
    var iter = std.mem.splitScalar(u8, text[0..line_index], ' ');

    const method = try Method.init(iter.next().?);
    const uri = iter.next().?;
    const version = iter.next().?;
    return Request.init(method, uri, version);
}
