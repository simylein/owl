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

    const status = switch (entry.app.latest.healthyness) {
        0 => "unknown",
        1 => "offline",
        2 => "unstable",
        3 => "recovery",
        4 => "online",
        else => "",
    };
    const status_color = switch (entry.app.latest.healthyness) {
        0 => "neutral-500 dark:neutral-400",
        1 => "red-600 dark:red-500",
        2 => "orange-600 dark:orange-500",
        3 => "yellow-600 dark:yellow-500",
        4 => "green-600 dark:green-500",
        else => "",
    };

    const left = try utils.format("<p class=\"m-0 font-normal\">{s} <span class=\"font-semibold {s}\">{s}</span></p>", .{ entry.app.name, status_color, status });
    defer std.heap.c_allocator.free(left);
    try buffer.appendSlice(left);

    var total_healthy: f32 = 0;
    var total_count: f32 = 0;
    for (entry.days) |day| {
        const healthy: f16 = @floatFromInt(day.healthy);
        const count: f16 = @floatFromInt(day.healthy + day.unhealthy);
        total_healthy += healthy;
        total_count += count;
    }
    const percent: f32 = if (total_count != 0) (total_healthy / total_count) * 100 else 0.0;
    const percent_color = try colorizeUptime(.{ .value = percent, .count = total_count });
    defer std.heap.c_allocator.free(percent_color);

    const right = try utils.format("<p class=\"m-0 font-normal\">uptime <span class=\"font-semibold {s}\">{d:.2}%</span></p>", .{ percent_color, percent });
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
        const percent = percentage(days[index]);
        const display = try visibility(index);
        defer std.heap.c_allocator.free(display);
        const color = try colorizeDay(percent);
        defer std.heap.c_allocator.free(color);
        const slice = try utils.format("<div class=\"{s} h-8 rounded-sm {s}\" title=\"{d:.2}%\"></div>", .{ display, color, percent.value });
        defer std.heap.c_allocator.free(slice);
        try buffer.appendSlice(slice);
    }

    try buffer.appendSlice("</div>");
}

const Percentage = struct {
    value: f16,
    count: f16,
};

fn percentage(day: uptime.Day) Percentage {
    const healthy: f16 = @floatFromInt(day.healthy);
    const count: f16 = @floatFromInt(day.healthy + day.unhealthy);
    const value: f16 = if (count != 0) (healthy / count) * 100 else 0.0;
    return Percentage{ .value = value, .count = count };
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

fn colorizeDay(percent: Percentage) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    if (percent.value == 0 and percent.count == 0) {
        try buffer.appendSlice("bg-neutral-300 dark:bg-neutral-700");
    } else if (percent.value > 99.9) {
        try buffer.appendSlice("bg-green-400 dark:bg-green-600");
    } else if (percent.value > 99) {
        try buffer.appendSlice("bg-yellow-400 dark:bg-yellow-600");
    } else if (percent.value > 98) {
        try buffer.appendSlice("bg-orange-400 dark:bg-orange-600");
    } else {
        try buffer.appendSlice("bg-red-400 dark:bg-red-600");
    }

    return buffer.toOwnedSlice();
}

const TotalPercentage = struct {
    value: f32,
    count: f32,
};

fn colorizeUptime(percent: TotalPercentage) ![]u8 {
    var buffer = std.ArrayList(u8).init(std.heap.c_allocator);

    if (percent.value == 0 and percent.count == 0) {
        try buffer.appendSlice("neutral-500 dark:neutral-400");
    } else if (percent.value > 99.9) {
        try buffer.appendSlice("green-600 dark:green-500");
    } else if (percent.value > 99) {
        try buffer.appendSlice("yellow-600 dark:yellow-500");
    } else if (percent.value > 98) {
        try buffer.appendSlice("orange-400 dark:orange-600");
    } else {
        try buffer.appendSlice("red-600 dark:red-500");
    }

    return buffer.toOwnedSlice();
}
