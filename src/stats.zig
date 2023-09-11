//! This module does in-memory CDC and prints stats to stdout
//! [Released under GNU LGPLv3]
//!
const std = @import("std");
const test_env = @import("test_env.zig");

pub const log_level: std.log.Level = .info;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    std.log.info(
        \\input data size: 10 MB
        \\minimum chunk size: 9.5 KB
        \\desired chunk size: 10 KB
        \\maximum chunk size: 10.5 KB
        \\
    , .{});
    var deduper = test_env.testingDeduper(10490000).init(allocator, 9728, 10240, 10750);
    defer deduper.deinit();

    try deduper.storeChunks();
    const initial_chunk_count = deduper.countChunks();
    const initial_used_space = deduper.usedSpace();
    const initial_smallest_chunk_size = deduper.smallestChunkSize();
    const initial_avg_chunk_size = deduper.averageChunkSize();
    const initial_largest_chunk_size = deduper.largestChunkSize();

    deduper.pointMutation();

    try deduper.storeChunks();
    const mutation_chunk_count = deduper.countChunks();
    const mutation_used_space = deduper.usedSpace();
    const mutation_smallest_chunk_size = deduper.smallestChunkSize();
    const mutation_avg_chunk_size = deduper.averageChunkSize();
    const mutation_largest_chunk_size = deduper.largestChunkSize();

    std.log.info(
        \\initial used space: {d} KB / {d} MB
        \\initial chunk count: {d}
        \\initial smallest chunk size: {d} KB (note: might be the size of the last chunk, containing the rest)
        \\initial average chunk size: {d} KB
        \\initial largest chunk size: {d} KB
        \\
    , .{
        // bytes to KB: x / 1000
        // bytes to MB: x / 1000000
        initial_used_space / 1000,
        initial_used_space / 1000000,
        initial_chunk_count,
        initial_smallest_chunk_size / 1000,
        initial_avg_chunk_size / 1000,
        initial_largest_chunk_size / 1000,
    });

    std.log.info(
        \\mutation used space: {d} KB / {d} MB
        \\mutation chunk count: {d}
        \\mutation smallest chunk size: {d} KB (note: might be the size of the last chunk, containing the rest)
        \\mutation average chunk size: {d} KB
        \\mutation largest chunk size: {d} KB
    , .{
        mutation_used_space / 1000,
        mutation_used_space / 1000000,
        mutation_chunk_count,
        mutation_smallest_chunk_size / 1000,
        mutation_avg_chunk_size / 1000,
        mutation_largest_chunk_size / 1000,
    });
}
