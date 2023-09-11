//! This module provides a simple integration test, reconstructing data from yielded chunks
//! [Released under GNU LGPLv3]
//!
const std = @import("std");
const cdc = @import("cdc.zig");

test "Reconstruct data from yielded chunks" {
    var random_data: [10490000]u8 = undefined; // 10MB
    try std.os.getrandom(&random_data);

    const desired_chunk_size: usize = 1049000; // 1MB
    const masks = comptime cdc.generateMasks(desired_chunk_size);

    var chunk_iterator = cdc.ChunkIterator.init(.{
        .desired_chunk_size = desired_chunk_size,
        .minimum_chunk_size = 943700, // 0.9 MB
        .maximum_chunk_size = 1153000, // 1.1MB
        .mask_s = masks.mask_s,
        .mask_l = masks.mask_l,
    });

    var check_buffer: [10490000]u8 = undefined;

    for (random_data) |byte| {
        if (chunk_iterator.consume(byte)) |chunk| {
            @memcpy(random_data[chunk.offset .. chunk.offset + chunk.length], check_buffer[chunk.offset .. chunk.offset + chunk.length]);
        }
    }

    if (chunk_iterator.final()) |chunk| {
        @memcpy(random_data[chunk.offset .. chunk.offset + chunk.length], check_buffer[chunk.offset .. chunk.offset + chunk.length]);
    }

    try std.testing.expect(std.mem.eql(u8, &random_data, &check_buffer));
}
