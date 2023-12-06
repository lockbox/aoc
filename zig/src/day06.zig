const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const DATA = @embedFile("data/day06.txt");
const TEST_DATA =
    \\Time:      7  15   30
    \\Distance:  9  40  200
;

const Race = struct {
    time: usize,
    distance: usize,
};

const ValidHoldRange = struct {
    start: usize = 1,
    end: usize,
};

inline fn validHoldTimes(time: usize) ValidHoldRange {
    return .{ .start = 1, .end = time };
}

fn getPart1Races(data: []const u8) !std.MultiArrayList(Race) {
    var races = std.MultiArrayList(Race){};

    var iterator = tokenizeSca(u8, data, '\n');
    var line_time_slice = iterator.next().?;
    var line_dist_slice = iterator.next().?;

    const time_line_start = 1 + indexOf(u8, line_time_slice, ':').?;
    const dist_line_start = 1 + indexOf(u8, line_dist_slice, ':').?;

    var time_iterator = tokenizeSca(u8, line_time_slice[time_line_start..], ' ');
    var dist_iterator = tokenizeSca(u8, line_dist_slice[dist_line_start..], ' ');

    while (time_iterator.next()) |time_slice| {
        const dist_slice = dist_iterator.next().?;

        const time = try parseInt(usize, time_slice, 10);
        const dist = try parseInt(usize, dist_slice, 10);

        try races.append(gpa, Race{
            .time = time,
            .distance = dist,
        });
    }

    return races;
}

inline fn holdTimeToDist(hold: usize, time: usize) usize {
    const go_time = time - hold;

    return go_time * hold;
}

fn part1(data: []const u8) !usize {
    var races = try getPart1Races(data);
    defer races.deinit(gpa);

    var total_winning: usize = 1;

    for (races.items(.time), races.items(.distance)) |time, dist| {
        const time_range = validHoldTimes(time);
        var winning: usize = 0;

        for (time_range.start..time_range.end) |hold_time| {
            const travelled = holdTimeToDist(hold_time, time);

            if (travelled > dist) {
                winning += 1;
            }
        }

        total_winning *= winning;
    }

    return total_winning;
}

fn getPart2Races(data: []const u8) !std.MultiArrayList(Race) {
    var races = std.MultiArrayList(Race){};

    var iterator = tokenizeSca(u8, data, '\n');
    var line_time_slice = iterator.next().?;
    var line_dist_slice = iterator.next().?;

    const time_line_start = 1 + indexOf(u8, line_time_slice, ':').?;
    const dist_line_start = 1 + indexOf(u8, line_dist_slice, ':').?;

    var time_iterator = tokenizeSca(u8, line_time_slice[time_line_start..], ' ');
    var dist_iterator = tokenizeSca(u8, line_dist_slice[dist_line_start..], ' ');

    var total_time: usize = 0;
    var total_dist: usize = 0;
    while (time_iterator.next()) |time_slice| {
        const dist_slice = dist_iterator.next().?;

        const time = try parseInt(usize, time_slice, 10);
        const dist = try parseInt(usize, dist_slice, 10);

        const time_size = time_slice.len;
        const dist_size = dist_slice.len;

        total_time *= std.math.pow(usize, 10, time_size);
        total_dist *= std.math.pow(usize, 10, dist_size);

        total_time += time;
        total_dist += dist;
    }

    try races.append(gpa, Race{
        .time = total_time,
        .distance = total_dist,
    });

    return races;
}

fn part2(data: []const u8) !usize {
    var races = try getPart2Races(data);
    defer races.deinit(gpa);

    var total_winning: usize = 1;

    for (races.items(.time), races.items(.distance)) |time, dist| {
        const time_range = validHoldTimes(time);
        var winning: usize = 0;

        for (time_range.start..time_range.end) |hold_time| {
            const travelled = holdTimeToDist(hold_time, time);

            if (travelled > dist) {
                winning += 1;
            }
        }

        total_winning *= winning;
    }

    return total_winning;
}

pub fn main() !void {
    print("[Test Data] Part1: `{}`\n", .{try part1(TEST_DATA)});
    print("[Real Data] Part1: `{}`\n", .{try part1(DATA)});
    print("[Test Data] Part2: `{}`\n", .{try part2(TEST_DATA)});
    print("[Real Data] Part2: `{}`\n", .{try part2(DATA)});
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
