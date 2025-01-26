const std = @import("std");

pub const Request = struct {
    request_line: []const u8,
    headers: []const u8,
    body: []const u8,

    const Self = @This();

    pub fn parse(input: []const u8) Request {
        var iter = std.mem.splitSequence(u8, input, "\r\n\r\n");
        const request_line_and_headers = iter.next().?;
        const body = iter.rest();
        var headers_iter = std.mem.splitSequence(u8, request_line_and_headers, "\r\n");
        return Request{
            .request_line = headers_iter.first(),
            .headers = headers_iter.rest(),
            .body = body,
        };
    }

    // Get request's HTTP method.
    pub fn getMethod(self: *Self) []const u8 {
        var request_line_iter = std.mem.splitSequence(u8, self.request_line, " ");
        return request_line_iter.first();
    }

    // Get request's URL.
    pub fn getTarget(self: *Self) ?[]const u8 {
        var request_line_iter = std.mem.splitSequence(u8, self.request_line, " ");
        _ = request_line_iter.first();
        return request_line_iter.next();
    }

    // Get request's header.
    pub fn getHeader(self: *Self, header_name: []const u8) ?[]const u8 {
        var header_iter = std.mem.splitSequence(u8, self.headers, "\r\n");
        while (header_iter.next()) |header| {
            var header_split = std.mem.splitSequence(u8, header, ": ");
            if (std.mem.eql(u8, header_split.next().?, header_name)) {
                return header_split.next();
            }
        }
        return null;
    }

    // Get request's "User-Agent" header.
    pub fn getUserAgent(self: *Self) ?[]const u8 {
        return self.getHeader("User-Agent");
    }
};
