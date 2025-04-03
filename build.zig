const std = @import("std");
const builtin = @import("builtin");
const os = builtin.os;
const cpu = builtin.cpu;
const assert = std.debug.assert;

pub fn build(b: *std.Build) !void {
    const pandoc_dependency = if (os.tag == .linux and cpu.arch == .x86_64)
        b.lazyDependency("pandoc_linux_amd64", .{}) orelse return
    else if (os.tag == .macos and cpu.arch == .aarch64)
        b.lazyDependency("pandoc_macos_arm64", .{}) orelse return
    else
        return error.UnsupportedHost;
    const pandoc = pandoc_dependency.path("bin/pandoc");

    const website = b.addWriteFiles();

    const markdown_files = b.run(&.{ "git", "ls-files", "content/*.md" });
    var lines = std.mem.tokenizeScalar(u8, markdown_files, '\n');
    while (lines.next()) |file_path| {
        const markdown = b.path(file_path);
        const html = markdown2html(b, pandoc, markdown);

        var html_path = file_path;
        html_path = cut_prefix(html_path, "content/").?;
        html_path = cut_suffix(html_path, ".md").?;
        html_path = b.fmt("{s}.html", .{html_path});

        _ = website.addCopyFile(html, html_path);
    }

    b.installDirectory(.{
        .source_dir = website.getDirectory(),
        .install_dir = .prefix,
        .install_subdir = ".",
    });
}

fn markdown2html(
    b: *std.Build,
    pandoc: std.Build.LazyPath,
    markdown: std.Build.LazyPath,
) std.Build.LazyPath {
    const pandoc_step = std.Build.Step.Run.create(b, "run pandoc");
    pandoc_step.addFileArg(pandoc);
    pandoc_step.addArgs(&.{ "--from=markdown", "--to=html5" });
    pandoc_step.addFileArg(markdown);
    return pandoc_step.captureStdOut();
}

fn cut_prefix(text: []const u8, prefix: []const u8) ?[]const u8 {
    if (std.mem.startsWith(u8, text, prefix)) return text[prefix.len..];
    return null;
}

fn cut_suffix(text: []const u8, suffix: []const u8) ?[]const u8 {
    if (std.mem.endsWith(u8, text, suffix)) return text[0 .. text.len - suffix.len];
    return null;
}
