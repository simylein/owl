const std = @import("std");
const config = @import("config.zig");
const database = @import("database.zig");
const logger = @import("logger.zig");

const host = "127.0.0.1";
const port = 4000;

pub fn main() void {
    var args = std.process.args();

    if (!args.skip()) {
        logger.panic("the zeroth argument is empty", .{});
        std.process.exit(1);
    }
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--log-level")) {
            if (args.next()) |log_level| {
                if (std.mem.eql(u8, log_level, "trace")) {
                    config.log_level = 6;
                } else if (std.mem.eql(u8, log_level, "debug")) {
                    config.log_level = 5;
                } else if (std.mem.eql(u8, log_level, "info")) {
                    config.log_level = 4;
                } else if (std.mem.eql(u8, log_level, "warn")) {
                    config.log_level = 3;
                } else if (std.mem.eql(u8, log_level, "fault")) {
                    config.log_level = 2;
                } else if (std.mem.eql(u8, log_level, "panic")) {
                    config.log_level = 1;
                } else {
                    logger.fault("log level must be one of trace debug info warn error panic", .{});
                    std.process.exit(1);
                }
            } else {
                logger.fault("log level must be one of trace debug info warn error panic", .{});
                std.process.exit(1);
            }
        }
    }

    const apps = config.init("owl.cfg");
    var data = database.init("owl.db");

    for (apps.items) |app| {
        logger.debug("spawning {s} healthcheck thread...", .{app.name});
        const thread = std.Thread.spawn(.{ .allocator = std.heap.c_allocator }, healthcheck, .{ app, &data }) catch |err| {
            logger.panic("could not spawn thread for app {s} ({s})", .{ app.name, @errorName(err) });
            std.process.exit(1);
        };
        defer thread.detach();
    }

    logger.info("starting http server...", .{});

    const address = std.net.Address.resolveIp(host, port) catch |err| {
        logger.panic("could not resolve address {s}:{d} ({s})", .{ host, port, @errorName(err) });
        std.process.exit(1);
    };
    var server = address.listen(.{ .kernel_backlog = 256, .reuse_address = true }) catch |err| {
        logger.panic("could not listen on {} ({s})", .{ address, @errorName(err) });
        std.process.exit(1);
    };

    logger.info("listening on {}", .{server.listen_address});

    while (true) {
        const connection = server.accept() catch |err| {
            logger.fault("could not accept client ({s})", .{@errorName(err)});
            continue;
        };
        logger.debug("connection from {}", .{connection.address});
    }
}

pub fn healthcheck(app: config.App, data: *database.Data) void {
    while (true) {
        logger.trace("healthchecking {s}...", .{app.name});
        const start = std.time.nanoTimestamp();

        const stop = std.time.nanoTimestamp();

        const app_id: u8 = 0;
        const timestamp: u64 = @intCast(@divFloor(start, 1000_000_000));
        const latency: u32 = @intCast(stop - start);
        const healthy: bool = true;

        data.insert(.{ .app_id = app_id, .timestamp = timestamp, .latency = latency, .healthy = healthy }) catch |err| {
            logger.fault("could not insert data for app {s} ({s})", .{ app.name, @errorName(err) });
        };

        const interval: u64 = @intCast(app.interval);
        const wait = interval * std.time.ns_per_s - latency;

        if (wait > 0) {
            std.time.sleep(wait);
        }
    }
}
