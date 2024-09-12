const std = @import("std");
const arguments = @import("arguments.zig");
const config = @import("config.zig");
const database = @import("database.zig");
const logger = @import("logger.zig");

fn connect(address: std.net.Address) ?std.net.Stream {
    const stream = std.net.tcpConnectToAddress(address) catch |err| {
        logger.debug("could not connect to {} ({s})", .{ address, @errorName(err) });
        return null;
    };
    return stream;
}

fn format(nanoseconds: u64) ![]const u8 {
    if (nanoseconds > 2_000_000_000) {
        return std.fmt.allocPrint(std.heap.c_allocator, "{d}s", .{nanoseconds / 1_000_000_000});
    } else if (nanoseconds > 2_000_000) {
        return std.fmt.allocPrint(std.heap.c_allocator, "{d}ms", .{nanoseconds / 1_000_000});
    } else if (nanoseconds > 2_000) {
        return std.fmt.allocPrint(std.heap.c_allocator, "{d}µs", .{nanoseconds / 1_000});
    } else {
        return std.fmt.allocPrint(std.heap.c_allocator, "{d}ns", .{nanoseconds});
    }
}

pub fn check(app: config.App, data: *database.Data) void {
    std.time.sleep(std.time.ns_per_s);

    while (true) {
        logger.trace("healthchecking {s}...", .{app.name});
        const start = std.time.nanoTimestamp();
        const stream = connect(app.address);
        if (stream) |socket| {
            defer socket.close();
        }
        const stop = std.time.nanoTimestamp();

        const timestamp: u64 = @intCast(@divFloor(start, 1000_000_000));
        const latency: u32 = @intCast(stop - start);
        const healthy = if (stream != null) true else false;

        const formatted = format(latency) catch "???ns";
        defer std.heap.c_allocator.free(formatted);
        if (healthy) {
            logger.info("app {s} is healthy ({s})", .{ app.name, formatted });
        } else {
            logger.warn("app {s} is unhealthy ({s})", .{ app.name, formatted });
        }

        data.insert(.{ .app_id = app.id, .timestamp = timestamp, .latency = latency, .healthy = healthy }) catch |err| {
            logger.fault("could not insert data for app {s} ({s})", .{ app.name, @errorName(err) });
        };

        const interval: u64 = @intCast(app.interval);
        const wait = interval * std.time.ns_per_s - latency;

        if (wait > 0) {
            std.time.sleep(wait);
        }
    }
}
