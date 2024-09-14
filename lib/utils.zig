const std = @import("std");

pub fn bucket(now: u64, timestamp: u64, timespan: u32, max: u7) u7 {
    const distance = now - (now % timespan) - (timestamp - (timestamp % timespan));
    const index: u7 = @intCast(if (distance < 0) 0 else distance / timespan);
    return max - index - 1;
}

pub fn format(comptime fmt: []const u8, args: anytype) ![]u8 {
    return try std.fmt.allocPrint(std.heap.c_allocator, fmt, args);
}

pub fn bytes(b: usize) ![]const u8 {
    const floating: f64 = @floatFromInt(b);
    if (b > 200_000_000) {
        return format("{d:.0}mb", .{floating / 1_000_000});
    } else if (b > 20_000_000) {
        return format("{d:.1}mb", .{floating / 1_000_000});
    } else if (b > 2_000_000) {
        return format("{d:.2}mb", .{floating / 1_000_000});
    } else if (b > 200_000) {
        return format("{d:.0}kb", .{floating / 1_000});
    } else if (b > 20_000) {
        return format("{d:.1}kb", .{floating / 1_000});
    } else if (b > 2_000) {
        return format("{d:.2}kb", .{floating / 1_000});
    } else {
        return format("{d:.0}b", .{floating});
    }
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
        return format("{d:.0}us", .{floating / 1_000});
    } else if (ns > 20_000) {
        return format("{d:.1}us", .{floating / 1_000});
    } else if (ns > 2_000) {
        return format("{d:.2}us", .{floating / 1_000});
    } else {
        return format("{d:.0}ns", .{floating});
    }
}

pub const Iterator = struct {
    input: []const u8,
    index: usize,

    pub fn init(input: []const u8) Iterator {
        return Iterator{ .input = input, .index = 0 };
    }

    pub fn next(self: *Iterator) ?u8 {
        if (self.index >= self.input.len) {
            return null;
        }
        const byte = self.input[self.index];
        self.index += 1;
        return byte;
    }

    pub fn slice(self: *Iterator, backwards: usize) ![]const u8 {
        if (self.index == 0 or self.index - 1 < backwards) {
            return error.OutOfBounds;
        }
        const index = self.index - 1;
        return self.input[index - backwards .. index];
    }
};
