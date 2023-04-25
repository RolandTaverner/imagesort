module directorymapper;

import std.algorithm.comparison : cmp;
import std.datetime.date;
import std.file;
import std.path;
import std.regex;
import std.stdio;

import options;
import stat;

// DirectoryMapper scans destination directories and creates new when necessary
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

    // getOrCreateDir() returns directory for given date. Creates new directory if necessary.
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
        opts.verboseMsg((){ writeln("mkdir \"", newDirPath, "\""); });
        if (opts.execute) {
            std.file.mkdir(newDirPath);
        }
        statCounter.increment(StatField.NewDirs);

        newDirMap[d] = newDirPath;
        return newDirPath;
    }
    
    // mapDstDir() scans destination directory and maps found directories to dates
    private void mapDstDir() {
        immutable static auto dirRegex = std.regex.regex(r"^(\d{4}\-\d{2}\-\d{2}).*$");

        foreach (DirEntry e; std.file.dirEntries(dstDir,  SpanMode.shallow)) {
            if (!e.isDir) {
                continue;
            }
            auto leaf = std.path.baseName(e.name);
            auto dirMatch = std.regex.matchFirst(leaf, dirRegex);
            if (dirMatch.empty) {
                opts.verboseMsg((){ writeln("directory \"", leaf, "\" not matched"); });
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
            //debug writeln(dirDate, " -> ", existingDirMap[dirDate]);
        }
    }

}
