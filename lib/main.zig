const std = @import("std");
const arguments = @import("arguments.zig");
const database = @import("database.zig");
const logger = @import("logger.zig");

const path = "owl.db";

pub fn main() void {
    var args = arguments.init();
    defer args.deinit();

    if (args.items.len < 1) {
        logger.warn("not enough arguments", .{});
        logger.info("available options", .{});
        logger.info("init", .{});
        logger.info("list", .{});
        logger.info("add name", .{});
        logger.info("remove name", .{});
        std.process.exit(1);
    }

    if (std.mem.eql(u8, args.items[0], "init")) {
        logger.trace("initialising {s}...", .{path});
        const file = std.fs.cwd().createFile(path, .{ .exclusive = true }) catch |err| {
            logger.fault("could not initialise {s} ({s})", .{ path, @errorName(err) });
            std.process.exit(1);
        };
        file.close();
        logger.debug("initialised {s}", .{path});
        std.process.exit(0);
    }

    var db = database.init(path);
    defer db.deinit();

    if (std.mem.eql(u8, args.items[0], "list")) {
        logger.info("watching {d} applications", .{db.apps.items.len});
        if (db.apps.items.len > 0) {
            logger.info("id name", .{});
        }
        for (db.apps.items) |app| {
            logger.info("{d} {s}", .{ app.id, app.name });
        }
        std.process.exit(0);
    }

    if (std.mem.eql(u8, args.items[0], "add")) {
        if (args.items.len != 2) {
            logger.warn("invalid amount of arguments for adding", .{});
            logger.info("usage: add name", .{});
            std.process.exit(1);
        }
        const name = std.heap.c_allocator.alloc(u8, args.items[1].len) catch |err| {
            logger.panic("could not allocate {d} bytes ({s})", .{ args.items[1].len, @errorName(err) });
            std.process.exit(1);
        };
        std.mem.copyForwards(u8, name, args.items[1]);
        if (name.len < 2 or name.len > 16) {
            logger.warn("name must be between 2 and 16 characters", .{});
            std.process.exit(1);
        }
        if (db.apps.items.len >= 255) {
            logger.warn("can not store more than 255 applications", .{});
            std.process.exit(1);
        }
        const id: u8 = @intCast(db.apps.items.len);
        db.insert(.{ .id = id, .name = name }) catch |err| {
            logger.fault("could not insert application ({s})", .{@errorName(err)});
            std.process.exit(1);
        };
        std.process.exit(0);
    }

    if (std.mem.eql(u8, args.items[0], "remove")) {
        if (args.items.len != 2) {
            logger.warn("invalid amount of arguments for removing", .{});
            logger.info("usage: remove id", .{});
            std.process.exit(1);
        }
        const id = std.fmt.parseInt(u8, args.items[1], 10) catch |err| {
            logger.warn("id must be between 0 and 255 ({s})", .{@errorName(err)});
            std.process.exit(1);
        };
        db.delete(id) catch |err| {
            logger.fault("could not delete application ({s})", .{@errorName(err)});
            std.process.exit(1);
        };
        std.process.exit(0);
    }
}
