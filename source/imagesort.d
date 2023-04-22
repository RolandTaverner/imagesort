module source.imagesort;

import std.algorithm.comparison : cmp;
import std.getopt;
import std.stdio;
import std.datetime.date;
import std.file;
import std.path;
import std.regex;

int main(string[] args)
{
    string srcDirStr = "";
    string dstDirStr = "";

    auto optsResult = getopt(args,
                                    "src",  &srcDirStr,   
								    "dst",  &dstDirStr);

    if (srcDirStr.length == 0 || dstDirStr.length == 0 || optsResult.helpWanted) {
		defaultGetoptPrinter("Usage", optsResult.options);
		return -1;
	}

    if (!std.file.exists(srcDirStr) || !std.file.isDir(srcDirStr)) {
        writefln("%s is not a directory", srcDirStr);
        return -1;
    }
    if (!std.file.exists(dstDirStr) || !std.file.isDir(dstDirStr)) {
        writefln("%s is not a directory", dstDirStr);
        return -1;
    }

    auto srcDir = std.file.DirEntry(srcDirStr);
    auto dstDir = std.file.DirEntry(dstDirStr);

    auto dstDirMap = mapDstDir(dstDir);

    return 0;
}

string[Date] mapDstDir(const std.file.DirEntry dstDir) {
    auto dirRegex = std.regex.regex(r"^(\d{4}\-\d{2}\-\d{2}).*$");

    string[Date] dirMap;
    foreach (DirEntry e; std.file.dirEntries(dstDir,  SpanMode.shallow)) {
        auto leaf = std.path.baseName(e.name);
        auto dirMatch = std.regex.matchFirst(leaf, dirRegex);
        if (dirMatch.empty) {
            debug writeln(leaf, " not matched");
            continue;
        }
        const string strDate = dirMatch[1];
        auto dirDate = Date.fromISOExtString(strDate);

        auto existingPath = dirDate in dirMap;
        if (existingPath is null) {
            dirMap[dirDate] = e.name;
        } else {
            if (cmp(e.name, *existingPath) < 0) {
                dirMap[dirDate] = e.name;
            }
        }

        debug writeln(dirDate, " -> ", dirMap[dirDate]);
    }

    return dirMap;
}