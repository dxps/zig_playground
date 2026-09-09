//! Code taken from [here](https://github.com/mactsouk/zigSP/blob/main/ch03/customMemoryAllocator.zig),
//! while studying "Systems Programming with Zig" book (2026, Packt Pub).
//!
const std = @import("std");

const bitsInByte = 8;

fn printHeader() void {
    std.debug.print(
        \\| action               | result (current) usage |
        \\|----------------------+------------------------|
        \\
    , .{});
}

fn printRow(
    action: []const u8,
    value: usize,
    unit: []const u8,
) void {
    var result_buf: [64]u8 = undefined;

    const result = std.fmt.bufPrint(
        &result_buf,
        "{d} {s}",
        .{ value, unit },
    ) catch unreachable;

    std.debug.print(
        "| {s:<20} | {s:<22} |\n",
        .{ action, result },
    );
}

fn printChange(
    verb: []const u8,
    amount: usize,
    current: usize,
) void {
    var action_buf: [64]u8 = undefined;

    const action = std.fmt.bufPrint(
        &action_buf,
        "{s} {d} bytes",
        .{ verb, amount },
    ) catch unreachable;

    printRow(action, current, "bytes");
}

pub const TrackingAllocator = struct {
    allocator: std.mem.Allocator,
    allocBytes: usize,

    pub fn init(allocator: std.mem.Allocator) TrackingAllocator {
        return TrackingAllocator{
            .allocator = allocator,
            .allocBytes = 0,
        };
    }

    pub fn alloc(
        self: *TrackingAllocator,
        comptime T: type,
        n: usize,
    ) ![]T {
        const initialValue = self.allocBytes;

        const slice = try self.allocator.alloc(T, n);

        self.allocBytes += @sizeOf(T) * n;
        const allocated = self.allocBytes - initialValue;

        printChange(
            "allocated",
            allocated,
            self.allocBytes,
        );

        return slice;
    }

    pub fn free(
        self: *TrackingAllocator,
        comptime T: type,
        slice: []T,
    ) void {
        if (slice.len > 0) {
            const initialValue = self.allocBytes;

            self.allocBytes -= @sizeOf(T) * slice.len;
            self.allocator.free(slice);

            const freed = initialValue - self.allocBytes;

            printChange(
                "freed",
                freed,
                self.allocBytes,
            );
        }
    }

    pub fn create(
        self: *TrackingAllocator,
        comptime T: type,
    ) !*T {
        const initialValue = self.allocBytes;

        const memory = try self.allocator.create(T);

        self.allocBytes += @sizeOf(T);
        const allocated = self.allocBytes - initialValue;

        printChange(
            "allocated",
            allocated,
            self.allocBytes,
        );

        return memory;
    }

    pub fn destroy(
        self: *TrackingAllocator,
        comptime T: type,
        memory: *T,
    ) void {
        const initialValue = self.allocBytes;

        self.allocBytes -= @sizeOf(T);
        self.allocator.destroy(memory);

        const freed = initialValue - self.allocBytes;

        printChange(
            "freed",
            freed,
            self.allocBytes,
        );
    }

    pub fn bytesAllocated(self: *TrackingAllocator) usize {
        return self.allocBytes;
    }

    pub fn printBits(self: TrackingAllocator) void {
        printRow(
            "-",
            self.allocBytes * bitsInByte,
            "bits",
        );
    }

    pub fn printBytes(self: TrackingAllocator) void {
        printRow(
            "-",
            self.allocBytes,
            "bytes",
        );
    }
};

pub fn main(_: std.process.Init.Minimal) !void {
    const allocator = std.heap.page_allocator;
    var trackingAllocator = TrackingAllocator.init(allocator);

    printHeader();

    trackingAllocator.printBytes();

    const n = 250;
    const slice = try trackingAllocator.alloc(i16, n);

    // Put some data into the array
    for (slice, 0..) |*item, index| {
        item.* = @as(i16, @intCast(index)) * 2;
    }

    // Allocate some more memory
    _ = try trackingAllocator.alloc(i32, n);

    trackingAllocator.free(i16, slice);
    trackingAllocator.printBytes();

    // Allocate memory for a single integer
    const anInt = try trackingAllocator.create(i64);
    anInt.* = 42;

    _ = try trackingAllocator.create(i64);

    trackingAllocator.destroy(i64, anInt);

    trackingAllocator.printBytes();
    trackingAllocator.printBits();
}
