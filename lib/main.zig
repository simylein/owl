const std = @import("std");
const arguments = @import("arguments.zig");
const config = @import("config.zig");
const database = @import("database.zig");
const health = @import("health.zig");
const logger = @import("logger.zig");
const render = @import("render.zig");
const uptime = @import("uptime.zig");
const utils = @import("utils.zig");

pub fn main() void {
    arguments.init();
    var apps = config.init("owl.cfg");
    var data = database.init("owl.bin");

    var index: u7 = 0;
    while (index < apps.items.len) : (index += 1) {
        logger.debug("spawning {s} healthcheck thread...", .{apps.items[index].name});
        const thread = std.Thread.spawn(.{ .allocator = std.heap.c_allocator }, health.check, .{ &apps.items[index], &data }) catch |err| {
            logger.panic("could not spawn thread for app {s} ({s})", .{ apps.items[index].name, @errorName(err) });
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
        logger.debug("rendering uptime...", .{});
        const start = std.time.nanoTimestamp();
        const buffer = handle(apps, &data) catch |err| {
            logger.fault("could not handle client {} ({s})", .{ connection.address, @errorName(err) });
            continue;
        };
        const stop = std.time.nanoTimestamp();
        const duration: u48 = @intCast(stop - start);
        const formatted = utils.nanoseconds(duration) catch "???ns";
        defer std.heap.c_allocator.free(formatted);
        logger.info("rendered uptime in {s}", .{formatted});
        defer std.heap.c_allocator.free(buffer);
        const wrote = connection.stream.write(buffer) catch |err| {
            logger.fault("could not send {d} bytes client {} ({s})", .{ buffer.len, connection.address, @errorName(err) });
            continue;
        };
        logger.debug("wrote {d} bytes to {}", .{ wrote, connection.address });
    }
}

fn handle(apps: std.ArrayList(config.App), data: *database.Data) ![]u8 {
    logger.trace("calculating uptimes...", .{});
    var uptimes = try uptime.calculate(apps, data);
    defer uptimes.deinit();

    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    logger.trace("rendering body...", .{});
    const body = try render.body(&uptimes);
    defer std.heap.c_allocator.free(body);

    logger.trace("rendering head...", .{});
    const head = try render.head(body.len);
    defer std.heap.c_allocator.free(head);

    try buffer.appendSlice(head);
    try buffer.appendSlice(body);

    return buffer.toOwnedSlice();
}
