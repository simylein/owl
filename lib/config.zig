const std = @import("std");
const logger = @import("logger.zig");

pub var host: []u8 = undefined;
pub var port: u16 = 4000;

pub var bucket_size: u24 = std.time.s_per_day;

pub var log_level: u3 = 4;
pub var log_requests: bool = true;
pub var log_responses: bool = true;

pub fn init(args: *std.process.ArgIterator) void {
    if (!args.skip()) {
        logger.panic("the zeroth argument is empty", .{});
        std.process.exit(1);
    }

    const default = "127.0.0.1";
    host = std.heap.c_allocator.alloc(u8, default.len) catch |err| {
        logger.panic("failed to allocate {d} bytes ({s})", .{ default.len, @errorName(err) });
        std.process.exit(1);
    };
    std.mem.copyForwards(u8, host, default);

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--host")) {
            if (args.next()) |value| {
                std.heap.c_allocator.free(host);
                host = std.heap.c_allocator.alloc(u8, value.len) catch |err| {
                    logger.panic("failed to allocate {d} bytes ({s})", .{ value.len, @errorName(err) });
                    std.process.exit(1);
                };
                std.mem.copyForwards(u8, host, value);
            } else {
                logger.fault("please provide a host", .{});
                std.process.exit(1);
            }
        }

        if (std.mem.eql(u8, arg, "--port")) {
            if (args.next()) |value| {
                port = std.fmt.parseInt(u16, value, 10) catch {
                    logger.fault("port must be between 0 and 65535", .{});
                    std.process.exit(1);
                };
            } else {
                logger.fault("please provide a port", .{});
                std.process.exit(1);
            }
        }

        if (std.mem.eql(u8, arg, "--bucket-size")) {
            if (args.next()) |value| {
                bucket_size = std.fmt.parseInt(u24, value, 10) catch {
                    logger.fault("bucket size must be between 0 and 16777216", .{});
                    std.process.exit(1);
                };
            } else {
                logger.fault("please provide a bucket size", .{});
                std.process.exit(1);
            }
        }

        if (std.mem.eql(u8, arg, "--log-level")) {
            if (args.next()) |value| {
                if (std.mem.eql(u8, value, "trace")) {
                    log_level = 6;
                } else if (std.mem.eql(u8, value, "debug")) {
                    log_level = 5;
                } else if (std.mem.eql(u8, value, "info")) {
                    log_level = 4;
                } else if (std.mem.eql(u8, value, "warn")) {
                    log_level = 3;
                } else if (std.mem.eql(u8, value, "fault")) {
                    log_level = 2;
                } else if (std.mem.eql(u8, value, "panic")) {
                    log_level = 1;
                } else {
                    logger.fault("log level must be one of trace debug info warn error panic", .{});
                    std.process.exit(1);
                }
            } else {
                logger.fault("please provide a log level", .{});
                std.process.exit(1);
            }
        }

        if (std.mem.eql(u8, arg, "--log-requests")) {
            if (args.next()) |value| {
                if (std.mem.eql(u8, value, "true")) {
                    log_requests = true;
                } else if (std.mem.eql(u8, value, "false")) {
                    log_requests = false;
                } else {
                    logger.fault("log requests must be one of true false", .{});
                    std.process.exit(1);
                }
            } else {
                logger.fault("please provide a log requests value", .{});
                std.process.exit(1);
            }
        }

        if (std.mem.eql(u8, arg, "--log-responses")) {
            if (args.next()) |value| {
                if (std.mem.eql(u8, value, "true")) {
                    log_responses = true;
                } else if (std.mem.eql(u8, value, "false")) {
                    log_responses = false;
                } else {
                    logger.fault("log responses must be one of true false", .{});
                    std.process.exit(1);
                }
            } else {
                logger.fault("please provide a log responses value", .{});
                std.process.exit(1);
            }
        }
    }
}
