const std = @import("std");
const config = @import("config.zig");
const utils = @import("utils.zig");

const stdout = std.io.getStdOut().writer();
const stderr = std.io.getStdErr().writer();

const purple = "\x1b[35m";
const blue = "\x1b[34m";
const cyan = "\x1b[36m";
const green = "\x1b[32m";
const yellow = "\x1b[33m";
const red = "\x1b[31m";
const bold = "\x1b[1m";
const reset = "\x1b[0m";

var mutex = std.Thread.Mutex{};

fn log(comptime writer: anytype, comptime color: []const u8, comptime level: []const u8, comptime format: []const u8, args: anytype) void {
    mutex.lock();
    defer mutex.unlock();
    writer.print(bold ++ "owl" ++ reset ++ " " ++ bold ++ color ++ level ++ reset ++ bold ++ ":" ++ reset ++ " " ++ format ++ "\n", args) catch return;
}

pub fn request(method: []const u8, pathname: []const u8, address: std.net.Address) void {
    if (config.log_requests) {
        log(stdout, "", "req", "{s} {s} from {}", .{ method, pathname, address });
    }
}

pub fn response(status: u9, time: u48, bytes: usize) void {
    if (config.log_responses) {
        const human_time = utils.nanoseconds(time) catch "???ns";
        defer std.heap.c_allocator.free(human_time);
        const human_bytes = utils.bytes(bytes) catch "???b";
        defer std.heap.c_allocator.free(human_bytes);
        log(stdout, "", "res", "{d} took {s} {s}", .{ status, human_time, human_bytes });
    }
}

pub fn trace(comptime format: []const u8, args: anytype) void {
    if (config.log_level >= 6) {
        log(stdout, blue, "trace", format, args);
    }
}

pub fn debug(comptime format: []const u8, args: anytype) void {
    if (config.log_level >= 5) {
        log(stdout, cyan, "debug", format, args);
    }
}

pub fn info(comptime format: []const u8, args: anytype) void {
    if (config.log_level >= 4) {
        log(stdout, green, "info", format, args);
    }
}

pub fn warn(comptime format: []const u8, args: anytype) void {
    if (config.log_level >= 3) {
        log(stderr, yellow, "warn", format, args);
    }
}

pub fn fault(comptime format: []const u8, args: anytype) void {
    if (config.log_level >= 2) {
        log(stderr, red, "fault", format, args);
    }
}

pub fn panic(comptime format: []const u8, args: anytype) void {
    if (config.log_level >= 1) {
        log(stderr, purple, "panic", format, args);
    }
}
