const std = @import("std");

/// An implementation of the Gear Hash, apparently first suggested in the Ddelta paper
pub const GearHash = struct {
    gear_table: [256]u32,
    fingerprint: u32 = 0,

    /// Initialize the GearTable
    /// The gear_table_seed must be statically defined in order to ensure hash consistency
    pub fn init(gear_table_seed: usize) @This() {
        var gear_table: [256]u32 = undefined;
        var prng = std.rand.DefaultPrng.init(gear_table_seed);
        const random = prng.random();

        // generate random table for a uniform distribution of hashes
        for (&gear_table) |*entry| {
            entry.* = random.int(u32);
        }

        return @This(){
            .gear_table = gear_table,
        };
    }

    /// Consume one bit, rolling of the next byte of the hash
    pub fn consume(self: *@This(), byte: u8) void {
        self.fingerprint = (self.fingerprint << 1) +% self.gear_table[byte];
    }

    /// Return the digest of the current position
    pub fn digest(self: @This()) u32 {
        return self.fingerprint;
    }
};
