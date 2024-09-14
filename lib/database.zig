const std = @import("std");
const config = @import("config.zig");
const logger = @import("logger.zig");
const utils = @import("utils.zig");

var mutex = std.Thread.Mutex{};

pub const Day = struct {
    timestamp: u64,
    latency: u64,
    healthy: u16,
    unhealthy: u16,
};

pub const App = struct {
    id: u8,
    name: []u8,
    address: std.net.Address,
    interval: u8,
    latest: Latest,
    days: [96]Day,

    pub fn shift(self: *App) void {
        var index: u7 = 0;
        while (index < self.days.len - 1) : (index += 1) {
            self.days[index] = self.days[index + 1];
        }
        self.days[self.days.len - 1] = Day{ .timestamp = std.math.maxInt(u64), .latency = 0, .healthy = 0, .unhealthy = 0 };
    }
};

pub const Latest = struct {
    timestamp: u64,
    latency: u48,
    healthyness: u8,
};

pub const Status = struct {
    app_id: u8,
    timestamp: u64,
    latency: u48,
    healthy: bool,
};

pub const Data = struct {
    config: std.fs.File,
    database: std.fs.File,
    apps: std.ArrayList(App),

    pub fn insert(self: *const Data, status: Status) !void {
        mutex.lock();
        defer mutex.unlock();
        var buffer: [16]u8 = undefined;
        std.mem.writeInt(u8, buffer[0..1], status.app_id, std.builtin.Endian.little);
        std.mem.writeInt(u64, buffer[1..9], status.timestamp, std.builtin.Endian.little);
        std.mem.writeInt(u48, buffer[9..15], status.latency, std.builtin.Endian.little);
        std.mem.writeInt(u8, buffer[15..16], if (status.healthy) 1 else 0, std.builtin.Endian.little);
        const bytes = try self.database.write(&buffer);
        logger.debug("wrote {d} bytes to database", .{bytes});
    }
};

fn parseConfig(comptime path: []const u8, data: *Data) std.fs.File {
    logger.trace("opening {s}...", .{path});
    const file = std.fs.cwd().openFile(path, .{ .mode = std.fs.File.OpenMode.read_only, .lock = std.fs.File.Lock.exclusive }) catch |err| {
        logger.panic("failed to open {s} ({s})", .{ path, @errorName(err) });
        std.process.exit(1);
    };
    defer file.close();
    const stat = file.stat() catch |err| {
        logger.panic("failed to stat {s} ({s})", .{ path, @errorName(err) });
        std.process.exit(1);
    };
    const buffer = std.heap.c_allocator.alloc(u8, stat.size) catch |err| {
        logger.panic("failed to allocate {d} bytes ({s})", .{ stat.size, @errorName(err) });
        std.process.exit(1);
    };
    defer std.heap.c_allocator.free(buffer);
    const read = file.read(buffer) catch |err| {
        logger.panic("failed to read {s} file ({s})", .{ path, @errorName(err) });
        std.process.exit(1);
    };
    const bytes = utils.bytes(read) catch "???b";
    defer std.heap.c_allocator.free(bytes);
    logger.debug("read {s} from {s}", .{ bytes, path });

    logger.debug("parsing config...", .{});
    const content = buffer[0..read];
    var index: u8 = 0;
    var tokenizer = std.mem.tokenize(u8, content, "\n");
    while (tokenizer.next()) |line| : (index += 1) {
        logger.trace("parsing app {d}...", .{index});
        var app = App{ .id = undefined, .name = undefined, .address = undefined, .interval = undefined, .latest = undefined, .days = undefined };
        var ind: u7 = 0;
        while (ind < app.days.len) : (ind += 1) {
            app.days[ind] = Day{ .timestamp = std.math.maxInt(u64), .latency = 0, .healthy = 0, .unhealthy = 0 };
        }
        app.latest = Latest{ .timestamp = 0, .latency = 0, .healthyness = 0 };

        var token = std.mem.tokenize(u8, line, " ");

        if (data.apps.items.len >= 255) {
            logger.fault("config can only hold a max of 255 apps", .{});
            std.process.exit(1);
        }
        const id: u8 = @intCast(data.apps.items.len);
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
            logger.panic("failed to allocate {d} bytes ({s})", .{ name.len, @errorName(err) });
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

        data.apps.append(app) catch |err| {
            logger.panic("failed to allocate app {s} ({s})", .{ app.name, @errorName(err) });
            std.process.exit(1);
        };
    }

    logger.info("config holds {d} apps", .{data.apps.items.len});
    return file;
}

fn parseDatabase(comptime path: []const u8, data: *Data) std.fs.File {
    logger.trace("opening {s}...", .{path});
    const file = std.fs.cwd().openFile(path, .{ .mode = std.fs.File.OpenMode.read_write, .lock = std.fs.File.Lock.exclusive }) catch |err| {
        logger.panic("failed to open {s} ({s})", .{ path, @errorName(err) });
        std.process.exit(1);
    };
    const stat = file.stat() catch |err| {
        logger.panic("failed to stat {s} ({s})", .{ path, @errorName(err) });
        std.process.exit(1);
    };
    const buffer = std.heap.c_allocator.alloc(u8, stat.size) catch |err| {
        logger.panic("failed to allocate {d} bytes ({s})", .{ stat.size, @errorName(err) });
        std.process.exit(1);
    };
    defer std.heap.c_allocator.free(buffer);
    const read = file.read(buffer) catch |err| {
        logger.panic("failed to read {s} file ({s})", .{ path, @errorName(err) });
        std.process.exit(1);
    };
    const bytes = utils.bytes(read) catch "???b";
    defer std.heap.c_allocator.free(bytes);
    logger.debug("read {s} from {s}", .{ bytes, path });

    logger.debug("parsing database...", .{});
    const content = buffer[0..read];
    var index: u64 = 0;
    while (index < content.len) : (index += 16) {
        logger.trace("parsing status {d}...", .{index / 16});
        const slice = content[index .. index + 16];

        const app_id = std.mem.readInt(u8, slice[0..1], std.builtin.Endian.little);
        const timestamp = std.mem.readInt(u64, slice[1..9], std.builtin.Endian.little);
        const latency = std.mem.readInt(u48, slice[9..15], std.builtin.Endian.little);
        const healthy = std.mem.readInt(u8, slice[15..16], std.builtin.Endian.little) == 1;

        const now: u64 = @intCast(std.time.timestamp());
        if (now - timestamp > config.bucket_size * 96) {
            continue;
        }

        if (app_id >= data.apps.items.len) {
            logger.warn("no app for status {d} with app id {d}", .{ index / 16, app_id });
            continue;
        }

        const day: u8 = utils.bucket(now, timestamp, config.bucket_size, 96);
        if (data.apps.items[app_id].days[day].timestamp > timestamp) {
            data.apps.items[app_id].days[day].timestamp = timestamp;
            data.apps.items[app_id].days[day].timestamp += latency;
        }
        if (healthy) {
            data.apps.items[app_id].days[day].healthy += 1;
        } else {
            data.apps.items[app_id].days[day].unhealthy += 1;
        }
    }

    logger.info("database holds {d} statuses", .{index / 16});
    return file;
}

pub fn init(comptime config_path: []const u8, comptime database_path: []const u8) Data {
    const apps = std.ArrayList(App).init(std.heap.c_allocator);
    var data = Data{ .config = undefined, .database = undefined, .apps = apps };

    data.config = parseConfig(config_path, &data);
    data.database = parseDatabase(database_path, &data);

    return data;
}
