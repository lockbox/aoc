const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const DATA = @embedFile("data/day13.txt");
const TEST_DATA =
    \\#.##..##.
    \\..#.##.#.
    \\##......#
    \\##......#
    \\..#.##.#.
    \\..##..##.
    \\#.#.##.#.
    \\
    \\#...##..#
    \\#....#..#
    \\..##..###
    \\#####.##.
    \\#####.##.
    \\..##..###
    \\#....#..#
;

const Pattern = struct {
    rows: List([]u8),

    fn init(alloc: std.mem.Allocator) Pattern {
        return Pattern{ .rows = List([]u8).init(alloc) };
    }

    fn deinit(self: *Pattern) void {
        for (self.rows.items) |row| {
            gpa.free(row);
        }
        self.rows.deinit();
        self.* = undefined;
    }

    fn fromData(data: []const u8) !Pattern {
        var pattern = Pattern.init(gpa);
        var iterator = tokenizeSca(u8, data, '\n');

        while (iterator.next()) |line| {
            const s = try gpa.dupe(u8, line);
            try pattern.rows.append(s);
        }

        return pattern;
    }

    // return the index to the left of the reflection
    fn verticalReflection(self: *const Pattern, errors: usize) ?usize {
        var col_idx: usize = 0;
        var delta_col: usize = 0;
        const row_len: usize = self.rows.items[0].len;

        // iterate over each row as a "base" row
        while (col_idx < row_len - 1) : (col_idx += 1) {
            delta_col = 0;
            var diff_count: usize = 0;

            // max delta is # rows - current row offset, minus the minimum
            // 2 rows required
            const row_len_isize: isize = @intCast(row_len);
            const col_idx_isize: isize = @intCast(col_idx);
            const delta_col_max: usize = @intCast(@min(col_idx_isize, row_len_isize - col_idx_isize - 2));

            // iterate starting at [row, row + 1] expanding outward
            // looking to see if the row differences are within
            // the threshold
            while (delta_col <= delta_col_max) : (delta_col += 1) {
                const cola = col_idx - delta_col;
                const colb = col_idx + 1 + delta_col;

                // calculate the # of different elements
                for (0..self.rows.items.len) |i| {
                    const row = self.rows.items[i];

                    if (row[cola] != row[colb]) {
                        diff_count += 1;
                    }
                }
            }

            // check if all the rows matched w/in bounds
            if (diff_count == errors) {
                return col_idx;
            }
        }

        return null;
    }

    // return the index above the reflection
    fn horizontalReflection(self: *const Pattern, errors: usize) ?usize {
        var row_idx: usize = 0;
        var delta_row: usize = 0;
        const pattern_len: usize = self.rows.items.len;

        // iterate over each row as a "base" row
        while (row_idx < pattern_len - 1) : (row_idx += 1) {
            delta_row = 0;
            var diff_count: usize = 0;

            // max delta is # rows - current row offset, minus the minimum
            // 2 rows required
            const pattern_len_isize: isize = @intCast(pattern_len);
            const row_idx_isize: isize = @intCast(row_idx);
            const delta_row_max: usize = @intCast(@min(row_idx_isize, pattern_len_isize - row_idx_isize - 2));

            // iterate starting at [row, row + 1] expanding outward
            // looking to see if the row differences are within
            // the threshold
            while (delta_row <= delta_row_max) : (delta_row += 1) {
                const rowa = self.rows.items[row_idx - delta_row];
                const rowb = self.rows.items[row_idx + 1 + delta_row];

                // calculate the # of different elements
                for (0..rowa.len) |i| {
                    if (rowa[i] != rowb[i]) {
                        diff_count += 1;
                    }
                }
            }

            // check if all matched w/in bounds
            if (diff_count == errors) {
                return row_idx;
            }
        }

        return null;
    }

    fn reflectionPoints(self: *const Pattern, errors: usize) usize {
        var points: usize = 0;
        const horizontal_scale = 100;

        const h_reflection = self.horizontalReflection(errors);
        const v_reflection = self.verticalReflection(errors);

        if (h_reflection) |horizontal_points| {
            points += horizontal_scale * (horizontal_points + 1);
        } else {
            // vert reflection is bigger
            points += v_reflection.? + 1;
        }

        return points;
    }
};

const Puzzle = struct {
    patterns: List(Pattern),

    fn init(alloc: std.mem.Allocator) Puzzle {
        return Puzzle{
            .patterns = List(Pattern).init(alloc),
        };
    }

    fn deinit(self: *Puzzle) void {
        for (0..self.patterns.items.len) |idx| {
            self.patterns.items[idx].deinit();
        }
        self.patterns.deinit();
        self.* = undefined;
    }

    fn fromData(data: []const u8) !Puzzle {
        var puzzle = Puzzle.init(gpa);
        var pattern_iterator = tokenizeSeq(u8, data, "\n\n"); // each pattern is separated by blank
        while (pattern_iterator.next()) |pattern_data| {
            const pattern = try Pattern.fromData(pattern_data);
            try puzzle.patterns.append(pattern);
        }

        return puzzle;
    }
};

fn part1(p: *const Puzzle) !usize {
    var total: usize = 0;

    for (p.patterns.items) |pat| {
        total += pat.reflectionPoints(0);
    }

    return total;
}

fn part2(p: *const Puzzle) !usize {
    var total: usize = 0;

    for (p.patterns.items) |pat| {
        total += pat.reflectionPoints(1);
    }

    return total;
}
pub fn main() !void {
    var TEST_PUZZLE = try Puzzle.fromData(TEST_DATA);
    defer TEST_PUZZLE.deinit();
    var REAL_PUZZLE = try Puzzle.fromData(DATA);
    defer REAL_PUZZLE.deinit();
    print("[Test Data]: Part1: `{}`\n", .{try part1(&TEST_PUZZLE)});
    print("[Real Data]: Part1: `{}`\n", .{try part1(&REAL_PUZZLE)});
    print("[Test Data]: Part2: `{}`\n", .{try part2(&TEST_PUZZLE)});
    print("[Real Data]: Part2: `{}`\n", .{try part2(&REAL_PUZZLE)});
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
