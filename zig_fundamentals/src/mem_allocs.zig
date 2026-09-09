const std = @import("std");

fn createNumbers(allocator: std.mem.Allocator) ![]u32 {
    const slice = try allocator.alloc(u32, 4);
    for (slice, 0..) |*item, i| {
        item.* = @intCast(i * 10);
    }
    return slice;
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const stdout_file = std.Io.File.stdout();

    // Allocate the buffer explicitly (here, on stack).
    var buf: [4096]u8 = undefined;

    // Init the writer with the buffer. It returns a concrete struct specific to a `File`.
    var stdout_impl = stdout_file.writer(io, &buf);

    // Get the standard `Writer` interface pointer.
    const stdout = &stdout_impl.interface;

    // Guarantee the cleanup happens, preventing truncated output.
    defer stdout.flush() catch {};

    // -------------------------------------------------------
    // General Purpose Allocator (GPA)
    // With Zig 0.16 or later, this is called Debug Allocator.
    // It is designed to balance performance with safety.
    // -------------------------------------------------------

    var gpa: std.heap.DebugAllocator(.{}) = .init;
    // This writes any leak information directly to stderr as a side effect.
    // And it returns (for you to act on it, if you want) a `Check` enum value
    // that indicates whether any leaks were detected.
    defer _ = gpa.deinit();
    const gpa_allocator = gpa.allocator();

    const numbers = try createNumbers(gpa_allocator);
    try stdout.print("GPA numbers: {any}\n", .{numbers});
    gpa_allocator.free(numbers);

    // ---------------
    // Arena Allocator
    // ---------------

    var arena: std.heap.ArenaAllocator = .init(gpa_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    const n1 = try createNumbers(arena_allocator);
    const n2 = try createNumbers(arena_allocator);
    try stdout.print("Arena numbers: {any}, {any}\n", .{ n1, n2 });

    // ----------------------
    // Fixed Buffer Allocator
    // ----------------------

    var stack_buf: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&stack_buf);
    const fba_allocator = fba.allocator();

    const n3 = try createNumbers(fba_allocator);
    try stdout.print("Stack numbers: {any}\n", .{n3});
}
