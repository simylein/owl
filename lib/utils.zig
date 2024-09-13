const std = @import("std");

pub fn format(comptime fmt: []const u8, args: anytype) ![]u8 {
    return try std.fmt.allocPrint(std.heap.c_allocator, fmt, args);
}

pub fn nanoseconds(ns: u64) ![]const u8 {
    if (ns > 2_000_000_000) {
        return format("{d}s", .{ns / 1_000_000_000});
    } else if (ns > 2_000_000) {
        return format("{d}ms", .{ns / 1_000_000});
    } else if (ns > 2_000) {
        return format("{d}µs", .{ns / 1_000});
    } else {
        return format("{d}ns", .{ns});
    }
}
