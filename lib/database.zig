const std = @import("std");
const logger = @import("logger.zig");

const App = struct {
    id: u8,
    name: []const u8,

    pub fn binary(self: *App) ![]u8 {
        return try std.mem.concat(std.heap.c_allocator, u8, &[_][]const u8{ &[_]u8{self.id}, self.name, "\x00", "\n" });
    }

    pub fn deinit(self: *App) void {
        std.heap.c_allocator.free(self.name);
    }
};

const Database = struct {
    path: []const u8,
    file: std.fs.File,
    apps: std.ArrayList(App),

    pub fn insert(self: *Database, app: App) !void {
        try self.apps.append(app);
        logger.trace("added application {s}", .{app.name});
        const buffer = try std.mem.concat(std.heap.c_allocator, u8, &[_][]const u8{ &[_]u8{app.id}, app.name, "\x00", "\n" });
        defer std.heap.c_allocator.free(buffer);
        const bytes = try self.file.write(buffer);
        logger.debug("wrote {d} bytes to {s}", .{ bytes, self.path });
    }

    pub fn delete(self: *Database, id: u8) !void {
        const app = self.apps.orderedRemove(id);
        logger.trace("removed application {s}", .{app.name});
        var buffer = std.ArrayList(u8).init(std.heap.c_allocator);
        defer buffer.deinit();
        var index: u8 = 0;
        while (index < self.apps.items.len) : (index += 1) {
            const bytes = try self.apps.items[index].binary();
            try buffer.appendSlice(bytes);
        }
        try self.file.seekTo(0);
        const wrote = try self.file.write(buffer.items);
        logger.debug("wrote {d} bytes to {s}", .{ wrote, self.path });
    }

    pub fn deinit(self: *Database) void {
        var index: u8 = 0;
        while (index < self.apps.items.len) : (index += 1) {
            self.apps.items[index].deinit();
        }
        self.apps.deinit();
        self.file.close();
    }
};

pub fn init(comptime path: []const u8) Database {
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
    const content = buffer[0..read];
    var apps = std.ArrayList(App).init(std.heap.c_allocator);
    var index: u8 = 0;
    var tokenizer = std.mem.tokenize(u8, content, "\n");
    while (tokenizer.next()) |bytes| : (index += 1) {
        var ind: u8 = 0;
        var stage: u2 = 0;
        var id: u8 = undefined;
        var name_buffer: [16]u8 = undefined;
        var name_length: u5 = 0;
        while (ind < bytes.len) : (ind += 1) {
            const byte = bytes[ind];
            switch (stage) {
                0 => {
                    id = byte;
                    stage = 1;
                },
                1 => {
                    if (byte == 0) {
                        stage = 2;
                    } else {
                        name_buffer[name_length] = byte;
                        name_length += 1;
                    }
                },
                else => break,
            }
        }
        const name = std.heap.c_allocator.alloc(u8, name_length) catch |err| {
            logger.panic("could not allocate {d} bytes ({s})", .{ name_length, @errorName(err) });
            std.process.exit(1);
        };
        std.mem.copyForwards(u8, name, name_buffer[0..name_length]);
        apps.append(.{ .id = id, .name = name }) catch |err| {
            logger.fault("could not allocate application {d} ({s})", .{ index, @errorName(err) });
        };
    }
    return Database{ .path = path, .file = file, .apps = apps };
}
