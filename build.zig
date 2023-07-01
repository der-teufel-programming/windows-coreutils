const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tools: []const []const u8 = &.{ "touch", "rm" };
    inline for (tools) |tool| {
        const exe = b.addExecutable(.{
            .name = tool,
            .root_source_file = .{ .path = tool ++ ".zig" },
            .target = target,
            .optimize = optimize,
        });
        exe.override_dest_dir = .prefix;
        b.installArtifact(exe);
    }
}
