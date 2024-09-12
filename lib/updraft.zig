const std = @import("std");

pub fn style(buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("<style>");

    try global(buffer);
    try small(buffer);
    try dark(buffer);

    try buffer.appendSlice("</style>");
}

fn global(buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("body{-webkit-font-smoothing: antialiased;-moz-osx-font-smoothing: grayscale;font-family: -apple-system, BlinkMacSystemFont, Helvetica, Arial, Roboto, Oxygen, sans-serif}");

    try buffer.appendSlice(".w-full{width:100%}");
    try buffer.appendSlice(".h-8{height:32px}");

    try buffer.appendSlice(".m-0{margin:0}");
    try buffer.appendSlice(".mx-4{margin-left:16px;margin-right:16px}");
    try buffer.appendSlice(".my-6{margin-top:24px;margin-bottom:24px}");

    try buffer.appendSlice(".p-4{padding:16px}");

    try buffer.appendSlice(".gap-2{gap:8px}");
    try buffer.appendSlice(".gap-4{gap:16px}");

    try buffer.appendSlice(".flex{display:flex}");
    try buffer.appendSlice(".flex-col{flex-direction:column}");
    try buffer.appendSlice(".justify-between{justify-content:space-between}");

    try buffer.appendSlice(".grid{display:grid}");
    try buffer.appendSlice(".grid-columns-32{grid-template-columns:repeat(32,minmax(0,1fr))}");

    try buffer.appendSlice(".rounded{border-radius:4px}");
    try buffer.appendSlice(".rounded-sm{border-radius:2px}");

    try buffer.appendSlice(".black{color:#000000}");
    try buffer.appendSlice(".bg-neutral-100{background-color:#f5f5f5}");
    try buffer.appendSlice(".bg-white{background-color:#ffffff}");
}

fn small(buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("@media(min-width:640px){");

    try buffer.appendSlice(".sm\\:mx-16{margin-left:64px;margin-right:64px}");
    try buffer.appendSlice(".sm\\:my-12{margin-top:48px;margin-bottom:48px}");

    try buffer.appendSlice(".sm\\:gap-4{gap:16px}");
    try buffer.appendSlice(".sm\\:gap-8{gap:32px}");

    try buffer.appendSlice("}");
}

fn dark(buffer: *std.ArrayList(u8)) !void {
    try buffer.appendSlice("@media(prefers-color-scheme:dark){");
    try buffer.appendSlice(".dark\\:white{color:#ffffff}");
    try buffer.appendSlice(".dark\\:bg-black{background-color:#000000}");
    try buffer.appendSlice(".dark\\:bg-neutral-900{background-color:#171717}");
    try buffer.appendSlice("}");
}
