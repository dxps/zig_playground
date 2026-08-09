const std = @import("std");

// Here we define the function signature of the POSIX access(2) syscall,
// that exists in the C library of the active system.
extern fn access(path: [*:0]const u8, mode: c_int) c_int;

pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());

    if (args.len < 2) {
        std.debug.print("Usage: {s} <path>\n", .{args[0]});
        return;
    }

    const file_path = args[1];

    // Call C function `access()` to check executability.
    if (access(file_path, std.posix.X_OK) == 0) {
        std.debug.print("File '{s}' is executable.\n", .{file_path});
    } else {
        std.debug.print("File '{s}' is not executable.\n", .{file_path});
    }
}
