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

test "filesystem helpers" {
    const testing = std.testing;

    // Get an `Io` instance for the test.
    var t: std.Io.Threaded = .init_single_threaded;
    const io = t.io();

    // Sandbox init.
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    // Create a file (keep it open for `fchmod` later).
    const filename = "test_bin";
    const file = try tmp.dir.createFile(io, filename, .{});
    defer file.close(io);

    // Create a directory.
    const dirname = "test_subdir";
    try tmp.dir.createDir(io, dirname, .default_dir);

    // Resolve the full (absolute) paths of the file and directory.
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    const abs_file_len = try tmp.dir.realPathFile(io, filename, &path_buf);
    const abs_file_path = path_buf[0..abs_file_len];

    const subdir = try tmp.dir.openDir(io, dirname, .{});
    defer subdir.close(io);
    var dir_buf: [std.fs.max_path_bytes]u8 = undefined;
    const abs_dir_len = try subdir.realPath(io, &dir_buf);
    const abs_dir_path = dir_buf[0..abs_dir_len];

    // TEST: canAccess
    try testing.expect(canAccess(io, abs_file_path));
    try testing.expect(!canAccess(io, "non_existent_file"));

    // TEST: isFile
    try testing.expect(isFile(io, abs_file_path));
    try testing.expect(!isFile(io, abs_dir_path));

    // TEST: isExecutable
    if (@import("builtin").os.tag != .windows) {
        // Case A: Make it executable (755)
        _ = std.c.fchmod(file.handle, 0o755);
        try testing.expect(isExecutable(io, abs_file_path));

        // Case B: Make it non-executable (644)
        _ = std.c.fchmod(file.handle, 0o644);
        try testing.expect(!isExecutable(io, abs_file_path));
    }
}
