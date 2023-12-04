const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day04.txt");

const Score = struct {
    val: usize = 0,

    fn increase(self: *Score) void {
        if (self.val == 0) {
            self.val = 1;
        } else {
            self.val *= 2;
        }
    }
};

fn listContains(comptime T: type, list: *const List(T), needle: T) bool {
    for (list.items) |item| {
        if (item == needle) {
            return true;
        }
    } else {
        return false;
    }
}

fn part1Score(winning: *const List(usize), numbers: *const List(usize)) usize {
    var score = Score{};

    for (numbers.items) |num| {
        if (listContains(usize, winning, num)) {
            score.increase();
        }
    }

    return score.val;
}

pub fn part1() !usize {
    var total: usize = 0;

    var iterator = tokenizeSca(u8, data, '\n');
    while (iterator.next()) |line| {
        const winning_start: usize = 1 + (indexOf(u8, line, ':') orelse continue);
        const winning_end = indexOf(u8, line, '|') orelse continue;

        // get list of winning numbers
        var winning_list: List(usize) = List(usize).init(gpa);
        defer winning_list.deinit();
        var winning_iterator = tokenizeSca(u8, line[winning_start..winning_end], ' ');
        while (winning_iterator.next()) |winning_num| {
            try winning_list.append(try parseInt(usize, winning_num, 10));
        }

        // get our numbers
        var our_list: List(usize) = List(usize).init(gpa);
        defer our_list.deinit();
        const our_nums = line[winning_end + 1 ..];
        var our_iterator = tokenizeSca(u8, our_nums, ' ');
        while (our_iterator.next()) |our_number| {
            try our_list.append(try parseInt(usize, our_number, 10));
        }

        const score = part1Score(@constCast(&winning_list), @constCast(&our_list));
        total += score;
    }

    return total;
}

fn countWinningNumbers(winning: *const List(usize), numbers: *const List(usize)) usize {
    var score: usize = 0;

    for (numbers.items) |num| {
        if (listContains(usize, winning, num)) {
            score += 1;
        }
    }

    return score;
}

fn ensureListSize(size: usize, list: *List(usize)) !void {
    while (list.items.len < size) {
        try list.append(1);
    }
}

fn addMultipliers(hand: usize, multipliers: *List(usize), num: usize) !void {
    var index: usize = hand + 1;
    const end_index: usize = hand + num + 1;
    try ensureListSize(end_index, multipliers);

    const n: usize = multipliers.items[hand];
    while (index < end_index) : (index += 1) {
        multipliers.items[index] += n;
    }
}

pub fn part2() !usize {
    var total: usize = 0;
    var multipliers: List(usize) = List(usize).init(gpa);
    defer multipliers.deinit();
    try ensureListSize(1024, &multipliers);

    var hand: usize = 0;
    var iterator = tokenizeSca(u8, data, '\n');
    while (iterator.next()) |line| {
        const winning_start: usize = 1 + (indexOf(u8, line, ':') orelse continue);
        const winning_end = indexOf(u8, line, '|') orelse continue;

        // get list of winning numbers
        var winning_list: List(usize) = List(usize).init(gpa);
        defer winning_list.deinit();
        var winning_iterator = tokenizeSca(u8, line[winning_start..winning_end], ' ');
        while (winning_iterator.next()) |winning_num| {
            try winning_list.append(try parseInt(usize, winning_num, 10));
        }

        // get our numbers
        var our_list: List(usize) = List(usize).init(gpa);
        defer our_list.deinit();
        const our_nums = line[winning_end + 1 ..];
        var our_iterator = tokenizeSca(u8, our_nums, ' ');
        while (our_iterator.next()) |our_number| {
            try our_list.append(try parseInt(usize, our_number, 10));
        }

        //
        // part2 begin
        //

        // make sure multipliers has an entry for this index
        try ensureListSize(hand + 1, &multipliers);

        // get the current number of winning hands
        const winning_numbers = countWinningNumbers(&winning_list, &our_list);
        // add the multipliers to the following cards
        try addMultipliers(hand, &multipliers, winning_numbers);

        // add the # for the current card
        total += multipliers.items[hand];

        // increase counters
        hand += 1;
    }

    return total;
}
pub fn main() !void {
    print("Part1: `{}`\n", .{try part1()});
    print("Part2: `{}`\n", .{try part2()});
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
