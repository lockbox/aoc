const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day02.txt");

// cube limits
const RED_CUBES: u32 = 12;
const GREEN_CUBES: u32 = 13;
const BLUE_CUBES: u32 = 14;

/// returns id on success
fn part1_line_parse(line: []const u8, red_limit: u32, green_limit: u32, blue_limit: u32) ?u32 {
    const end_game_idx = indexOf(u8, line, ':').?;
    const game_id = parseInt(u8, line[5..end_game_idx], 10) catch return null;

    // iterate over hands
    var iterator = tokenizeSca(u8, line[end_game_idx+1..], ';');
    while (iterator.next()) |hand| {
        var reading_iter = tokenizeSca(u8, hand, ',');
        while (reading_iter.next()) |reading| {
            // get index of the space after the int
            const end_reading_int = indexOf(u8, reading[1..], ' ').? + 1;

            // iterate over the cube readings
            const reading_int = parseInt(u8, reading[1..end_reading_int], 10) catch @panic("reading int");
    
            // now handle the color limits
            const color = reading[end_reading_int + 1..];
            if (startsWith(u8, color, "red")) {
                if (reading_int > red_limit) {
                    return null;
                }
            } else if (startsWith(u8, color, "green")) {
                if (reading_int > green_limit) {
    
                    return null;
                }
            } else if (startsWith(u8, color, "blue")) {
                if (reading_int > blue_limit) {
                    return null;
                }
            } else {
                unreachable;
            }
        }
    }

    return game_id;
}


/// returns id on success
fn part2_line_parse(line: []const u8) u32 {
    const end_game_idx = indexOf(u8, line, ':').?;
    const game_id = parseInt(u8, line[5..end_game_idx], 10) catch @panic("game idx");
    _ = game_id;

    var min_red: u32 = 0;
    var min_blue: u32 = 0;
    var min_green: u32 = 0;

    // iterate over hands
    var iterator = tokenizeSca(u8, line[end_game_idx+1..], ';');
    while (iterator.next()) |hand| {
        var reading_iter = tokenizeSca(u8, hand, ',');
        while (reading_iter.next()) |reading| {
            // get index of the space after the int
            const end_reading_int = indexOf(u8, reading[1..], ' ').? + 1;

            // iterate over the cube readings
            const reading_int = parseInt(u8, reading[1..end_reading_int], 10) catch @panic("reading int");
    
            // now handle the color limits
            const color = reading[end_reading_int + 1..];
            if (startsWith(u8, color, "red")) {
                if (reading_int > min_red) {
                    min_red = reading_int;
                }
            } else if (startsWith(u8, color, "green")) {
                if (reading_int > min_green) {
                    min_green = reading_int;
                }
            } else if (startsWith(u8, color, "blue")) {
                if (reading_int > min_blue) {
                    min_blue = reading_int;
                }
            } else {
                unreachable;
            }
        }
    }

    return min_blue * min_green * min_red;
}

pub fn main() !void {
    var iterator = tokenizeSca(u8, data, '\n');
    var part1_sum: u32 = 0;
    var part2_sum: u32 = 0;

    while (iterator.next()) |line| {
        if  (part1_line_parse(line, RED_CUBES, GREEN_CUBES, BLUE_CUBES)) |id|{
            part1_sum += id;
        }
        part2_sum += part2_line_parse(line);

    }

    print("Part1: {}\n", .{part1_sum});
    print("Part2: {}\n", .{part2_sum});
}

// Useful stdlib functions
const startsWith = std.mem.startsWith;
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
