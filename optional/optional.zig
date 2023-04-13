const std = @import("std");
const print = std.debug.print;
const expect = std.testing.expect;

fn foo(condition: bool, b: u32) ?u32 {
    const res = if (condition) b else return null;
    return res;
}

fn noreturnTest() void {
    const a = foo(false, 1);
    // if optional a has a value, capture and use it.
    const n = if (a) |v| v else 0;

    print(" type of a is {s}\n", .{@typeName(@TypeOf(a))});
    print(" type of n is {s}\n", .{@typeName(@TypeOf(n))});
}

pub fn main() void {
    noreturnTest();
}
