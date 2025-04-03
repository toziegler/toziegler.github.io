const std = @import("std");
const builtin = @import("builtin");
const os = builtin.os;
const cpu = builtin.cpu;
const assert = std.debug.assert;

pub fn build(b: *std.Build) !void {
    const website = b.addWriteFiles();
    const markdown_files = b.run(&.{ "git", "ls-files", "contents/*.md" });

    std.debug.print("{s}\n", .{markdown_files});
    var lines = std.mem.tokenizeScalar(u8, markdown_files, '\n');
    while (lines.next()) |file_path| {
        std.debug.print("{s} \n", .{file_path});
        const markdown = b.path(file_path);
        const html = markdown2html(b, markdown);

        var html_path = file_path;
        html_path = cut_prefix(html_path, "contents/").?;
        html_path = cut_suffix(html_path, ".md").?;
        html_path = b.fmt("{s}.html", .{html_path});

        _ = website.addCopyFile(html, html_path);
    }
    const index = b.path("./index.html");
    _ = website.addCopyFile(index, "index.html");
    const assets = b.path("assets");
    _ = website.addCopyDirectory(assets, "assets", .{});

    b.installDirectory(.{
        .source_dir = website.getDirectory(),
        .install_dir = .{ .custom = "../docs" },
        .install_subdir = ".",
    });
}

fn markdown2html(
    b: *std.Build,
    markdown: std.Build.LazyPath,
) std.Build.LazyPath {
    const pandoc_step = std.Build.Step.Run.create(b, "run pandoc");
    pandoc_step.addArgs(&.{ "pandoc", "-s", "--from=markdown", "--to=html5", "--css=assets/style.css", "--highlight-style=tango", "--template=assets/template.html" });
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
