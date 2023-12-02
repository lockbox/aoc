const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day01.txt");
const alphaLower = "abcdefghijklmnopqrstuvwxyz";
const alphaUpper = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
const alpha = alphaLower ++ alphaUpper;

fn line_to_value(line: []const u8) !u32 {
    var digits: [2]u8 = [_]u8{ 0, 0 };
    var found = false;

    for (line) |c| {
        if (c >= '0' and c <= '9') {
            // has the first been set
            if (!found) {
                digits[0] = c;
                found = true;
            }
            // set the last
            digits[1] = c;
        }
    }

    return try parseInt(u8, &digits, 10);
}

fn part1_counter(s: []const u8) !u32 {
    var out: u32 = 0;
    var iterator = tokenizeSca(u8, s, '\n');
    while (iterator.next()) |line| {
        // find first int digit
        // find last int digit
        // combine digits into u8[2]
        // parse u8[2] into integer
        // add result to out
        const calibration_sum = line_to_value(line) catch break;
        out = out + calibration_sum;
    }
    return out;
}

fn part1() !void {
    print("Part1 (old): {}\n", .{try part1_counter(data)});
}

fn counter_new(input: []const u8) !u32 {
    var out: u32 = 0;
    var iterator = tokenizeSca(u8, input, '\n');

    while (iterator.next()) |line| {
        for (0..line.len) |i| {
            if (get_number(line[i..])) |n| {
                out += 10 * n;
                break;
            }
        }

        var tmp_idx: usize = line.len - 1;
        while (tmp_idx >= 0) : (tmp_idx -= 1) {
            if (get_number(line[tmp_idx..])) |n| {
                out += n;
                break;
            }
        }
    }

    return out;
}

fn get_number(piece: []const u8) ?u32 {
    // easy ascii dec case
    if (piece[0] >= '0' and piece[0] <= '9') {
        return @intCast(piece[0] - '0');
    }

    // wasn't in ascii dec, so look for ascii words
    if (std.mem.startsWith(u8, piece, "one")) {
        return 1;
    } else if (std.mem.startsWith(u8, piece, "two")) {
        return 2;
    } else if (std.mem.startsWith(u8, piece, "three")) {
        return 3;
    } else if (std.mem.startsWith(u8, piece, "four")) {
        return 4;
    } else if (std.mem.startsWith(u8, piece, "five")) {
        return 5;
    } else if (std.mem.startsWith(u8, piece, "six")) {
        return 6;
    } else if (std.mem.startsWith(u8, piece, "seven")) {
        return 7;
    } else if (std.mem.startsWith(u8, piece, "eight")) {
        return 8;
    } else if (std.mem.startsWith(u8, piece, "nine")) {
        return 9;
    } else {
        return null;
    }
}

pub fn main() !void {
    try part1();
    print("Part1 (new): {}\n", .{try counter_new(data)});
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
