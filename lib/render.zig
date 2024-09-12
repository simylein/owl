const std = @import("std");
const config = @import("config.zig");
const updraft = @import("updraft.zig");
const uptime = @import("uptime.zig");
const utils = @import("utils.zig");

pub fn head(length: usize) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    try buffer.appendSlice("HTTP/1.1 200 OK\r\n");
    try buffer.appendSlice("content-type:text/html\r\n");
    const slice = try utils.format("content-length:{d}\r\n", .{length});
    defer std.heap.c_allocator.free(slice);
    try buffer.appendSlice(slice);
    try buffer.appendSlice("\r\n");

    return buffer.toOwnedSlice();
}

pub fn body(entries: *std.ArrayList(uptime.Uptime)) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    try buffer.appendSlice("<!doctype html>");
    try buffer.appendSlice("<html lang=\"en\">");

    try buffer.appendSlice("<head>");
    try buffer.appendSlice("<meta charset=\"utf-8\">");
    try buffer.appendSlice("<meta name=\"viewport\" content=\"width=device-width,initial-scale=1.0\">");
    try buffer.appendSlice("<title>owl uptime</title>");

    try updraft.style(&buffer);

    try buffer.appendSlice("</head>");

    try buffer.appendSlice("<body class=\"m-0 black dark:white bg-neutral-100 dark:bg-neutral-900\">");
    try buffer.appendSlice("<main class=\"flex flex-col mx-4 my-6 sm:mx-8 sm:my-9 md:mx-16 md:my-12\">");
    try buffer.appendSlice("<div class=\"flex gap-2 sm:gap-4 flex-col\">");
    for (entries.items) |entry| {
        try container(entry, &buffer);
    }
    try buffer.appendSlice("</div>");
    try buffer.appendSlice("</main>");
    try buffer.appendSlice("</body>");

    try buffer.appendSlice("</html>");

    return buffer.toOwnedSlice();
}

fn container(entry: uptime.Uptime, buffer: *std.ArrayList(u8)) !void {
    const content = try utils.format("<div id=\"{d}\" class=\"flex gap-2 flex-col p-4 rounded bg-white dark:bg-black\">", .{entry.app.id});
    defer std.heap.c_allocator.free(content);
    try buffer.appendSlice(content);

    try buffer.appendSlice("<div class=\"w-full flex gap-4 sm:gap-8 justify-between\">");

    const left = try utils.format("<p class=\"m-0\">{s} <span>{s}</span></p>", .{ entry.app.name, "online" });
    defer std.heap.c_allocator.free(left);
    try buffer.appendSlice(left);

    const right = try utils.format("<p class=\"m-0\">uptime <span>{d}%</span></p>", .{100});
    defer std.heap.c_allocator.free(right);
    try buffer.appendSlice(right);

    try buffer.appendSlice("</div>");

    try timeline(entry.days, buffer);

    try buffer.appendSlice("</div>");
}

fn timeline(days: [96]uptime.Day, buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("<div class=\"grid gap-0.5 grid-columns-32 sm:grid-columns-48 md:grid-columns-64 lg:grid-columns-80 xl:grid-columns-96\">");

    var index: u7 = 0;
    while (index < days.len) : (index += 1) {
        const total: f16 = @floatFromInt(days[index].healthy + days[index].unhealthy);
        const healthy: f16 = @floatFromInt(days[index].healthy);
        const percent: f16 = if (total != 0) (healthy / total) * 100 else 0.0;
        const display = try visibility(index);
        defer std.heap.c_allocator.free(display);
        const color = try colorize(percent);
        defer std.heap.c_allocator.free(color);
        const slice = try utils.format("<div class=\"{s} h-8 rounded-sm {s}\" title=\"{d:.2}%\"></div>", .{ display, color, percent });
        defer std.heap.c_allocator.free(slice);
        try buffer.appendSlice(slice);
    }

    try buffer.appendSlice("</div>");
}

fn visibility(index: u7) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    if (index < 32) {
        try buffer.appendSlice("block");
    } else if (index < 48) {
        try buffer.appendSlice("hidden sm:block");
    } else if (index < 64) {
        try buffer.appendSlice("hidden md:block");
    } else if (index < 80) {
        try buffer.appendSlice("hidden lg:block");
    } else if (index < 96) {
        try buffer.appendSlice("hidden xl:block");
    }

    return buffer.toOwnedSlice();
}

fn colorize(percent: f16) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    if (percent == 0) {
        try buffer.appendSlice("bg-neutral-300 dark:bg-neutral-700");
    } else if (percent > 99.9) {
        try buffer.appendSlice("bg-green-400 dark:bg-green-600");
    } else if (percent > 99) {
        try buffer.appendSlice("bg-yellow-400 dark:bg-yellow-600");
    } else if (percent > 98) {
        try buffer.appendSlice("bg-orange-400 dark:bg-orange-600");
    } else {
        try buffer.appendSlice("bg-red-400 dark:bg-red-600");
    }

    return buffer.toOwnedSlice();
}
