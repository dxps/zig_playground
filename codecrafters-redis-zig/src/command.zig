const std = @import("std");
const log = @import("log.zig").log;

pub const Command = struct {
    /// The name of the command.
    name: CommandName,
    /// The number of data lines in the command.
    payload_size: u8,
    /// The data of the command.
    payload: [][]const u8,

    pub fn parse(input: []u8) !Command {

        // First, we split the input into lines.
        var input_iter = std.mem.splitSequence(u8, input, "\r\n");
        const first_line = input_iter.next().?;

        var payload = std.ArrayList([]const u8).init(std.heap.page_allocator);

        if (std.mem.eql(u8, first_line, "*1\r\n$4\r\nPING\r\n")) {
            return Command{
                .name = CommandName.PING,
                .payload_size = 0,
                .payload = payload.items,
            };
        }

        if (std.mem.startsWith(u8, first_line, "*")) { // It's an array.

            const payload_size = try std.fmt.parseUnsigned(u8, first_line[1..], 10) - 1; // Ignore the first "data line" that is the command name.
            _ = input_iter.next(); // Skip the length line (that "${number}" line).
            const name = input_iter.next().?;
            const case = std.meta.stringToEnum(CommandName, name) orelse return error.InvalidCommand;

            switch (case) {
                .PING => return Command{
                    .name = CommandName.PING,
                    .payload_size = 0,
                    .payload = payload.items,
                },
                .ECHO => {
                    _ = input_iter.next();
                    const item = input_iter.next().?;
                    try payload.append(item);
                    return Command{
                        .name = .ECHO,
                        .payload_size = payload_size,
                        .payload = payload.items,
                    };
                },
                .SET => {
                    _ = input_iter.next();
                    const key = input_iter.next().?;
                    _ = input_iter.next();
                    const value = input_iter.next().?;
                    try payload.append(key);
                    try payload.append(value);
                    if (payload_size == 4) {
                        _ = input_iter.next(); // Skip the (next line's) size line.
                        try payload.append(input_iter.next().?); // This should be "px".
                        _ = input_iter.next(); // Skip the (next line's) size line.
                        try payload.append(input_iter.next().?); // This should be the expiration time.
                    }
                    return Command{
                        .name = .SET,
                        .payload_size = payload_size,
                        .payload = payload.items,
                    };
                },
                .GET => {
                    _ = input_iter.next();
                    const key = input_iter.next().?;
                    try payload.append(key);
                    return Command{
                        .name = .GET,
                        .payload_size = payload_size,
                        .payload = payload.items,
                    };
                },
                .CONFIG => {
                    _ = input_iter.next();
                    try payload.append(input_iter.next().?); // This should be "GET".
                    _ = input_iter.next(); // Skip the (next line's) size line.
                    try payload.append(input_iter.next().?); // This should be the parameter (such as dir or dbfilename).
                    return Command{
                        .name = .CONFIG,
                        .payload_size = payload_size,
                        .payload = payload.items,
                    };
                },
            }
        }

        return error.InvalidCommand;
    }
};

pub const CommandName = enum {
    PING,
    ECHO,
    SET,
    GET,
    CONFIG,
};
