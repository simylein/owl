const std = @import("std");
const logger = @import("logger.zig");

pub fn init() std.ArrayList([]const u8) {
    var args = std.ArrayList([]const u8).init(std.heap.c_allocator);
    var arguments = std.process.args();
    if (!arguments.skip()) {
        logger.panic("not enough arguments", .{});
        std.process.exit(1);
    }
    while (arguments.next()) |argument| {
        args.append(argument) catch |err| {
            logger.panic("could not allocate {d} bytes ({s})", .{ argument.len, @errorName(err) });
            std.process.exit(1);
        };
    }
    return args;
}
