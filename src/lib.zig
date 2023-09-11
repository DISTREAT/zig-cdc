//! This library provides structs and functions for doing Content-Defined-Chunking using Gear Hashing
//! [Released under GNU LGPLv3]
//!
pub const Chunk = @import("cdc.zig").Chunk;
pub const ChunkIterator = @import("cdc.zig").ChunkIterator;
pub const ChunkIteratorOptions = @import("cdc.zig").ChunkIteratorOptions;
pub const generateMasks = @import("cdc.zig").generateMasks;
pub const GearHash = @import("gear.zig").GearHash;
