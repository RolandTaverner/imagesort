module imagesort;

import std.algorithm.comparison : cmp;
import std.getopt;
import std.stdio;
import std.datetime.date;
import std.file;
import std.path;
import std.regex;

import stat;

int main(string[] args)
{
    string srcDirStr = "";
    string dstDirStr = "";
    bool execute = false;
    bool removeDups = false;

    auto optsResult = getopt(args,
                                "src", &srcDirStr,   
                                "dst", &dstDirStr,
                                "do",  &execute,
                                "rmdups", &removeDups);

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

    StatCounter sc = new StatCounter();
    
    DirectoryMapper dm = new DirectoryMapper(dstDir, opts, sc);

    uint filesToExistingDirs = 0;
    uint filesToNewDirs = 0;

    foreach (DirEntry e; std.file.dirEntries(srcDir,  SpanMode.depth)) {
        if (!e.isFile) {
            continue;
        }

        auto fileDate = dateFromName(e);
        if (fileDate == null) {
            continue;
        }
        //debug writeln("file date ", fileDate.toISOExtString(), e.name);

        string dirToMove = dm.getOrCreateDir(*fileDate);
        auto fileName = std.path.baseName(e.name);
        string newFilePath = std.path.buildPath(dirToMove, fileName);
        if (std.file.exists(newFilePath)) {
            sc.increment(StatField.FilesSkipped);
            writeln(newFilePath, " already exists");
            if (opts.removeDups) {
                sc.increment(StatField.DupsRemoved);
                debug writeln("remove \"", e.name, "\"");
                if (opts.execute) {
                    std.file.remove(e.name);
                }
            }
            continue;
        }

        debug writeln("copy \"", e.name, "\" \"", newFilePath, "\"");
        try {
            if (opts.execute) {
                std.file.copy(e.name, newFilePath);
            }
        } catch (FileException ex) {
            writeln("copy to ", newFilePath, " error: ", ex.message());
            continue;
        }
        sc.increment(StatField.FilesProcessed);
        
        debug writeln("remove ", e.name);
        try {
            if (opts.execute) {
                std.file.remove(e.name);
            }
        } catch (FileException ex) {
            writeln("remove ", e.name, " error: ", ex.message());
            continue;
        }
    }


    // writeln(filesToExistingDirs + filesToNewDirs, " files found");
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

class DirectoryMapper {
    private std.file.DirEntry dstDir;
    private string[Date] existingDirMap;
    private string[Date] newDirMap;
    Options opts;
    StatCounter statCounter;

    this(const std.file.DirEntry dstDir, Options opts, StatCounter statCounter) {
        this.dstDir = dstDir;
        this.opts = opts;
        this.statCounter = statCounter;
        mapDstDir();
    }

    string getOrCreateDir(const Date d) {
        const auto existingDir = d in existingDirMap;
        if (existingDir != null) {
            statCounter.increment(StatField.FilesToExistingDirs);
            return *existingDir;
        } 

        statCounter.increment(StatField.FilesToNewDirs);
        const auto newDir = d in newDirMap;
        if (newDir != null) {
            return *newDir;
        } 
        const auto newDirPath = std.path.buildPath(dstDir.name, d.toISOExtString());
        if (opts.execute) {
            std.file.mkdir(newDirPath);
        }
        statCounter.increment(StatField.NewDirs);
        debug writeln("Created dir ", newDirPath);

        newDirMap[d] = newDirPath;
        return newDirPath;
    }
    

    private void mapDstDir() {
        immutable static auto dirRegex = std.regex.regex(r"^(\d{4}\-\d{2}\-\d{2}).*$");

        foreach (DirEntry e; std.file.dirEntries(dstDir,  SpanMode.shallow)) {
            if (!e.isDir) {
                continue;
            }
            auto leaf = std.path.baseName(e.name);
            auto dirMatch = std.regex.matchFirst(leaf, dirRegex);
            if (dirMatch.empty) {
                debug writeln(leaf, " not matched");
                continue;
            }
            const string strDate = dirMatch[1];
            Date dirDate;
            
            try dirDate = Date.fromISOExtString(strDate);
            catch(DateTimeException d) continue;

            auto existingPath = dirDate in existingDirMap;
            if (existingPath is null) {
                existingDirMap[dirDate] = e.name;
                statCounter.increment(StatField.ExistingDirs);
            } else {
                if (cmp(e.name, *existingPath) < 0) {
                    existingDirMap[dirDate] = e.name;
                }
            }
            debug writeln(dirDate, " -> ", existingDirMap[dirDate]);
        }
    }

}

struct Options {
    bool execute = false;
    bool verbose = false;
    bool removeDups = false;
}


Date *dateFromName(scope ref const DirEntry fileEntry) {
    immutable static auto fileRegex = std.regex.regex(r"^(\d{8})_.*\.\w+$");
    if (!fileEntry.isFile) {
        return null;
    }

    auto fileMatch = std.regex.matchFirst(std.path.baseName(fileEntry.name), fileRegex);
    if (fileMatch.empty) {
        writeln("file ", fileEntry.name, " not matched");
        return null;
    }
    const string dateExpr = fileMatch[1];
    const string strDate = dateExpr[0..4] ~ "-" ~ dateExpr[4..6] ~ "-" ~ dateExpr[6..8];
    
    Date *dirDate = new Date() ;
    try *dirDate = Date.fromISOExtString(strDate);
    catch(DateTimeException d) return null;

    return dirDate;
}