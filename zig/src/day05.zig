const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day05.txt");
const test_data =
    \\seeds: 79 14 55 13
    \\
    \\seed-to-soil map:
    \\50 98 2
    \\52 50 48
    \\
    \\soil-to-fertilizer map:
    \\0 15 37
    \\37 52 2
    \\39 0 15
    \\
    \\fertilizer-to-water map:
    \\49 53 8
    \\0 11 42
    \\42 0 7
    \\57 7 4
    \\
    \\water-to-light map:
    \\88 18 7
    \\18 25 70
    \\
    \\light-to-temperature map:
    \\45 77 23
    \\81 45 19
    \\68 64 13
    \\
    \\temperature-to-humidity map:
    \\0 69 1
    \\1 0 69
    \\
    \\humidity-to-location map:
    \\60 56 37
    \\56 93 4
;

const MappedRange = struct {
    dest: usize,
    source: usize,
    len: usize,

    inline fn maxSource(self: *const MappedRange) usize {
        return self.source + self.len;
    }

    fn lookup(self: *const MappedRange, item: usize) usize {
        if (item >= self.source and item < self.maxSource()) {
            const delta = item - self.source;
            return self.dest + delta;
        }

        return item;
    }
};

fn cmpBySourceAddress(context: void, a: MappedRange, b: MappedRange) bool {
    return std.sort.asc(usize)(context, a.source, b.source);
}

const RangeTable = struct {
    ranges: List(MappedRange),

    fn init(alloc: std.mem.Allocator) RangeTable {
        return RangeTable{
            .ranges = List(MappedRange).init(alloc),
        };
    }

    fn deinit(self: *RangeTable) void {
        self.ranges.deinit();
        self.* = undefined;
    }

    fn addRange(self: *RangeTable, r: MappedRange) !void {
        try self.ranges.append(r);
    }

    fn sort(self: *RangeTable) void {
        std.sort.heap(MappedRange, self.ranges.items, {}, cmpBySourceAddress);
    }

    fn lookup(self: *const RangeTable, n: usize) usize {
        for (self.ranges.items) |map| {
            // because the list is sorted, if `n` is below
            // the first range, then it will lookup and
            // return `n`
            if (n < map.maxSource()) {
                return map.lookup(n);
            }
        } else {
            // if nothing matches, then maps to `n`
            return n;
        }
    }
};

const Puzzle = struct {
    seeds: List(usize),
    seed_soil: RangeTable,
    soil_fert: RangeTable,
    fert_water: RangeTable,
    water_light: RangeTable,
    light_temp: RangeTable,
    temp_humid: RangeTable,
    humid_loc: RangeTable,

    /// sorts all the lists of ranges by their
    /// source address, allows for binary search lookup
    fn sort(self: *Puzzle) void {
        self.seed_soil.sort();
        self.soil_fert.sort();
        self.fert_water.sort();
        self.water_light.sort();
        self.light_temp.sort();
        self.temp_humid.sort();
        self.humid_loc.sort();
    }

    fn init(alloc: std.mem.Allocator) Puzzle {
        return Puzzle{
            .seeds = List(usize).init(alloc),
            .seed_soil = RangeTable.init(alloc),
            .soil_fert = RangeTable.init(alloc),
            .fert_water = RangeTable.init(alloc),
            .water_light = RangeTable.init(alloc),
            .light_temp = RangeTable.init(alloc),
            .temp_humid = RangeTable.init(alloc),
            .humid_loc = RangeTable.init(alloc),
        };
    }

    fn deinit(self: *Puzzle) void {
        self.seeds.deinit();
        self.seed_soil.deinit();
        self.soil_fert.deinit();
        self.fert_water.deinit();
        self.water_light.deinit();
        self.light_temp.deinit();
        self.temp_humid.deinit();
        self.humid_loc.deinit();
        self.* = undefined;
    }

    const LookupType = enum {
        seed_soil,
        soil_fert,
        fert_water,
        water_light,
        light_temp,
        temp_humid,
        humid_loc,
    };

    /// Performs the lookup in the desired table
    inline fn lookup(self: *const Puzzle, lookup_variant: LookupType, n: usize) usize {
        return switch (lookup_variant) {
            .seed_soil => self.seed_soil.lookup(n),
            .soil_fert => self.soil_fert.lookup(n),
            .fert_water => self.fert_water.lookup(n),
            .water_light => self.water_light.lookup(n),
            .light_temp => self.light_temp.lookup(n),
            .temp_humid => self.temp_humid.lookup(n),
            .humid_loc => self.humid_loc.lookup(n),
        };
    }
};

fn parseRangeTable(iter: *std.mem.TokenIterator(u8, .scalar)) !RangeTable {
    var table = RangeTable.init(gpa);
    // each line should have 3 base 10 integers,
    // when we cannot parse the first integer, pack
    // up what we have into the single RangeTable and
    // return
    while (iter.next()) |line| {
        var num_iterator = tokenizeSca(u8, line, ' ');

        // when we cannot parse `num1`, the loop is over
        const num1 = parseInt(usize, num_iterator.next().?, 10) catch break;
        const num2 = try parseInt(usize, num_iterator.next().?, 10);
        const num3 = try parseInt(usize, num_iterator.next().?, 10);

        try table.addRange(MappedRange{
            .dest = num1,
            .source = num2,
            .len = num3,
        });
    }

    return table;
}

fn input_to_puzzle(d: []const u8) !Puzzle {
    var seeds = List(usize).init(gpa);
    var iterator = tokenizeSca(u8, d, '\n');

    // parse seeds
    var seed_line_slice: []const u8 = iterator.next().?;
    const seeds_start_idx: usize = 1 + indexOf(u8, seed_line_slice, ':').?;
    var seeds_iterator = tokenizeSca(u8, seed_line_slice[seeds_start_idx..], ' ');
    while (seeds_iterator.next()) |seed_text| {
        try seeds.append(try parseInt(usize, seed_text, 10));
    }

    _ = iterator.next().?;
    // parse seed-to-soil map
    const seed_soil = try parseRangeTable(&iterator);

    // parse soil-to-fetilizer map
    const soil_fert = try parseRangeTable(&iterator);

    // parse fartilizer-to-water map
    const fert_water = try parseRangeTable(&iterator);

    // parse water-to-light map
    const water_light = try parseRangeTable(&iterator);

    // parse light-to-temperature map
    const light_temp = try parseRangeTable(&iterator);

    // parse temperature-to-humidity map
    const temp_humid = try parseRangeTable(&iterator);

    // parse humidity-to-location map
    const humid_loc = try parseRangeTable(&iterator);

    var p = Puzzle{
        .seeds = seeds,
        .seed_soil = seed_soil,
        .soil_fert = soil_fert,
        .fert_water = fert_water,
        .water_light = water_light,
        .light_temp = light_temp,
        .temp_humid = temp_humid,
        .humid_loc = humid_loc,
    };

    p.sort();
    return p;
}

inline fn seedToLoc(p: *const Puzzle, seed: usize) usize {
    //print("$ Seed `{}`\n", .{seed});
    const soil = p.lookup(.seed_soil, seed);
    //print("\tSoil: `{}`\n", .{soil});
    const fert = p.lookup(.soil_fert, soil);
    //print("\tFert: `{}`\n", .{fert});
    const water = p.lookup(.fert_water, fert);
    //print("\tWater: `{}`\n", .{water});
    const light = p.lookup(.water_light, water);
    //print("\tLight: `{}`\n", .{light});
    const temp = p.lookup(.light_temp, light);
    //print("\tTemp: `{}`\n", .{temp});
    const humid = p.lookup(.temp_humid, temp);
    //print("\tHumid: `{}`\n", .{humid});
    const loc = p.lookup(.humid_loc, humid);
    //print("\tLoc: `{}`\n", .{loc});
    return loc;
}

fn part1(p: *const Puzzle) !usize {
    var smallest_location: usize = 0xFFFF_FFFF_FFFF_FFFF;

    // check all the seeds to see who gets the smallest location
    for (p.seeds.items) |seed| {
        const loc = seedToLoc(p, seed);
        if (loc < smallest_location) {
            //print("!! new smallest loc: `{}` over `{}`\n", .{ loc, smallest_location });
            smallest_location = loc;
        }
    }

    return smallest_location;
}

fn part2(p: *const Puzzle) !usize {
    var small: usize = 0xFFFF_FFFF_FFFF_FFFF;

    const num_pairs = p.seeds.items.len / 2;
    print("`{}` seed pairs\n", .{num_pairs});

    for (0..num_pairs) |pair_base| {
        const idx_loc = pair_base * 2;
        const size_loc = idx_loc + 1;
        const base = p.seeds.items[idx_loc];
        const size = p.seeds.items[size_loc];
        var idx: usize = 0;
        print("[Pair {}]: `{}` iterations\n", .{ pair_base, size });

        // go from base -> base + size
        while (idx < size) : (idx += 1) {
            const seed_num = base + idx;

            const loc = seedToLoc(p, seed_num);
            if (loc < small) {
                small = loc;
            }
        }
    }

    return small;
}

pub fn main() !void {
    var test_puzzle_input = try input_to_puzzle(test_data);
    defer test_puzzle_input.deinit();
    var real_puzzle_input = try input_to_puzzle(data);
    defer real_puzzle_input.deinit();

    print("[Test Data] Part1: `{}`\n", .{try part1(&test_puzzle_input)});
    print("[Real Data] Part1: `{}`\n", .{try part1(&real_puzzle_input)});
    print("[Test Data] Part2: `{}`\n", .{try part2(&test_puzzle_input)});
    print("[Real Data] Part2: `{}`\n", .{try part2(&real_puzzle_input)});
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
