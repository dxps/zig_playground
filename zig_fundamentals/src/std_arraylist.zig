const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const alloc = init.gpa;

    // 1. Initialize the list.
    var numbers = std.ArrayList(i32).empty;
    defer numbers.deinit(alloc);

    const stdout = std.Io.File.stdout();
    try stdout.writeStreamingAll(init.io, "Adding numbers 0, 10, 20, 30, 40 ...\n");

    // 2. Append items to the list.
    var i: i32 = 0;
    while (i < 5) : (i += 1) {
        try numbers.append(alloc, i * 10);
    }

    // 3. Modify the list
    if (numbers.items.len > 2) {
        numbers.items[2] = 200;
        try stdout.writeStreamingAll(init.io, "Modified index 2 to 200.\n");
    }

    // 4. Iterate & Print the list's items.
    try stdout.writeStreamingAll(init.io, "List contents: ");
    for (numbers.items) |num| {
        const num_str = try std.fmt.allocPrint(alloc, "{d} ", .{num});
        defer alloc.free(num_str);
        try stdout.writeStreamingAll(init.io, num_str);
    }

    try stdout.writeStreamingAll(init.io, "\n");

    // 5. Pop (returns optional ?i32) an item from the list.
    const last = numbers.pop();
    if (last) |item| {
        const pop_msg = try std.fmt.allocPrint(alloc, "Popped last item: {d}\n", .{item});
        defer alloc.free(pop_msg);
        try stdout.writeStreamingAll(init.io, pop_msg);
    }

    const len_msg = try std.fmt.allocPrint(alloc, "Final list length: {d}\n", .{numbers.items.len});
    defer alloc.free(len_msg);
    try stdout.writeStreamingAll(init.io, len_msg);
}
