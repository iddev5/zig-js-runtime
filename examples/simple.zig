const std = @import("std");
const js = @import("js-runtime");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const global = js.global();
    const object = js.createNumber(43.27);
    global.set("test_prop", object);

    const test_prop = global.get("test_prop");
    std.log.info("test_prop {}", .{test_prop.val.num});

    {
        const my_custom = js.createMap();
        defer my_custom.deinit();

        global.set("my_custom", my_custom.toValue());
        defer global.delete("my_custom");

        my_custom.set("xyz", object);
        std.log.info("my_custom.xyz {}", .{global.get("my_custom").value(.object, null).get("xyz").val.num});
    }

    const string = allocator.dupe(u8, "Hello") catch unreachable;
    defer allocator.free(string);
    //const string = "Hello";
    const object2 = js.createString(string);

    const very_custom = js.createArray();
    global.set("very_custom", very_custom.toValue());

    very_custom.setIndex(0, object2);
    defer very_custom.deleteIndex(0);

    std.log.info("very_custom is {}", .{very_custom.ref});
    //std.log.info("very_custom.abc {}", .{very_custom.getIndex(0).val.num});
}
