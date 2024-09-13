const std = @import("std");

pub fn build(builder: *std.Build) void {
    const executable = builder.addExecutable(.{
        .name = "owl",
        .link_libc = true,
        .target = builder.standardTargetOptions(.{}),
        .optimize = builder.standardOptimizeOption(.{}),
        .root_source_file = builder.path("lib/main.zig"),
    });
    builder.exe_dir = "";
    builder.installArtifact(executable);
}
