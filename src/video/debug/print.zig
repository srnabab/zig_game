const std = @import("std");
const builtin = @import("builtin");

const global = @import("global");

const processRender = @import("processRender");
const Commands = processRender.commands;

var commands: *Commands = undefined;
var io: std.Io = undefined;

pub fn init(io_: std.Io, c: *Commands) void {
    commands = c;
    io = io_;
}

pub fn printToDot() void {
    const old1 = global.stopNodeDagPrint;
    const old2 = global.printDagToDot;

    defer {
        global.stopNodeDagPrint = old1;
        global.printDagToDot = old2;
    }

    global.stopNodeDagPrint = false;
    global.printDagToDot = true;
    processRender.nodeDagPrint(&commands.nodeDag, commands);
}

pub fn printAllInfoToTxt() void {
    const epochSeconds = std.time.epoch.EpochSeconds{
        .secs = @intCast(std.Io.Timestamp.now(io, .real).toSeconds()),
    };
    const epochDay = epochSeconds.getEpochDay();
    const daySeconds = epochSeconds.getDaySeconds();

    const year = epochDay.calculateYearDay().year;
    const month = epochDay.calculateYearDay().calculateMonthDay().month;
    const day = epochDay.calculateYearDay().calculateMonthDay().day_index;
    const hour = daySeconds.getHoursIntoDay();
    const minute = daySeconds.getMinutesIntoHour();
    const second = daySeconds.getSecondsIntoMinute();

    var pathBuffer = [_]u8{0} ** 25;
    const path = std.fmt.bufPrint(&pathBuffer, "{d}-{s}-{d}-{d} {d} {d}.txt", .{
        year,
        @tagName(month),
        day,
        hour,
        minute,
        second,
    }) catch |err| {
        std.log.err("write err: {s} 6", .{@errorName(err)});
        return;
    };
    var file = std.Io.Dir.cwd().createFile(io, path, .{}) catch |err| {
        std.log.err("write err: {s} 7", .{@errorName(err)});
        return;
    };
    defer file.close(io);

    var writeBuffer = [_]u8{0} ** 1024;
    var fileWriter = file.writer(io, &writeBuffer);

    var it = commands.nodeDag.map.iterator();
    while (it.next()) |entry| {
        const com = commands.queue.getPtr(entry.key_ptr.*);
        if (com == null) continue;

        var infoBuffer = [_]u8{0} ** 512;
        var len: usize = 0;
        switch (com.?.command) {
            .computeRecord => |r| {
                const info = std.fmt.bufPrint(
                    &infoBuffer,
                    "group count = {d}",
                    .{r.groupCount},
                ) catch continue;
                len = info.len;
            },
            else => continue,
        }

        fileWriter.interface.print("{d} {s} {s}", .{
            entry.key_ptr.*,
            @tagName(entry.value_ptr.*.data.commandPoolType),
            infoBuffer[0..len],
        }) catch |err| {
            std.log.err("write err: {s} 8", .{@errorName(err)});
            return;
        };
    }

    fileWriter.flush() catch |err| {
        std.log.err("write err: {s} 8", .{@errorName(err)});
        return;
    };
}
