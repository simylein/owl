const std = @import("std");
const logger = @import("logger.zig");

pub const App = struct {
    id: u8,
    name: []u8,
    address: std.net.Address,
    interval: u8,
    latest: Latest,
};

pub const Latest = struct {
    timestamp: u64,
    healthyness: u8,
};

pub fn init(comptime path: []const u8) std.ArrayList(App) {
    logger.trace("opening {s}...", .{path});
    const file = std.fs.cwd().openFile(path, .{ .mode = std.fs.File.OpenMode.read_only, .lock = std.fs.File.Lock.exclusive }) catch |err| {
        logger.panic("could not open {s} ({s})", .{ path, @errorName(err) });
        std.process.exit(1);
    };
    defer file.close();
    const stat = file.stat() catch |err| {
        logger.panic("could not stat {s} ({s})", .{ path, @errorName(err) });
        std.process.exit(1);
    };
    const buffer = std.heap.c_allocator.alloc(u8, stat.size) catch |err| {
        logger.panic("could not allocate {d} bytes ({s})", .{ stat.size, @errorName(err) });
        std.process.exit(1);
    };
    defer std.heap.c_allocator.free(buffer);
    const read = file.read(buffer) catch |err| {
        logger.panic("could not read {s} file ({s})", .{ path, @errorName(err) });
        std.process.exit(1);
    };
    logger.debug("read {d} bytes from {s}", .{ read, path });

    logger.debug("parsing config...", .{});
    const content = buffer[0..read];
    var apps = std.ArrayList(App).init(std.heap.c_allocator);
    var index: u8 = 0;
    var tokenizer = std.mem.tokenize(u8, content, "\n");
    while (tokenizer.next()) |line| : (index += 1) {
        logger.trace("parsing app {d}...", .{index});
        var app = App{ .id = undefined, .name = undefined, .address = undefined, .interval = undefined, .latest = Latest{ .timestamp = 0, .healthyness = 0 } };
        var token = std.mem.tokenize(u8, line, " ");

        if (apps.items.len >= 255) {
            logger.fault("config can only hold a max of 255 apps", .{});
            std.process.exit(1);
        }
        const id: u8 = @intCast(apps.items.len);
        const name = if (token.next()) |name| name else {
            logger.fault("app {d} must have a name", .{index});
            std.process.exit(1);
        };
        const host = if (token.next()) |host| host else {
            logger.fault("app {d} must have a host", .{index});
            std.process.exit(1);
        };
        const port = if (token.next()) |port| port else {
            logger.fault("app {d} must have a port", .{index});
            std.process.exit(1);
        };
        const interval = if (token.next()) |interval| interval else {
            logger.fault("app {d} must have an interval", .{index});
            std.process.exit(1);
        };

        app.id = id;
        if (name.len < 2 or name.len > 16) {
            logger.fault("app {d} name must be between 2 and 16 characters", .{index});
            std.process.exit(1);
        }
        for (name) |char| {
            if ((char < 97 or char > 122) and char != 45) {
                logger.fault("app {d} name must contain lowercase letters or hyphons", .{index});
                std.process.exit(1);
            }
        }
        app.name = std.heap.c_allocator.alloc(u8, name.len) catch |err| {
            logger.panic("could not allocate {d} bytes ({s})", .{ name.len, @errorName(err) });
            std.process.exit(1);
        };
        std.mem.copyForwards(u8, app.name, name);
        app.address = std.net.Address.resolveIp(host, std.fmt.parseInt(u16, port, 10) catch {
            logger.fault("app {d} port must be between 0 and 65535", .{index});
            std.process.exit(1);
        }) catch |err| {
            logger.fault("app {d} address must be valid ({s})", .{ index, @errorName(err) });
            std.process.exit(1);
        };
        app.interval = std.fmt.parseInt(u8, interval, 10) catch {
            logger.fault("app {d} interval must be between 0 and 255", .{index});
            std.process.exit(1);
        };

        apps.append(app) catch |err| {
            logger.panic("could not allocate app {s} ({s})", .{ app.name, @errorName(err) });
            std.process.exit(1);
        };
    }

    logger.info("config holds {d} apps", .{apps.items.len});
    return apps;
}
