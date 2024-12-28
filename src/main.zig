const std = @import("std");
const Child = std.process.Child;
const fs = std.fs;
const os = std.os;

const AllowedDomains = struct {
    domains: []const []const u8,

    pub fn contains(self: AllowedDomains, domain: []const u8) bool {
        for (self.domains) |allowed| {
            if (allowed[0] == '.') {
                if (std.mem.endsWith(u8, domain, allowed)) return true;
            } else {
                if (std.mem.eql(u8, allowed, domain)) return true;
            }
        }
        return false;
    }
};

fn setupPfRules(allowed_domains: AllowedDomains, allocator: std.mem.Allocator) !void {
    var rules = std.ArrayList(u8).init(allocator);
    defer rules.deinit();

    // Disable PF first
    {
        var disable_cmd = Child.init(&[_][]const u8{ "pfctl", "-d" }, allocator);
        _ = try disable_cmd.spawnAndWait();
    }
    // Enable PF
    {
        var enable_cmd = Child.init(&[_][]const u8{ "pfctl", "-e" }, allocator);
        _ = try enable_cmd.spawnAndWait();
    }

    // Write base rules
    try rules.appendSlice(
        \\# Allow localhost
        \\set skip on lo0
        \\
        \\# Default block
        \\block return out proto tcp from any to any port {80, 443}
        \\
    );

    // Add allowed domains
    for (allowed_domains.domains) |domain| {
        const rule = try std.fmt.allocPrint(
            allocator,
            "pass out proto tcp from any to {s} port {{80, 443}}\n",
            .{if (domain[0] == '.') domain[1..] else domain},
        );
        defer allocator.free(rule);
        try rules.appendSlice(rule);
    }

    // Write rules to a temporary file
    const tmp_path = "/tmp/pf.rules";
    {
        const file = try fs.cwd().createFile(tmp_path, .{});
        defer file.close();
        try file.writeAll(rules.items);
    }
    defer fs.cwd().deleteFile(tmp_path) catch {};

    // Apply the rules from the temporary file
    {
        var apply_cmd = Child.init(&[_][]const u8{ "pfctl", "-f", tmp_path }, allocator);
        const term = try apply_cmd.spawnAndWait();

        if (term != .Exited or term.Exited != 0) {
            std.debug.print("pfctl failed to apply rules\n", .{});
            return error.PfctlFailed;
        }
    }
}

fn killPfctl(allocator: std.mem.Allocator) !void {
    var disable_cmd = Child.init(&[_][]const u8{ "pfctl", "-d" }, allocator);
    const term = try disable_cmd.spawnAndWait();

    if (term != .Exited or term.Exited != 0) {
        std.debug.print("pfctl failed to disable\n", .{});
        return error.PfctlFailed;
    }
}

pub fn main() !void {
    const allowed_domains = AllowedDomains{
        .domains = &[_][]const u8{
            "claude.ai", // Exact match for claude.ai
            ".claude.ai", // Matches all subdomains of claude.ai
            "www.github.com",
            ".github.com", // All subdomains of github.com
            "www.chat.com",
            ".chat.com", // ChatGPT
            "www.chatgpt.com",
            ".chatgpt.com",
            "www.deepseek.com", // DeepSeek
            ".deepseek.com",
        },
    };

    try setupPfRules(allowed_domains, std.heap.page_allocator);
    std.debug.print("Traffic blocking enabled. Only allowed domains can be accessed.\n", .{});

    // Set up signal handling for SIGINT (CTRL+C)
    const act = std.posix.Sigaction{
        .handler = .{ .handler = handleSignal },
        .mask = std.posix.empty_sigset,
        .flags = 0,
    };
    try std.posix.sigaction(std.posix.SIG.INT, &act, null);

    // Keep the program running until interrupted
    while (!should_exit) {
        std.time.sleep(std.time.ns_per_s);
    }

    try killPfctl(std.heap.page_allocator);
    std.debug.print("Shutting down gracefully...\n", .{});
}

// Global flag to indicate if the program should exit
var should_exit: bool = false;

// Signal handler function
fn handleSignal(sig: c_int) callconv(.C) void {
    if (sig == std.posix.SIG.INT) {
        should_exit = true;
    }
}
