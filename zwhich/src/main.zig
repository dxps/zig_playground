const std = @import("std");
const Io = std.Io;

const canAccess = @import("utils.zig").canAccess;
const isExecutable = @import("utils.zig").isExecutable;
const isFile = @import("utils.zig").isFile;

pub fn main(init: std.process.Init) !void {
    // Parse the command line args.
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len < 2) {
        std.log.err("Usage {s} <command>\n", .{args[0]});
        std.process.exit(1);
    }
    const cmd = args[1];
    const stdout = std.Io.File.stdout();

    // Get the PATH environment variable.
    const pathEnv = init.environ_map.get("PATH") orelse {
        std.log.err("PATH variable not found!\n", .{});
        std.process.exit(1);
    };

    // Split PATH into individual directories.
    var dirs = std.mem.splitScalar(u8, pathEnv, ':');

    var found = false;

    while (dirs.next()) |dir| {
        var pathBuf = std.ArrayList(u8).empty;
        defer pathBuf.deinit(init.gpa);

        try pathBuf.appendSlice(init.gpa, dir);
        try pathBuf.append(init.gpa, std.Io.Dir.path.sep);
        try pathBuf.appendSlice(init.gpa, cmd);
        const fullPath = pathBuf.items;

        if (canAccess(init.io, fullPath) and isFile(init.io, fullPath) and isExecutable(init.io, fullPath)) {
            try stdout.writeStreamingAll(init.io, fullPath);
            try stdout.writeStreamingAll(init.io, "\n");
            found = true;
            break;
        }
    }

    if (!found) {
        std.log.err("Command '{s}' not found in PATH", .{cmd});
        return error.FileNotFound;
    }
}
