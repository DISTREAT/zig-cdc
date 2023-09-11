//! This module provides methods and functions for generating masks and defining the chunk boundaries of data
//! [Released under GNU LGPLv3]
//!
const std = @import("std");
const gear = @import("gear.zig");

/// Generate both a small and large mask as suggested by FastCDC
pub fn generateMasks(desired_chunk_size: usize) struct { mask_s: u32, mask_l: u32 } {
    const bits = @round(@log2(@as(f32, @floatFromInt(desired_chunk_size))));
    const mask_s: u32 = @as(u32, @intFromFloat(@exp2(bits + 1))) - 1;
    const mask_l: u32 = @as(u32, @intFromFloat(@exp2(bits - 1))) - 1;

    return .{
        .mask_s = mask_s,
        .mask_l = mask_l,
    };
}

pub const ChunkIteratorOptions = struct {
    /// The gear table for the rolling hash is pseudo-randomly generated using the provided seed
    /// It is important to note that CDC relies on the digest of the rolling hash.
    /// Thus, changing this value will also change the chunk boundaries
    gear_table_seed: usize = 0,
    /// Desired chunk size in bytes
    desired_chunk_size: usize,
    /// Do not allow boundaries bellow this size in bytes
    minimum_chunk_size: usize,
    /// Force new chunk reaching this size in bytes
    maximum_chunk_size: usize,
    /// Small mask for the hash-judgement function
    mask_s: u32,
    /// Large mask for the hash-judgement function
    mask_l: u32,
};

pub const Chunk = struct {
    /// Digest of the rolling hash for this chunk
    fingerprint: u32,
    /// Starting point of the chunk
    offset: usize,
    /// Size of the chunk in bytes
    length: usize,
};

/// An iterator for defining chunk boundaries within data
pub const ChunkIterator = struct {
    desired_chunk_size: usize,
    minimum_chunk_size: usize,
    maximum_chunk_size: usize,
    mask_s: u32,
    mask_l: u32,
    gear_hash: gear.GearHash,
    offset: usize = 0,
    chunk_size: usize = 0,

    pub fn init(options: ChunkIteratorOptions) ChunkIterator {
        var gear_hash = gear.GearHash.init(options.gear_table_seed);

        return ChunkIterator{
            .desired_chunk_size = options.desired_chunk_size,
            .minimum_chunk_size = options.minimum_chunk_size,
            .maximum_chunk_size = options.maximum_chunk_size,
            .mask_s = options.mask_s,
            .mask_l = options.mask_l,
            .gear_hash = gear_hash,
        };
    }

    /// Consume on byte, returning a Chunk if a boundary is reached
    pub fn consume(self: *ChunkIterator, byte: u8) ?Chunk {
        self.gear_hash.consume(byte);
        self.chunk_size += 1;

        if (self.chunk_size < self.minimum_chunk_size) return null;
        if (self.is_chunk_boundary() or self.chunk_size >= self.maximum_chunk_size) {
            const chunk_size = self.chunk_size;
            self.chunk_size = 0;
            const offset = self.offset;
            self.offset += chunk_size;

            return Chunk{
                .fingerprint = self.gear_hash.digest(),
                .offset = offset,
                .length = chunk_size,
            };
        }

        return null;
    }

    /// The consume function does not know when the stream ends,
    /// hence this function is needed to return the rest as the last Chunk
    pub fn final(self: ChunkIterator) ?Chunk {
        if (self.chunk_size == 0) return null;

        return Chunk{
            .fingerprint = self.gear_hash.digest(),
            .offset = self.offset,
            .length = self.chunk_size,
        };
    }

    /// The so called hash judgment function, calculating if a new boundary is due
    fn is_chunk_boundary(self: ChunkIterator) bool {
        if (self.chunk_size < self.desired_chunk_size) {
            return self.gear_hash.digest() & self.mask_s == 0;
        } else {
            return self.gear_hash.digest() & self.mask_l == 0;
        }
    }
};
