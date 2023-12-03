const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day03.txt");

const Number = struct {
    x: usize,
    len: usize,
    y: usize,
    value: usize,

    /// Any idx in:
    /// x: [max(x-1, 0), min(x+len + 1)]
    /// y: [max(y-1, 0)] U [y+1]
    fn isPart1Part(self: *const Number, map: *const PartMap) bool {
        const min_x: usize = switch (self.x) {
            0 => 0,
            else => self.x - 1,
        };
        const max_x = self.x + self.len + 1;

        if (self.y > 0) {
            // check the previous row
            for (min_x..max_x) |x_val| {
                if (map.symbolExists(x_val, self.y - 1)) {
                    return true;
                }
            }
        }

        // check current row
        for (min_x..max_x) |x_val| {
            if (map.symbolExists(x_val, self.y)) {
                return true;
            }
        }

        // check next row
        for (min_x..max_x) |x_val| {
            if (map.symbolExists(x_val, self.y + 1)) {
                return true;
            }
        }

        return false;
    }

    fn addGearRef(self: *const Number, map: *PartMap) !void {
        const min_x: usize = switch (self.x) {
            0 => 0,
            else => self.x - 1,
        };
        const max_x = self.x + self.len + 1;

        if (self.y > 0) {
            // check the previous row
            for (min_x..max_x) |x_val| {
                try map.addGearRef(x_val, self.y - 1, self.value);
            }
        }

        // check current row
        for (min_x..max_x) |x_val| {
            try map.addGearRef(x_val, self.y, self.value);
        }

        // check next row
        for (min_x..max_x) |x_val| {
            try map.addGearRef(x_val, self.y + 1, self.value);
        }
    }
};

const Location = struct {
    x: usize,
    y: usize,
};

const PartMap = struct {
    /// Map<(x,y), symbol>
    symbols: Map(Location, u8),
    numbers: List(Number),
    gear_refs: Map(Location, List(usize)),

    const Self = @This();

    fn init(allocator: std.mem.Allocator) !Self {
        const s = Map(Location, u8).init(allocator);
        const n = List(Number).init(allocator);
        const g = Map(Location, List(usize)).init(allocator);

        return Self{
            .symbols = s,
            .numbers = n,
            .gear_refs = g,
        };
    }

    fn symbolExists(self: *const PartMap, x: usize, y: usize) bool {
        return self.symbols.contains(Location{ .x = x, .y = y });
    }

    fn isGear(self: *const PartMap, x: usize, y: usize) bool {
        if (self.symbols.get(Location{ .x = x, .y = y })) |val| {
            if (val == '*') {
                return true;
            }
        }

        return false;
    }

    fn addGearRef(self: *PartMap, x: usize, y: usize, value: usize) !void {
        if (self.isGear(x, y)) {
            const result = try self.gear_refs.getOrPut(Location{ .x = x, .y = y });

            if (result.found_existing == true) {
                try result.value_ptr.*.append(value);
            } else {
                var l = List(usize).init(gpa);
                try l.append(value);
                result.value_ptr.* = l;
            }
        }
    }

    fn deinit(self: *Self) void {
        self.symbols.deinit();
        self.numbers.deinit();

        var iter = self.gear_refs.valueIterator();
        while (iter.next()) |v| {
            v.deinit();
        }
        self.gear_refs.deinit();
        self.* = undefined;
    }

    fn addSymbol(self: *Self, x: usize, y: usize, s: u8) !void {
        _ = try self.symbols.put(Location{ .x = x, .y = y }, s);
    }

    fn addNumber(self: *Self, num: Number) !void {
        try self.numbers.append(num);
    }

    fn gearRatioSum(self: *Self) !usize {
        var total: usize = 0;

        // add the gear xrefs from part -> sym
        for (self.numbers.items) |num| {
            if (num.isPart1Part(self)) {
                try num.addGearRef(self);
            }
        }

        // for all the values in the gear_refs
        var iter = self.gear_refs.valueIterator();
        while (iter.next()) |ref_list| {
            if (ref_list.items.len == 2) {
                total += (ref_list.items[0] * ref_list.items[1]);
            }
        }

        return total;
    }

    fn part1Sum(self: *const Self) usize {
        var total: usize = 0;
        for (self.numbers.items) |num| {
            if (num.isPart1Part(self)) {
                total += num.value;
            }
        }

        return total;
    }

    fn buildMap(m: *PartMap, lines: []const u8) !void {
        var start_x: ?usize = null;
        var iterator = splitSca(u8, lines, '\n');
        var y: u32 = 0;
        while (iterator.next()) |line| {
            for (0..line.len) |x| {
                const i: u8 = line[x];
                // found a digit
                if (i >= '0' and i <= '9') {
                    // update state
                    if (start_x == null) {
                        start_x = x;
                    }

                    // if we're @ the end of the line, make a
                    // new number
                    if (x == line.len - 1) {
                        try m.addNumber(Number{
                            .x = start_x.?,
                            .y = y,
                            .len = (x + 1) - start_x.?,
                            .value = try parseInt(usize, line[start_x.? .. x + 1], 10),
                        });
                        start_x = null;
                    }
                } else {
                    // did not find digit. so finish
                    // making the number if we are in progress,
                    // then make the next item

                    // if we are in progress, then finish the number
                    if (start_x) |num_start| {
                        try m.addNumber(Number{
                            .x = num_start,
                            .y = y,
                            .len = x - num_start,
                            .value = try parseInt(usize, line[num_start..x], 10),
                        });
                        start_x = null;
                    }

                    // now that we've cleaned up the number, make the
                    // item or new space
                    if (i == '.') {
                        // found empty space
                    } else {

                        // found a symbol
                        try m.addSymbol(x, y, i);
                    }
                }
            }

            // increase counters
            y += 1;
        }
    }
};

pub fn part1() !void {
    const alloc = gpa;
    var m: PartMap = try PartMap.init(alloc);
    defer m.deinit();

    try m.buildMap(data);
    const sum = m.part1Sum();

    print("Part1: `{}`\n", .{sum});
}

pub fn part2() !void {
    const alloc = gpa;
    var m: PartMap = try PartMap.init(alloc);
    defer m.deinit();

    try m.buildMap(data);
    const sum = try m.gearRatioSum();

    print("Part2: `{}`\n", .{sum});
}

pub fn main() !void {
    try part1();
    try part2();
}

// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
