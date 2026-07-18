const std = @import("std");

pub fn main() void {
    var a: i32 = 42;
    const b: *i32 = &a;
    b.* += 1;
    std.debug.print("a: {d}\n", .{a});
}
