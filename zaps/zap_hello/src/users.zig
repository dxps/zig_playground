const std = @import("std");
const zap = @import("zap");

pub const User = struct {
    first_name: ?[]const u8 = null,
    last_name: ?[]const u8 = null,
};

const UsersStore = struct {
    const Self = @This();

    store: std.AutoHashMap(usize, User),

    fn loadData(self: *Self, a: std.mem.Allocator) !void {
        self.store = std.AutoHashMap(usize, User).init(a);
        try self.store.put(1, .{ .first_name = "Joe" });
        try self.store.put(2, .{ .first_name = "Jane", .last_name = "Black" });
    }

    pub fn get(self: *Self, id: usize) ?User {
        return self.store.get(id);
    }
};

var users_store: UsersStore = undefined;

pub fn initStore(a: std.mem.Allocator) !void {
    users_store = UsersStore{ .store = std.AutoHashMap(usize, User).init(a) };
    try users_store.loadData(a);
}

pub fn handleUsers(r: zap.Request) void {
    if (r.methodAsEnum() != .GET) return;

    // /users/{id}
    if (r.path) |the_path| {
        if (the_path.len < 8 or !std.mem.startsWith(u8, the_path, "/users/")) {
            r.setStatus(.not_found);
            r.sendFile("public/404.html") catch |err| {
                std.log.err("Failed to send 404 page: {}", .{err});
                r.sendBody("404 - Not Found") catch return;
            };
            return;
        }

        const id: usize = @as(usize, @intCast(the_path[7] - 0x30));
        const user = users_store.get(id);

        if (user == null) {
            r.setStatus(.not_found);
            var buff: [128]u8 = undefined;
            const resp = zap.stringifyBuf(&buff, .{ .error_message = "user not found" }, .{}) orelse return;
            r.sendBody(resp) catch return;
            return;
        }

        var buf: [100]u8 = undefined;
        if (zap.stringifyBuf(&buf, user, .{})) |json| {
            r.setContentType(.JSON) catch return;
            r.sendBody(json) catch return;
        }
    }
}
