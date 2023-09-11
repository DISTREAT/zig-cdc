const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "zig-cdc",
        .root_source_file = .{ .path = "src/lib.zig" },
        .target = target,
        .optimize = optimize,
    });

    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/tests.zig" },
        .target = target,
        .optimize = optimize,
    });

    const stats = b.addExecutable(.{
        .name = "cdc-stats",
        .root_source_file = .{ .path = "src/stats.zig" },
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(lib);

    const test_step = b.step("test", "Run integration tests");
    test_step.dependOn(&b.addRunArtifact(tests).step);
    const stats_step = b.step("stats", "Perform test runs and collect stats");
    stats_step.dependOn(&b.addRunArtifact(stats).step);
}
