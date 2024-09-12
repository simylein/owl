const std = @import("std");
const config = @import("config.zig");
const updraft = @import("updraft.zig");
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

pub fn body(apps: std.ArrayList(config.App)) ![]u8 {
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
    try buffer.appendSlice("<main class=\"flex flex-col mx-4 my-6 sm:mx-16 sm:my-12\">");
    try buffer.appendSlice("<div class=\"flex gap-2 sm:gap-4 flex-col\">");
    for (apps.items) |app| {
        try container(app, &buffer);
    }
    try buffer.appendSlice("</div>");
    try buffer.appendSlice("</main>");
    try buffer.appendSlice("</body>");

    try buffer.appendSlice("</html>");

    return buffer.toOwnedSlice();
}

fn container(app: config.App, buffer: *std.ArrayList(u8)) !void {
    const content = try utils.format("<div id=\"{d}\" class=\"flex gap-2 flex-col p-4 rounded bg-white dark:bg-black\">", .{app.id});
    defer std.heap.c_allocator.free(content);
    try buffer.appendSlice(content);

    try buffer.appendSlice("<div class=\"w-full flex gap-4 sm:gap-8 justify-between\">");

    const name = try utils.format("<p class=\"m-0\">{s} <span>{s}</span></p>", .{ app.name, "online" });
    defer std.heap.c_allocator.free(name);
    try buffer.appendSlice(name);

    const uptime = try utils.format("<p class=\"m-0\">uptime <span>{d}%</span></p>", .{100});
    defer std.heap.c_allocator.free(uptime);
    try buffer.appendSlice(uptime);

    try buffer.appendSlice("</div>");

    try timeline(.{ 1.1, 2.2 }, buffer);

    try buffer.appendSlice("</div>");
}

fn timeline(uptimes: [2]f16, buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("<div class=\"grid gap-2 grid-columns-32\">");

    for (uptimes) |uptime| {
        const slice = try utils.format("<div class=\"h-8 rounded-sm\" title=\"{d}%\"></div>", .{uptime});
        defer std.heap.c_allocator.free(slice);
        try buffer.appendSlice(slice);
    }

    try buffer.appendSlice("</div>");
}
