const std = @import("std");

pub fn build(b: *std.Build) void {
    // Standard target and optimize options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create an executable for the proxy server
    const exe = b.addExecutable(.{
        .name = "proxy-server",
        .root_source_file = b.path("src/main2.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Install the executable
    b.installArtifact(exe);

    // Add a run step to make it easy to execute the program
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    // Allow the user to pass arguments to the program
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // Create a "run" step for convenience
    const run_step = b.step("run", "Run the proxy server");
    run_step.dependOn(&run_cmd.step);

    // Optionally, add a test step if you have tests
    const tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&tests.step);
}
