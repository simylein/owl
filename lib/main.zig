const std = @import("std");
const config = @import("config.zig");
const logger = @import("logger.zig");

const host = "127.0.0.1";
const port = 4000;

pub fn main() void {
    const apps = config.init("owl.cfg");

    for (apps.items) |app| {
        logger.debug("spawning {s} healthcheck thread...", .{app.name});
        _ = std.Thread.spawn(.{ .allocator = std.heap.c_allocator }, healthcheck, .{&app}) catch |err| {
            logger.panic("could not spawn thread for app {s} ({s})", .{ app.name, @errorName(err) });
            std.process.exit(1);
        };
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

pub fn healthcheck(app: *const config.App) void {
    while (true) {
        logger.trace("app {s} healthcheck running...", .{app.name});
        const time: u64 = @intCast(app.interval);
        std.time.sleep(time * std.time.ns_per_s);
    }
}
