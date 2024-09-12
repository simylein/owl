const std = @import("std");
const logger = @import("logger.zig");

var mutex = std.Thread.Mutex{};

pub const Status = struct {
    app_id: u8,
    timestamp: u64,
    latency: u48,
    healthy: bool,
};

pub const Data = struct {
    path: []const u8,
    file: std.fs.File,
    statuses: std.ArrayList(Status),

    pub fn insert(self: *Data, status: Status) !void {
        mutex.lock();
        defer mutex.unlock();
        try self.statuses.append(status);
        var buffer: [16]u8 = undefined;
        std.mem.writeInt(u8, buffer[0..1], status.app_id, std.builtin.Endian.little);
        std.mem.writeInt(u64, buffer[1..9], status.timestamp, std.builtin.Endian.little);
        std.mem.writeInt(u48, buffer[9..15], status.latency, std.builtin.Endian.little);
        std.mem.writeInt(u8, buffer[15..16], if (status.healthy) 1 else 0, std.builtin.Endian.little);
        const bytes = try self.file.write(&buffer);
        logger.debug("wrote {d} bytes to {s}", .{ bytes, self.path });
    }

    pub fn deinit(self: *Data) void {
        self.statuses.deinit();
        self.file.close();
    }
};

pub fn init(comptime path: []const u8) Data {
    logger.trace("opening {s}...", .{path});
    const file = std.fs.cwd().openFile(path, .{ .mode = std.fs.File.OpenMode.read_write, .lock = std.fs.File.Lock.exclusive }) catch |err| {
        logger.panic("could not open {s} ({s})", .{ path, @errorName(err) });
        std.process.exit(1);
    };
    const stat = file.stat() catch |err| {
        logger.panic("could not stat {s} ({s})", .{ path, @errorName(err) });
        std.process.exit(1);
    };
    const buffer = std.heap.c_allocator.alloc(u8, stat.size) catch |err| {
        logger.panic("could not allocate {d} bytes ({s})", .{ stat.size, @errorName(err) });
        std.process.exit(1);
    };
    const read = file.read(buffer) catch |err| {
        logger.panic("could not read {s} file ({s})", .{ path, @errorName(err) });
        std.process.exit(1);
    };
    logger.debug("read {d} bytes from {s}", .{ read, path });

    logger.debug("parsing database...", .{});
    const content = buffer[0..read];
    var statuses = std.ArrayList(Status).init(std.heap.c_allocator);
    var index: u64 = 0;
    while (index < content.len) : (index += 16) {
        logger.trace("parsing status {d}...", .{index / 16});
        const slice = content[index .. index + 16];
        var status = Status{ .app_id = undefined, .timestamp = undefined, .latency = undefined, .healthy = undefined };

        status.app_id = std.mem.readInt(u8, slice[0..1], std.builtin.Endian.little);
        status.timestamp = std.mem.readInt(u64, slice[1..9], std.builtin.Endian.little);
        status.latency = std.mem.readInt(u48, slice[9..15], std.builtin.Endian.little);
        status.healthy = std.mem.readInt(u8, slice[15..16], std.builtin.Endian.little) == 1;

        statuses.append(status) catch |err| {
            logger.panic("could not allocate status for app {d} ({s})", .{ status.app_id, @errorName(err) });
            std.process.exit(1);
        };
    }

    logger.info("database holds {d} statuses", .{statuses.items.len});
    return Data{ .path = path, .file = file, .statuses = statuses };
}
