module imagesort;


import std.getopt;
import std.stdio;
import std.datetime.date;
import std.file;
import std.path;
import std.regex;

import directorymapper;
import filedateextractor;
import options;
import stat;

int main(string[] args) {
    string srcDirStr = "";
    string dstDirStr = "";
    bool execute = false;
    bool removeDups = false;
    bool verbose = false;

    auto optsResult = getopt(args,
                                "src", &srcDirStr,   
                                "dst", &dstDirStr,
                                "do", &execute,
                                "rmdups", &removeDups,
                                "verbose", &verbose);

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

    if (!execute) {
        writeln("Performing test flight - no changes to file system will be done!");
    }

    Options opts;
    opts.execute = execute;
    opts.removeDups = removeDups;
    opts.verbose = verbose;

    StatCounter sc = new StatCounter();
    DirectoryMapper dm = new DirectoryMapper(dstDir, opts, sc);

    foreach (DirEntry e; std.file.dirEntries(srcDir,  SpanMode.depth)) {
        if (!e.isFile) {
            continue;
        }

        auto fileDate = extractFileDate(e);
        if (fileDate == null) {
            opts.verboseMsg((){ writeln("file ", e.name, " not matched any date extractor"); });
            continue;
        }

        string dirToMove = dm.getOrCreateDir(*fileDate);
        auto fileName = std.path.baseName(e.name);
        string newFilePath = std.path.buildPath(dirToMove, fileName);
        if (std.file.exists(newFilePath)) {
            sc.increment(StatField.FilesSkipped);
            opts.verboseMsg((){ writeln(newFilePath, " already exists"); });
            if (opts.removeDups) {
                sc.increment(StatField.DupsRemoved);
                opts.verboseMsg((){ writeln("remove duplicate \"", e.name, "\""); });
                if (opts.execute) {
                    std.file.remove(e.name);
                }
            }
            continue;
        }

        opts.verboseMsg((){ writeln("copy \"", e.name, "\" \"", newFilePath, "\""); });
        try {
            if (opts.execute) {
                std.file.copy(e.name, newFilePath);
            }
        } catch (FileException ex) {
            writeln("copy to ", newFilePath, " error: ", ex.message());
            continue;
        }
        sc.increment(StatField.FilesProcessed);
        
        opts.verboseMsg((){ writeln("remove ", e.name); });
        try {
            if (opts.execute) {
                std.file.remove(e.name);
            }
        } catch (FileException ex) {
            writeln("remove ", e.name, " error: ", ex.message());
            continue;
        }
    }

    writeln("Summary:");
    writeln(sc.getValue(StatField.ExistingDirs), " dst dirs found");
    writeln(sc.getValue(StatField.NewDirs), " dst dirs created");
    writeln(sc.getValue(StatField.FilesToExistingDirs) + sc.getValue(StatField.FilesToNewDirs), " total files found");
    writeln(sc.getValue(StatField.FilesToExistingDirs), " files moved to existing dirs");
    writeln(sc.getValue(StatField.FilesToNewDirs), " files moved to new dirs");
    writeln(sc.getValue(StatField.FilesProcessed), " files processed");
    writeln(sc.getValue(StatField.FilesSkipped), " files skipped");
    writeln(sc.getValue(StatField.DupsRemoved), " duplicates removed");

    return 0;
}
