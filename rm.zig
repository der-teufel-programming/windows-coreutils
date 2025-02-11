const std = @import("std");

fn oom(err: std.mem.Allocator.Error) noreturn {
    _ = err catch {};
    @panic("Out of memory");
}

fn usage() !void {
    const stderr = std.io.getStdErr().writer();
    try stderr.writeAll("Usage: rm [-rf] FILE...\n" ++
        "    -r recurse\n" ++
        "    -f force remove (never prompt)\n");
}

pub fn main() !u8 {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const all_args = try std.process.argsAlloc(allocator);
    // no need to free

    if (all_args.len <= 1) {
        try usage();
        return 0x7f;
    }

    var recurse = false;
    var force = false;
    const args = blk: {
        var new_args = all_args[1..];
        var new_arg_count: usize = 0;
        for (new_args) |arg| {
            if (!std.mem.startsWith(u8, arg, "-")) {
                new_args[new_arg_count] = arg;
                new_arg_count += 1;
            } else {
                for (arg[1..]) |c| {
                    if (c == 'r') {
                        recurse = true;
                    } else if (c == 'f') {
                        force = true;
                    } else {
                        std.log.err("unknown cmdline option '-{c}'", .{c});
                        return 0x7f;
                    }
                }
            }
        }
        break :blk new_args[0..new_arg_count];
    };
    if (args.len == 0) {
        try usage();
        return 0x7f;
    }

    const stderr = std.io.getStdErr().writer();
    var got_error = false;
    for (args) |arg| {
        if (recurse) {
            if (!force) {
                std.fs.cwd().access(arg, .{}) catch |err| switch (err) {
                    error.FileNotFound => {
                        try stderr.print("rm: '{s}' does not exist", .{arg});
                        got_error = true;
                        continue;
                    },
                    else => |e| return e,
                };
            }
            try std.fs.cwd().deleteTree(arg);
        } else {
            std.fs.cwd().deleteFile(arg) catch |err| switch (err) {
                error.FileNotFound => {
                    if (!force) {
                        try stderr.print("rm: '{s}' does not exist", .{arg});
                        got_error = true;
                    }
                },
                error.IsDir => {
                    try stderr.print("rm: '{s}' is a directory\n", .{arg});
                    got_error = true;
                },
                else => |e| return e,
            };
        }
    }

    return if (got_error) 0x7f else 0;
}
