//! Linked List
//! A "chain" of nodes where each node has 2 properties: data, and a reference to the next node

// Requirements:
// Linked List must be generic
// function: append(value): void
//   add "value" to the end of the Linked List
// function: prepend(value): void
//   add "value" to the beginning of the Linked List
// function: remove(value): bool
//   remove a given value from the Linked List. Return "true" if the value was found, "false" otherwise
// function: popHead(): T
//   return and remove the head (first) node
// function: popTail(): T
//   return and remove the tail (last) node
// function: hasValue(value): bool
//   return "true" if the Linked List has "value". Otherwise return "false"
// function: display(): void
//   print a visual representation of the Linked List to console

// For all the functions above, feel free to modify the return types to account for error handling:
//  e.g. make the return type optional, or an error union

// Note: There is a [SinglyLinkedList](https://codeberg.org/ziglang/zig/src/branch/master/lib/std/SinglyLinkedList.zig)
//       in the standard library, if you want to check it out.

const std = @import("std");
const Allocator = std.mem.Allocator;
const print = std.debug.print;

pub fn LinkedList(comptime T: type) type {
    return struct {
        const Self = @This();

        pub const Node = struct {
            data: T,
            next: ?*Node,
        };

        allocator: Allocator,
        head: ?*Node = null,
        len: usize = 0,

        /// Initializes the linked list.
        pub fn init(allocator: Allocator) Self {
            return .{
                .allocator = allocator,
            };
        }

        /// Uninitializes the linked list.
        pub fn uninit(self: *Self) void {
            var current = self.head;
            while (current) |node| {
                const next = node.next;
                self.allocator.destroy(node);
                current = next;
            }
            self.head = null;
            self.len = 0;
        }

        /// Prints a visual representation of the Linked List to console.
        pub fn display(self: *Self) void {
            var first = true;
            var current = self.head;
            while (current) |node| {
                if (first) {
                    print("{}", .{node.data});
                    first = false;
                } else {
                    print(" -> {}", .{node.data});
                }
                current = node.next;
            }
            print("\n", .{});
        }

        /// Inserts a value at the end.
        /// Time complexity: `O(n)`.
        pub fn append(self: *Self, value: T) !void {
            const node = try self.allocator.create(Node);
            node.* = .{
                .data = value,
                .next = null,
            };

            if (self.head == null) {
                self.head = node;
            } else {
                var current = self.head.?;
                while (current.next) |next| {
                    current = next;
                }
                current.next = node;
            }
            self.len += 1;
        }

        /// Inserts a value at the beginning.
        /// Time complexity: `O(1)`.
        pub fn prepend(self: *Self, value: T) !void {
            const node = try self.allocator.create(Node);
            node.* = .{
                .data = value,
                .next = self.head,
            };
            self.head = node;
            self.len += 1;
        }

        /// Removes a given value from the Linked List. Return "true" if the value was found, "false" otherwise.
        pub fn remove(self: *Self, value: T) bool {
            var current = self.head;
            var prev: ?*Node = null;
            while (current) |node| {
                if (node.data == value) {
                    if (prev) |p| {
                        p.next = node.next;
                    } else {
                        self.head = node.next;
                    }
                    self.allocator.destroy(node);
                    self.len -= 1;
                    return true;
                }
                prev = node;
                current = node.next;
            }
            return false;
        }

        /// Returns and removes the first (head) node.
        /// Time complexity: `O(1)`.
        pub fn popHead(self: *Self) ?T {
            if (self.head) |node| {
                const value = node.data;
                self.head = node.next;
                self.len -= 1;
                return value;
            }
            return null;
        }

        /// Returns and removes the last (tail) node.
        /// Time complexity: `O(n)`.
        pub fn popTail(self: *Self) ?T {
            if (self.head == null) {
                return null;
            }
            if (self.len == 1) {
                const value = self.head.?.data;
                self.allocator.destroy(self.head.?);
                self.head = null;
                self.len = 0;
                return value;
            }
            var current = self.head;
            var prev: ?*Node = self.head;
            for (0..self.len) |i| {
                if (i == self.len - 1) {
                    const value = current.?.data;
                    self.allocator.destroy(current.?);
                    prev.?.next = null;
                    self.len -= 1;
                    return value;
                }
                prev = current;
                current = current.?.next;
            }
            return null;
        }

        /// Return "true" if the Linked List has "value". Otherwise return "false"
        pub fn hasValue(self: *Self, value: T) bool {
            var current = self.head;
            while (current) |node| {
                if (node.data == value) {
                    return true;
                }
                current = node.next;
            }
            return false;
        }
    };
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var numbers = LinkedList(i32).init(allocator);
    defer numbers.uninit();

    try numbers.append(1);
    try numbers.append(2);
    try numbers.append(3);
    try numbers.append(4);
    try numbers.append(5);
    numbers.display();

    if (numbers.popTail()) |value| {
        print("Popped last (tail) value: {d}\n", .{value});
    }
    numbers.display();

    if (numbers.remove(3)) {
        print("Removed value 3 from the list.\n", .{});
    }
    numbers.display();

    if (numbers.popHead()) |value| {
        print("Popped first (head) value: {d}\n", .{value});
    }
    numbers.display();

    if (numbers.hasValue(2)) {
        print("Found value 2 in the list.\n", .{});
    }
}
