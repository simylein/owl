const std = @import("std");
const arguments = @import("arguments.zig");
const config = @import("config.zig");
const database = @import("database.zig");
const health = @import("health.zig");
const logger = @import("logger.zig");

pub fn main() void {
    arguments.init();
    const apps = config.init("owl.cfg");
    var data = database.init("owl.bin");

    for (apps.items) |app| {
        logger.debug("spawning {s} healthcheck thread...", .{app.name});
        const thread = std.Thread.spawn(.{ .allocator = std.heap.c_allocator }, health.check, .{ app, &data }) catch |err| {
            logger.panic("could not spawn thread for app {s} ({s})", .{ app.name, @errorName(err) });
            std.process.exit(1);
        };
        defer thread.detach();
    }

    logger.info("starting http server...", .{});

    const address = std.net.Address.resolveIp(arguments.host, arguments.port) catch |err| {
        logger.panic("could not resolve address {s}:{d} ({s})", .{ arguments.host, arguments.port, @errorName(err) });
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
        logger.trace("accepted connection from {}", .{connection.address});
        defer {
            logger.trace("closed connection to {}", .{connection.address});
            connection.stream.close();
        }
    }
}
