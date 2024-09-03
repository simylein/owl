const std = @import("std");

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

fn log(comptime writer: anytype, comptime color: []const u8, comptime level: []const u8, comptime format: []const u8, args: anytype) void {
    writer.print(bold ++ "owl" ++ reset ++ " " ++ bold ++ color ++ level ++ reset ++ bold ++ ":" ++ reset ++ " " ++ format ++ "\n", args) catch return;
}

pub fn trace(comptime format: []const u8, args: anytype) void {
    log(stdout, blue, "trace", format, args);
}

pub fn debug(comptime format: []const u8, args: anytype) void {
    log(stdout, cyan, "debug", format, args);
}

pub fn info(comptime format: []const u8, args: anytype) void {
    log(stdout, green, "info", format, args);
}

pub fn warn(comptime format: []const u8, args: anytype) void {
    log(stderr, yellow, "warn", format, args);
}

pub fn fault(comptime format: []const u8, args: anytype) void {
    log(stderr, red, "fault", format, args);
}

pub fn panic(comptime format: []const u8, args: anytype) void {
    log(stderr, purple, "panic", format, args);
}
