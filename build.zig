const std = @import("std");

const web_install_dir = std.build.InstallDir{ .custom = "www" };

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();
    const example = b.option([]const u8, "example", "Example program to use") orelse "simple";

    const exe_options = b.addOptions();
    exe_options.addOption([]const u8, "example", example);

    const exe = b.addSharedLibrary("application", "examples/main.zig", .unversioned);
    exe.setTarget(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
        .abi = .none,
    });
    exe.setBuildMode(mode);
    exe.addPackage(.{
        .name = "js-runtime",
        .source = .{ .path = "src/main.zig" },
    });
    exe.addOptions("exe_options", exe_options);
    exe.install();
    exe.install_step.?.dest_dir = web_install_dir;

    // Install step
    const install_rt_js = b.addInstallFileWithDir(
        .{ .path = comptime getRoot() ++ "/src/zig-runtime.js" },
        web_install_dir,
        "zig-runtime.js",
    );
    exe.install_step.?.step.dependOn(&install_rt_js.step);

    const install_template_html = b.addInstallFileWithDir(
        .{ .path = comptime getRoot() ++ "/www/template.html" },
        web_install_dir,
        "application.html",
    );
    exe.install_step.?.step.dependOn(&install_template_html.step);

    // Run step
    const serve = b.addSystemCommand(&.{
        "python3", "-m", "http.server",
    });
    serve.cwd = b.getInstallPath(web_install_dir, "");
    serve.step.dependOn(&exe.install_step.?.step);

    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&serve.step);
}

fn getRoot() []const u8 {
    return std.fs.path.dirname(@src().file) orelse ".";
}
