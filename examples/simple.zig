const std = @import("std");
const js = @import("js-runtime");

pub fn main() !void {
    const global = js.global();
    const object = js.Object{ .tag = .num, .val = .{ .num = 43.27 } };
    global.set("test_prop", &object);

    const test_prop = global.get("test_prop");
    std.log.info("test_prop {}", .{test_prop.val.num});
    {
        const my_custom = js.Object.initMap();
        defer my_custom.deinit();
        global.set("my_custom", &my_custom);
        my_custom.set("xyz", &object);
        std.log.info("my_custom.xyz {}", .{global.get("my_custom").get("xyz").val.num});
    }

    const object2 = js.Object{ .tag = .num, .val = .{ .num = 27.43 } };
    const very_custom = js.Object.initMap();
    very_custom.set("abc", &object2);
    std.log.info("very_custom is {}", .{very_custom.val.ref});
    std.log.info("very_custom.abc {}", .{very_custom.get("abc").val.num});
}
