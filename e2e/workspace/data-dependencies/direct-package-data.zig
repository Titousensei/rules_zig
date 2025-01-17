const std = @import("std");
const direct_package = @import("direct-package");

test "read data file" {
    const content = try direct_package.readData(std.testing.allocator);
    defer std.testing.allocator.free(content);

    try std.testing.expectEqualStrings("Hello World!\n", content);
}
