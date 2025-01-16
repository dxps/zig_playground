const std = @import("std");
const zap = @import("zap");

const User = struct {
    first_name: ?[]const u8 = null,
    last_name: ?[]const u8 = null,
};

fn on_request(r: zap.Request) void {
    if (r.methodAsEnum() != .GET) return;

    // /user/n
    if (r.path) |the_path| {
        if (the_path.len < 7 or !std.mem.startsWith(u8, the_path, "/user/"))
            return;

        const user_id: usize = @as(usize, @intCast(the_path[6] - 0x30));
        const user = users.get(user_id);

        if (user == null) {
            r.setStatus(.not_found);
            var buff: [128]u8 = undefined;
            const resp = zap.stringifyBuf(&buff, .{ .error_message = "User not found" }, .{}) orelse return;
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

const UserMap = std.AutoHashMap(usize, User);

var users: UserMap = undefined;

fn loadUserData(a: std.mem.Allocator) !void {
    users = UserMap.init(a);
    try users.put(1, .{ .first_name = "Joe" });
    try users.put(2, .{ .first_name = "Jane", .last_name = "Black" });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const a = gpa.allocator();

    try loadUserData(a);

    var listener = zap.HttpListener.init(.{
        .port = 3000,
        .on_request = on_request,
        .log = false,
    });
    try listener.listen();

    std.debug.print(
        \\ Listening on 0.0.0.0:3000
        \\ 
        \\ Check out:
        \\ http://localhost:3000/user/1   # -- first user
        \\ http://localhost:3000/user/2   # -- second user
        \\ http://localhost:3000/user/3   # -- non-existing user
        \\
    , .{});

    // start worker threads
    zap.start(.{
        .threads = 2,
        .workers = 1, // user map cannot be shared among multiple worker processes
    });
}
