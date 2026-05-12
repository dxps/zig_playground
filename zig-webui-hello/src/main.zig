const std = @import("std");
const webui = @import("webui");

var spa_response: []const u8 = "";

fn loadSpaResponse(io: std.Io, allocator: std.mem.Allocator) !void {
    const html = try std.Io.Dir.cwd().readFileAlloc(io, "index.html", allocator, .limited(1024 * 1024));
    defer allocator.free(html);

    spa_response = try std.fmt.allocPrint(
        allocator,
        "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{s}",
        .{ html.len, html },
    );
}

fn serveSpa(filename: []const u8) ?[]const u8 {
    if (std.mem.eql(u8, filename, "/") or
        std.mem.eql(u8, filename, "/data") or
        std.mem.eql(u8, filename, "/index.html"))
    {
        return spa_response;
    }

    return null;
}

pub fn main(init: std.process.Init) !void {
    const allocator = std.heap.page_allocator;
    try loadSpaResponse(init.io, allocator);
    defer allocator.free(spa_response);

    webui.setTimeout(0);
    webui.setConfig(.multi_client, true);
    webui.setConfig(.use_cookies, true);

    var window = webui.newWindow();
    window.setPublic(true);
    window.setFileHandler(serveSpa);

    _ = try window.startServer("/");
    const port = try window.getPort();

    std.debug.print(
        \\Zig WebUI server is running.
        \\Local browser URL: http://localhost:{}
        \\LAN browser URL:   http://<your-machine-ip>:{}
        \\
        \\Press Ctrl+C to stop the server.
        \\
    , .{ port, port });

    webui.wait();
    webui.clean();
}
