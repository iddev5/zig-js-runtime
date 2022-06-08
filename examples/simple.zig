const std = @import("std");
const js = @import("js-runtime");

pub fn main() !void {
    const global = js.global();
    const object = js.Object{ .tag = 1, .val = .{ .num = 43.27 } };
    global.set("test_prop", &object);

    const test_prop = global.get("test_prop");
    std.log.info("test_prop {}", .{test_prop.val.num});

    const my_custom = js.Object.initMap();
    global.set("my_custom", &my_custom);
    my_custom.set("xyz", &object);
    std.log.info("my_custom.test_prop {}", .{my_custom.get("xyz").val.num});
}