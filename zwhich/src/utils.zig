const std = @import("std");

pub fn canAccess(io: std.Io, path: []const u8) bool {
    var found: bool = true;
    std.Io.Dir.cwd().access(io, path, .{}) catch |e| switch (e) {
        error.FileNotFound => found = false,
        else => found = false,
    };
    return found;
}

pub fn isFile(io: std.Io, path: []const u8) bool {
    const stat = std.Io.Dir.cwd().statFile(io, path, .{}) catch return false;
    return stat.kind == .file;
}

pub fn isExecutable(io: std.Io, path: []const u8) bool {
    const stat = std.Io.Dir.cwd().statFile(io, path, .{}) catch return false;
    const mode = stat.permissions.toMode();
    return (mode & 0o111) != 0;
}
