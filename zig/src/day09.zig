const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const DATA = @embedFile("data/day09.txt");
const TEST_DATA =
    \\0 3 6 9 12 15
    \\1 3 6 10 15 21
    \\10 13 16 21 30 45
;

fn calculateNextRecursive(xs: *List(isize)) isize {
    // check for base case (all == 0)
    for (xs.items) |x| {
        if (x != 0) break;
    } else {
        return 0;
    }
    // normal case, make a list of the derivative
    var ys = List(isize).init(gpa);
    defer ys.deinit();

    var idx: usize = 1;
    while (idx < xs.items.len) {
        const delta = xs.items[idx] - xs.items[idx - 1];
        ys.append(delta) catch @panic("oom");

        // inc
        idx += 1;
    }

    return ys.items[ys.items.len - 1] + calculateNextRecursive(&ys);
}

fn part1(data: []const u8) !isize {
    var iterator = tokenizeSca(u8, data, '\n');
    var sum: isize = 0;

    while (iterator.next()) |line| {
        var numbers = List(isize).init(gpa);
        defer numbers.deinit();

        var num_iterator = tokenizeSca(u8, line, ' ');
        while (num_iterator.next()) |num_ascii| {
            try numbers.append(try parseInt(isize, num_ascii, 10));
        }

        // now calulate the next item in the sequence
        const line_next = calculateNextRecursive(&numbers);
        sum += line_next + numbers.items[numbers.items.len - 1];
    }

    return sum;
}

fn calculatePrevRecursive(xs: *List(isize)) isize {
    // check for base case (all == 0)
    for (xs.items) |x| {
        if (x != 0) break;
    } else {
        return 0;
    }

    // normal case, make a list of the derivative
    var ys = List(isize).init(gpa);
    defer ys.deinit();

    var idx: usize = xs.items.len - 1;
    while (idx > 0) {
        const delta = xs.items[idx] - xs.items[idx - 1];
        ys.insert(0, delta) catch @panic("oom");

        // inc
        idx -= 1;
    }

    return ys.items[0] - calculatePrevRecursive(&ys);
}

fn part2(data: []const u8) !isize {
    var iterator = tokenizeSca(u8, data, '\n');
    var sum: isize = 0;

    while (iterator.next()) |line| {
        var numbers = List(isize).init(gpa);
        defer numbers.deinit();

        var num_iterator = tokenizeSca(u8, line, ' ');
        while (num_iterator.next()) |num_ascii| {
            const num = try parseInt(isize, num_ascii, 10);
            try numbers.append(num);
        }

        // now calulate the next item in the sequence
        const line_prev = calculatePrevRecursive(&numbers);
        sum += numbers.items[0] - line_prev;
    }

    return sum;
}

pub fn main() !void {
    print("[Test Data]: Part1: `{}`\n", .{try part1(TEST_DATA)});
    print("[Real Data]: Part1: `{}`\n", .{try part1(DATA)});
    print("[Test Data]: Part2: `{}`\n", .{try part2(TEST_DATA)});
    print("[Real Data]: Part2: `{}`\n", .{try part2(DATA)});
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
