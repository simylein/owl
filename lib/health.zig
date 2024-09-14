const std = @import("std");
const database = @import("database.zig");
const logger = @import("logger.zig");
const utils = @import("utils.zig");

fn connect(address: std.net.Address) ?std.net.Stream {
    const stream = std.net.tcpConnectToAddress(address) catch |err| {
        logger.debug("could not connect to {} ({s})", .{ address, @errorName(err) });
        return null;
    };
    logger.debug("address {} is reachable", .{address});
    return stream;
}

fn log(app: *database.App) void {
    const formatted = utils.nanoseconds(app.latest.latency) catch "???ns";
    defer std.heap.c_allocator.free(formatted);
    switch (app.latest.healthyness) {
        0 => logger.warn("app {s} is unknown ({s})", .{ app.name, formatted }),
        1 => logger.warn("app {s} is unhealthy ({s})", .{ app.name, formatted }),
        2 => logger.warn("app {s} is unstable ({s})", .{ app.name, formatted }),
        3 => logger.info("app {s} is recovering ({s})", .{ app.name, formatted }),
        4 => logger.info("app {s} is healthy ({s})", .{ app.name, formatted }),
        else => return,
    }
}

pub fn check(data: *const database.Data, index: u8) void {
    std.time.sleep(std.time.ns_per_s);
    var app = &data.apps.items[index];

    while (true) {
        logger.trace("healthchecking {s}...", .{app.name});

        const start = std.time.nanoTimestamp();
        const stream = connect(app.address);
        if (stream) |socket| {
            defer socket.close();
        }
        const stop = std.time.nanoTimestamp();

        const timestamp: u64 = @intCast(@divFloor(start, 1000_000_000));
        const latency: u48 = @intCast(stop - start);
        const healthy = if (stream != null) true else false;

        app.latest.timestamp = timestamp;
        app.latest.latency = latency;

        const day = utils.bucket(timestamp, timestamp, std.time.s_per_day, 96);
        app.days[day].latency += latency;
        if (healthy) {
            app.days[day].healthy += 1;
            if (app.latest.healthyness == 0) {
                app.latest.healthyness = 4;
                log(app);
            }
            if (app.latest.healthyness < 4) {
                app.latest.healthyness += 1;
                log(app);
            }
        } else {
            app.days[day].unhealthy += 1;
            if (app.latest.healthyness > 1) {
                app.latest.healthyness -= 1;
                log(app);
            }
        }

        data.insert(.{ .app_id = index, .timestamp = timestamp, .latency = latency, .healthy = healthy }) catch |err| {
            logger.fault("failed to insert data for app {s} ({s})", .{ app.name, @errorName(err) });
        };

        const interval: u64 = @intCast(app.interval);
        if (latency > (interval * std.time.ns_per_s)) {
            continue;
        }

        std.time.sleep(interval * std.time.ns_per_s - latency);
    }
}
