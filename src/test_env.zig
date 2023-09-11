//! This module provides methods for doing in-memory CDC testing
//! [Released under GNU LGPLv3]
//!
const std = @import("std");
const cdc = @import("cdc.zig");
const Sha256 = std.crypto.hash.sha3.Sha3_256;
const Allocator = std.mem.Allocator;

/// Type generator for in-memory CDC testing
pub fn testingDeduper(comptime data_size: usize) type {
    return struct {
        arena_allocator_keys: std.heap.ArenaAllocator,
        /// Random-generated data to be CDCed
        data: [data_size]u8,
        /// Hashmap containing content hashes and data slices
        storage: std.StringHashMap([]u8),
        desired_chunk_size: usize,
        /// Low-end cut
        minimum_chunk_size: usize,
        /// High-end cut
        maximum_chunk_size: usize,
        mask_s: u32,
        mask_l: u32,

        pub fn init(allocator: Allocator, minimum_chunk_size: usize, desired_chunk_size: usize, maximum_chunk_size: usize) @This() {
            const masks = cdc.generateMasks(desired_chunk_size);
            var random_data: [data_size]u8 = undefined;
            std.crypto.random.bytes(&random_data);

            return @This(){
                .arena_allocator_keys = std.heap.ArenaAllocator.init(allocator),
                .data = random_data,
                .storage = std.StringHashMap([]u8).init(allocator),
                .desired_chunk_size = desired_chunk_size,
                .minimum_chunk_size = minimum_chunk_size,
                .maximum_chunk_size = maximum_chunk_size,
                .mask_s = masks.mask_s,
                .mask_l = masks.mask_l,
            };
        }

        pub fn deinit(self: *@This()) void {
            self.storage.deinit();
            self.arena_allocator_keys.deinit();
        }

        pub fn countChunks(self: @This()) usize {
            return self.storage.count();
        }

        /// Return the amount of bytes currently stored as chunks
        pub fn usedSpace(self: @This()) usize {
            var used_space: usize = 0;
            var storage_iterator = self.storage.valueIterator();

            while (storage_iterator.next()) |value| {
                used_space += value.len;
            }

            return used_space;
        }

        /// Return the average chunk size in bytes
        pub fn averageChunkSize(self: *@This()) usize {
            return @divFloor(self.usedSpace(), self.countChunks());
        }

        /// Return the size of the smallest chunk in bytes
        pub fn smallestChunkSize(self: @This()) usize {
            var smallest: usize = data_size;
            var storage_iterator = self.storage.valueIterator();

            while (storage_iterator.next()) |value| {
                if (value.len < smallest) smallest = value.len;
            }

            return smallest;
        }

        /// Return the size of the largest chunk in bytes
        pub fn largestChunkSize(self: @This()) usize {
            var largest: usize = 0;
            var storage_iterator = self.storage.valueIterator();

            while (storage_iterator.next()) |value| {
                if (largest < value.len) largest = value.len;
            }

            return largest;
        }

        /// Randomly edit one byte in the first half of the random-generated data
        pub fn pointMutation(self: *@This()) void {
            // chose first half to test for boundary-shift problem
            const random_index = std.crypto.random.uintLessThan(usize, @divFloor(data_size, 2));
            self.data[random_index] = std.crypto.random.int(u8);
        }

        /// Convert the data into chunks and store them in the internal HashMap
        pub fn storeChunks(self: *@This()) anyerror!void {
            var chunk_iterator = cdc.ChunkIterator.init(.{
                .desired_chunk_size = self.desired_chunk_size,
                .minimum_chunk_size = self.minimum_chunk_size,
                .maximum_chunk_size = self.maximum_chunk_size,
                .mask_s = self.mask_s,
                .mask_l = self.mask_l,
            });

            for (self.data) |byte| {
                if (chunk_iterator.consume(byte)) |chunk| {
                    try self.storeChunk(chunk);
                }
            }

            if (chunk_iterator.final()) |chunk| {
                try self.storeChunk(chunk);
            }
        }

        /// Store a chunk in the internal HashMap
        fn storeChunk(self: *@This(), chunk: cdc.Chunk) anyerror!void {
            const data_slice = self.data[chunk.offset .. chunk.offset + chunk.length];

            var sha256_hash: [Sha256.digest_length]u8 = undefined;
            Sha256.hash(data_slice, &sha256_hash, .{});

            try self.storage.put(try self.arena_allocator_keys.allocator().dupe(u8, &sha256_hash), data_slice);
        }
    };
}
