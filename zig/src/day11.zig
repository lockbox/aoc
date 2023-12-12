const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const DATA = @embedFile("data/day11.txt");
const TEST_DATA =
    \\...#......
    \\.......#..
    \\#.........
    \\..........
    \\......#...
    \\.#........
    \\.........#
    \\..........
    \\.......#..
    \\#...#.....
;

const Coor = struct {
    x: usize,
    y: usize,
};

const Puzzle = struct {
    rows: List([]const u8),
    expanded_rows: List([]const u8),
    locations: List(Coor),
    search_points: Map(Coor, List(Coor)),
    marked_cols: List(usize),
    marked_rows: List(usize),

    fn init(alloc: std.mem.Allocator) Puzzle {
        return Puzzle{
            .rows = List([]const u8).init(alloc),
            .expanded_rows = List([]const u8).init(alloc),
            .locations = List(Coor).init(alloc),
            .search_points = Map(Coor, List(Coor)).init(gpa),
            .marked_cols = List(usize).init(alloc),
            .marked_rows = List(usize).init(alloc),
        };
    }

    fn deinit(self: *Puzzle) void {
        self.locations.deinit();
        for (self.rows.items) |r| {
            gpa.free(r);
        }
        self.rows.deinit();

        for (self.expanded_rows.items) |r| {
            gpa.free(r);
        }
        self.expanded_rows.deinit();
        self.* = undefined;
    }

    fn fromPart1Data(self: *Puzzle, data: []const u8) !void {
        var iterator = tokenizeSca(u8, data, '\n');

        // copy the rows
        while (iterator.next()) |line| {
            const row = try gpa.alloc(u8, line.len);
            @memcpy(row, line);
            try self.rows.append(row);
        }

        // now expand
        try self.expand();

        // now find coordinates
        for (self.expanded_rows.items, 0..) |row, y| {
            for (row, 0..) |c, x| {
                if (c == '#') {
                    try self.locations.append(Coor{ .x = x, .y = y });
                }
            }
        }
    }

    fn markExpand(self: *Puzzle) !void {
        for (self.rows.items, 0..) |row, idx| {
            for (row) |c| {
                if (c != '.') break;
            } else {
                try self.marked_rows.append(idx);
            }
        }

        // now iterate column wise through all the rows
        for (0..self.rows.items[0].len) |col_idx| {
            for (self.rows.items) |row| {
                if (row[col_idx] != '.') break;
            } else {
                try self.marked_cols.append(col_idx);
            }
        }
    }

    fn fromPart2Data(self: *Puzzle, data: []const u8) !void {
        var iterator = tokenizeSca(u8, data, '\n');

        // copy the rows
        while (iterator.next()) |line| {
            const row = try gpa.alloc(u8, line.len);
            @memcpy(row, line);
            try self.rows.append(row);
        }

        // now expand
        try self.markExpand();

        // now find coordinates
        for (self.rows.items, 0..) |row, y| {
            for (row, 0..) |c, x| {
                if (c == '#') {
                    try self.locations.append(Coor{ .x = x, .y = y });
                }
            }
        }
    }

    fn colsInRange(self: *Puzzle, start: usize, end: usize) usize {
        var total: usize = 0;
        for (self.marked_cols.items) |col| {
            if (col > end) break;

            if (col > start and col < end) {
                total += 1;
            }
        }

        return total;
    }

    fn rowsInRange(self: *Puzzle, start: usize, end: usize) usize {
        var total: usize = 0;
        for (self.marked_rows.items) |row| {
            if (row > end) break;

            if (row > start and row < end) {
                total += 1;
            }
        }

        return total;
    }

    fn markedManhattan(self: *Puzzle, a: *const Coor, b: *const Coor) usize {
        const x_start = @min(a.x, b.x);
        const x_end = @max(a.x, b.x);
        const y_start = @min(a.y, b.y);
        const y_end = @max(a.y, b.y);

        const col_modifier = self.colsInRange(x_start, x_end);
        const row_modifier = self.rowsInRange(y_start, y_end);

        const modifier_scale = 1_000_000;
        const a_x = increaseModifier(a.x, b.x, modifier_scale, col_modifier);
        const b_x = increaseModifier(b.x, a.x, modifier_scale, col_modifier);
        const a_y = increaseModifier(a.y, b.y, modifier_scale, row_modifier);
        const b_y = increaseModifier(b.y, a.y, modifier_scale, row_modifier);
        //
        const scaled_a = Coor{ .x = a_x, .y = a_y };
        const scaled_b = Coor{ .x = b_x, .y = b_y };
        const mhtn = manhattanCoord(&scaled_a, &scaled_b);

        return mhtn;
    }

    fn addPairInner(self: *Puzzle, a: *const Coor, b: *const Coor) !void {
        var result = try self.search_points.getOrPut(Coor{ .x = a.x, .y = a.y });
        const b_coor = Coor{ .x = b.x, .y = b.y };
        if (result.found_existing) {
            try result.value_ptr.append(b_coor);
        } else {
            result.value_ptr.* = List(Coor).init(gpa);
            try result.value_ptr.append(b_coor);
        }
    }

    fn addCoorPair(self: *Puzzle, a: *const Coor, b: *const Coor) !void {
        try self.addPairInner(a, b);
        try self.addPairInner(b, a);
    }

    fn containsPairInner(self: *const Puzzle, a: *const Coor, b: *const Coor) bool {
        if (self.search_points.contains(a.*)) {
            const val = self.search_points.getEntry(a.*).?;
            const list = val.value_ptr;

            for (list.items) |c| {
                if (c.x == b.x and c.y == b.y) {
                    return true;
                }
            }
        }

        return false;
    }

    fn containsPair(self: *const Puzzle, a: *const Coor, b: *const Coor) bool {
        const found = self.containsPairInner(a, b) or self.containsPairInner(b, a);
        return found;
    }

    fn part1Distances(self: *Puzzle) !usize {
        var total: usize = 0;
        var num_added: usize = 0;
        for (self.locations.items) |start_loc| {
            for (self.locations.items) |dest_loc| {
                if (start_loc.x == dest_loc.x and start_loc.y == dest_loc.y) continue;
                if (self.containsPair(&start_loc, &dest_loc)) {
                    continue;
                }

                num_added += 1;

                // we havent already calculated this pair
                total += manhattanCoord(&start_loc, &dest_loc);

                // add to seen
                try self.addCoorPair(&start_loc, &dest_loc);
            }
        }

        print("Added: `{}`\n", .{num_added});

        return total;
    }

    fn part2Distances(self: *Puzzle) !usize {
        var total: usize = 0;
        var num_added: usize = 0;
        for (self.locations.items) |start_loc| {
            for (self.locations.items) |dest_loc| {
                if (start_loc.x == dest_loc.x and start_loc.y == dest_loc.y) continue;
                if (self.containsPair(&start_loc, &dest_loc)) {
                    continue;
                }

                num_added += 1;

                // we havent already calculated this pair
                total += self.markedManhattan(&start_loc, &dest_loc);

                // add to seen
                try self.addCoorPair(&start_loc, &dest_loc);
            }
        }

        print("Added: `{}`\n", .{num_added});

        return total;
    }

    fn expand(self: *Puzzle) !void {
        // do rows first since its easiest
        for (self.rows.items) |row| {
            try self.expanded_rows.append(try gpa.dupe(u8, row));
            for (row) |c| {
                if (c != '.') break;
            } else {
                try self.expanded_rows.append(try gpa.dupe(u8, row));
            }
        }

        // now iterate column wise through all the expanded rows
        var col_idx: usize = 0;
        while (col_idx < self.expanded_rows.items[0].len) {
            for (self.expanded_rows.items) |row| {
                if (row[col_idx] != '.') break;
            } else {
                // all rows in this column are '.', so expand
                var row_idx: usize = 0;
                while (row_idx < self.expanded_rows.items.len) {
                    const row = self.expanded_rows.items[row_idx];
                    defer gpa.free(row);

                    var new_row = try gpa.alloc(u8, row.len + 1);
                    @memcpy(new_row[0..col_idx], row[0..col_idx]);
                    new_row[col_idx] = '.';
                    @memcpy(new_row[col_idx + 1 ..], row[col_idx..]);
                    self.expanded_rows.items[row_idx] = new_row;

                    // inc counters
                    row_idx += 1;
                }

                // we just added a new column, so we need to inc counter by 2
                col_idx += 1;
            }

            // inc counters
            col_idx += 1;
        }
    }
};
fn increaseModifier(first: usize, second: usize, scale: usize, modifier: usize) usize {
    if (first > second) {
        return first + (modifier * scale) - modifier;
    }

    return first;
}
fn manhattanCoord(a: *const Coor, b: *const Coor) usize {
    const x_0: isize = @intCast(a.x);
    const x_1: isize = @intCast(b.x);
    const y_0: isize = @intCast(a.y);
    const y_1: isize = @intCast(b.y);

    return @abs(x_1 - x_0) + @abs(y_1 - y_0);
}

fn part1(data: []const u8) !usize {
    var puzzle = Puzzle.init(gpa);
    defer puzzle.deinit();

    // load the puzzle
    try puzzle.fromPart1Data(data);

    print("Puzzle has `{}` locations\n", .{puzzle.locations.items.len});

    return try puzzle.part1Distances();
}

// 827009909817
fn part2(data: []const u8) !usize {
    var puzzle = Puzzle.init(gpa);
    defer puzzle.deinit();

    // load the puzzle
    try puzzle.fromPart2Data(data);

    print("Puzzle has `{}` locations\n", .{puzzle.locations.items.len});

    return try puzzle.part2Distances();
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
