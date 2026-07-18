///
/// This is a pointer to a constant aka "read-only pointer"
/// meaning a pointer whose pointed-to value cannot be modified through that pointer.
///
/// The important distinction is that `const ptr: *i32 = &value;` means that
/// `ptr` itself cannot be reassigned, but the pointed-to value may still be mutable.
///
const std = @import("std");

pub fn main() void {
    var a: i32 = 42;

    const b: *const i32 = &a;

    b.* += 1; // This fails to compile: "error: cannot assign to constant"

    std.debug.print("a: {d}\n", .{a});
}
