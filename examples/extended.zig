const std = @import("std");
const js = @import("js-runtime");

pub fn main() !void {
    const global = js.global();
    const object = js.Object{ .tag = .nulled, .val = undefined };
    const object1 = js.Object{ .tag = .undef, .val = undefined };
    global.set("test_prop", &object);
    global.set("test_prop1", &object1);

    if (true) unreachable;

    const val = global.call("string_func", &.{});
    const str = val.getString(std.heap.page_allocator) catch unreachable;
    std.log.info("string is: {s}\n", .{str});
    global.set("string_prop", &val);

    std.log.info("{} {}", .{ global.call("udfun", &.{}).tag, global.call("nufun", &.{}).tag });
}
