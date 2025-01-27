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

            const payload_size = try std.fmt.parseUnsigned(u8, first_line[1..], 10);
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
                        .payload_size = payload_size, // Skip the first item, which is the command name.
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
};
