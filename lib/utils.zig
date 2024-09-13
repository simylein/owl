const std = @import("std");

pub fn format(comptime fmt: []const u8, args: anytype) ![]u8 {
    return try std.fmt.allocPrint(std.heap.c_allocator, fmt, args);
}

pub fn nanoseconds(ns: u64) ![]const u8 {
    const floating: f64 = @floatFromInt(ns);
    if (ns > 200_000_000_000) {
        return format("{d:.0}s", .{floating / 1_000_000_000});
    } else if (ns > 20_000_000_000) {
        return format("{d:.1}s", .{floating / 1_000_000_000});
    } else if (ns > 2_000_000_000) {
        return format("{d:.2}s", .{floating / 1_000_000_000});
    } else if (ns > 200_000_000) {
        return format("{d:.0}ms", .{floating / 1_000_000});
    } else if (ns > 20_000_000) {
        return format("{d:.1}ms", .{floating / 1_000_000});
    } else if (ns > 2_000_000) {
        return format("{d:.2}ms", .{floating / 1_000_000});
    } else if (ns > 200_000) {
        return format("{d:.0}µs", .{floating / 1_000});
    } else if (ns > 20_000) {
        return format("{d:.1}µs", .{floating / 1_000});
    } else if (ns > 2_000) {
        return format("{d:.2}µs", .{floating / 1_000});
    } else {
        return format("{d:.0}ns", .{floating});
    }
}
