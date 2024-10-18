const std = @import("std");
const config = @import("config.zig");
const database = @import("database.zig");
const logger = @import("logger.zig");
const health = @import("health.zig");
const render = @import("render.zig");
const request = @import("request.zig");
const response = @import("response.zig");

pub fn main() void {
    var args = std.process.args();
    config.init(&args);

    const data = database.init(config.config_path, config.database_path);
    var index: u8 = 0;
    while (index < data.apps.items.len) : (index += 1) {
        logger.debug("spawning {s} healthcheck thread...", .{data.apps.items[index].name});
        const thread = std.Thread.spawn(.{ .allocator = std.heap.c_allocator }, health.check, .{ &data, index }) catch |err| {
            logger.panic("failed to spawn thread ({s})", .{@errorName(err)});
            std.process.exit(1);
        };
        defer thread.detach();
    }

    logger.info("starting http server...", .{});

    const address = std.net.Address.resolveIp(config.address, config.port) catch |err| {
        logger.panic("failed to resolve address {s}:{d} ({s})", .{ config.address, config.port, @errorName(err) });
        std.process.exit(1);
    };
    var server = address.listen(.{ .kernel_backlog = 256, .reuse_address = true }) catch |err| {
        logger.panic("failed to listen on {} ({s})", .{ address, @errorName(err) });
        std.process.exit(1);
    };

    logger.info("listening on {}", .{server.listen_address});

    while (true) {
        const connection = server.accept() catch |err| {
            logger.fault("failed to accept client ({s})", .{@errorName(err)});
            continue;
        };
        logger.trace("accepted connection from {}", .{connection.address});
        defer {
            logger.trace("closed connection to {}", .{connection.address});
            connection.stream.close();
        }

        logger.debug("parsing request...", .{});
        const start = std.time.nanoTimestamp();
        const req = request.parse(&connection) catch |err| {
            logger.fault("failed to parse request ({s})", .{@errorName(err)});
            continue;
        };
        defer req.deinit();

        logger.request(req.method, req.pathname, connection.address);

        const res = handle(&req, &data) catch |err| {
            logger.fault("failed to handle client {} ({s})", .{ connection.address, @errorName(err) });
            continue;
        };
        defer res.deinit();

        const stop = std.time.nanoTimestamp();
        const time: u48 = @intCast(stop - start);

        logger.response(res.status, time, res.buffer.len);

        const wrote = connection.stream.write(res.buffer) catch |err| {
            logger.fault("failed to send {d} bytes client {} ({s})", .{ res.buffer.len, connection.address, @errorName(err) });
            continue;
        };
        logger.debug("wrote {d} bytes to {}", .{ wrote, connection.address });
    }
}

fn handle(req: *const request.Request, data: *const database.Data) !response.Response {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    logger.trace("rendering body...", .{});
    const body = try route(req, data);
    defer body.deinit();

    logger.trace("rendering head...", .{});
    const head = try render.head(body.status, body.content, body.buffer.len);
    defer std.heap.c_allocator.free(head);

    try buffer.appendSlice(head);
    try buffer.appendSlice(body.buffer);

    return .{ .buffer = try buffer.toOwnedSlice(), .status = body.status, .content = body.content };
}

fn route(req: *const request.Request, data: *const database.Data) !response.Response {
    logger.trace("routing request...", .{});
    if (std.mem.eql(u8, req.pathname, "/")) {
        return .{ .buffer = try render.home(data), .status = 200, .content = "text/html" };
    } else if (std.mem.eql(u8, req.pathname, "/robots.txt")) {
        return .{ .buffer = try render.robots(), .status = 200, .content = "text/plain" };
    } else {
        return .{ .buffer = try render.notFound(), .status = 404, .content = "text/html" };
    }
}
