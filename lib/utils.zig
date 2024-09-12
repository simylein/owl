const std = @import("std");

pub fn format(comptime fmt: []const u8, args: anytype) ![]u8 {
    return try std.fmt.allocPrint(std.heap.c_allocator, fmt, args);
}
