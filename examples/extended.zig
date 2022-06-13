const std = @import("std");
const js = @import("js-runtime");

pub fn main() !void {
    const global = js.global();
    const object = js.Object{ .tag = .nulled, .val = undefined };
    const object1 = js.Object{ .tag = .undef, .val = undefined };
    global.set("test_prop", &object);
    global.set("test_prop1", &object1);

    if (true) unreachable;
    std.log.info("{} {}", .{ global.call("udfun", &.{}).tag, global.call("nufun", &.{}).tag });
}
