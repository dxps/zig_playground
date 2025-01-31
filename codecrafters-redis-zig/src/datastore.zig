const std = @import("std");
const Allocator = std.mem.Allocator;
const log = @import("log.zig").log;

pub const Store = struct {
    /// The directory of the store file.
    dir: []const u8,

    /// The filename where the store is persisted.
    dbfilename: []const u8,

    /// The store as a map of key-value pairs.
    kvs: std.StringHashMap([]const u8),

    /// The store's access mutex.
    kvs_mutex: std.Thread.Mutex,

    /// A store of keys that expires at a certain time (stored as milliseconds since UTC).
    keys_expirations: std.StringHashMap(i64),

    pub fn init(a: Allocator, dir: []const u8, dbfilename: []const u8) Store {
        return Store{
            .dir = dir,
            .dbfilename = dbfilename,
            .kvs = std.StringHashMap([]const u8).init(a),
            .kvs_mutex = std.Thread.Mutex{},
            .keys_expirations = std.StringHashMap(i64).init(a),
        };
    }

    pub fn deinit(self: *Store) void {
        self.kvs.deinit();
        self.keys_expirations.deinit();
    }

    pub fn get(self: *Store, key: []const u8) ?[]const u8 {
        self.kvs_mutex.lock();
        defer self.kvs_mutex.unlock();

        const expires = if (self.keys_expirations.get(key)) |val| val else 0;
        log("Key '{s}' expires at {d} and now is {d}.\n", .{ key, expires, std.time.milliTimestamp() });
        if (expires > 0) {
            const now = std.time.milliTimestamp();
            if (now > expires) {
                log("Key '{s}' expired.\n", .{key});
                _ = self.keys_expirations.remove(key);
                _ = self.kvs.remove(key);
                return null;
            }
        }
        return self.kvs.get(key);
    }

    /// Put a key-value pair into the store. For keys that don't expire, `expires` must be 0.
    pub fn put(self: *Store, key: []const u8, value: []const u8, expires: i64) !void {
        self.kvs_mutex.lock();
        defer self.kvs_mutex.unlock();

        if (expires > 0) {
            try self.keys_expirations.put(key, expires + std.time.milliTimestamp());
        }
        try self.kvs.put(key, value);
    }
};
