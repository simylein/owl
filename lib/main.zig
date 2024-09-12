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
        const buffer = handle(apps, data) catch |err| {
            logger.fault("could not handle client {} ({s})", .{ connection.address, @errorName(err) });
            continue;
        };
        defer buffer.deinit();
        const wrote = connection.stream.write(buffer.items) catch |err| {
            logger.fault("could not send {d} bytes client {} ({s})", .{ buffer.items.len, connection.address, @errorName(err) });
            continue;
        };
        logger.debug("wrote {d} bytes to {}", .{ wrote, connection.address });
    }
}

fn handle(apps: std.ArrayList(config.App), data: database.Data) !std.ArrayList(u8) {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    try buffer.appendSlice("HTTP/1.1 200 OK\r\n\r\n");
    for (apps.items) |app| {
        const slice = try std.fmt.allocPrint(std.heap.c_allocator, "id {d} name {s} interval {d}\n", .{ app.id, app.name, app.interval });
        defer std.heap.c_allocator.free(slice);
        try buffer.appendSlice(slice);
    }
    for (data.statuses.items) |status| {
        const slice = try std.fmt.allocPrint(std.heap.c_allocator, "app_id {d} timestamp {d} latency {d} healthy {}\n", .{ status.app_id, status.timestamp, status.latency, status.healthy });
        defer std.heap.c_allocator.free(slice);
        try buffer.appendSlice(slice);
    }

    return buffer;
}
