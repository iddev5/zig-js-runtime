const std = @import("std");
const app = @import("simple.zig");

const js = struct {
    extern fn wzLogWrite(str: [*]const u8, len: u32) void;
    extern fn wzLogFlush() void;
    extern fn wzPanic(str: [*]const u8, len: u32) void;
};

pub const log_level = .info;

const LogError = error{};
const LogWriter = std.io.Writer(void, LogError, writeLog);

fn writeLog(_: void, msg: []const u8) LogError!usize {
    js.wzLogWrite(msg.ptr, @intCast(u32, msg.len));
    return msg.len;
}

pub fn log(
    comptime message_level: std.log.Level,
    comptime scope: @Type(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const prefix = if (scope == .default) ": " else "(" ++ @tagName(scope) ++ "): ";
    const writer = LogWriter{ .context = {} };

    writer.print(message_level.asText() ++ prefix ++ format ++ "\n", args) catch return;
    js.wzLogFlush();
}

pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace) noreturn {
    js.wzPanic(msg.ptr, @intCast(u32, msg.len));
    unreachable;
}

export fn main() void {
    app.main() catch |e| @panic(std.fmt.comptimePrint("error: {s}", .{@tagName(e)}));
}
