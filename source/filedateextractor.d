module filedateextractor;

import std.datetime.date;
import std.file;
import std.path;
import std.regex;

interface FileDateExtractor {
     Date* extractFileDate(scope ref const std.file.DirEntry fileEntry) const pure;
}

abstract class BaseFileDateExtractor : FileDateExtractor {
     private const std.regex.Regex!char fileRegex;

     private this(const string regexString) {
          this.fileRegex = std.regex.regex(regexString);
     }
}

class ISOExtractor : BaseFileDateExtractor {
     this() {
          super(r"^(\d{8})_.*\.\w+$");
     }

     Date* extractFileDate(scope ref const std.file.DirEntry fileEntry) const pure {
          if (!fileEntry.isFile) {
               return null;
          }

          auto fileMatch = std.regex.matchFirst(std.path.baseName(fileEntry.name), fileRegex);
          if (fileMatch.empty) {
               return null;
          }
          const string dateExpr = fileMatch[1];
          const string strDate = dateExpr[0..4] ~ "-" ~ dateExpr[4..6] ~ "-" ~ dateExpr[6..8];
          
          Date *dirDate = new Date() ;
          try *dirDate = Date.fromISOExtString(strDate);
          catch(DateTimeException d) return null;

          return dirDate;
     }
}

class VideoShowExtractor : BaseFileDateExtractor {
     this() {
          super(r"^Video_(\d{8})\d+_\w+\.\w+$");
     }

     Date* extractFileDate(scope ref const std.file.DirEntry fileEntry) const pure {
          if (!fileEntry.isFile) {
               return null;
          }

          auto fileMatch = std.regex.matchFirst(std.path.baseName(fileEntry.name), fileRegex);
          if (fileMatch.empty) {
               return null;
          }
          const string dateExpr = fileMatch[1];
          const string strDate = dateExpr[0..4] ~ "-" ~ dateExpr[4..6] ~ "-" ~ dateExpr[6..8];
          
          Date *dirDate = new Date() ;
          try *dirDate = Date.fromISOExtString(strDate);
          catch(DateTimeException d) return null;

          return dirDate;
     }
}

class VidWaExtractor : BaseFileDateExtractor {
     this() {
          super(r"^VID-(\d{8})-WA\d+\.\w+$");
     }

     Date* extractFileDate(scope ref const std.file.DirEntry fileEntry) const pure {
          if (!fileEntry.isFile) {
               return null;
          }

          auto fileMatch = std.regex.matchFirst(std.path.baseName(fileEntry.name), fileRegex);
          if (fileMatch.empty) {
               return null;
          }
          const string dateExpr = fileMatch[1];
          const string strDate = dateExpr[0..4] ~ "-" ~ dateExpr[4..6] ~ "-" ~ dateExpr[6..8];
          
          Date *dirDate = new Date() ;
          try *dirDate = Date.fromISOExtString(strDate);
          catch(DateTimeException d) return null;

          return dirDate;
     }
}

class ImgWaExtractor : BaseFileDateExtractor {
     this() {
          super(r"^IMG-(\d{8})-WA\d+\.\w+$");
     }

     Date* extractFileDate(scope ref const std.file.DirEntry fileEntry) const pure {
          if (!fileEntry.isFile) {
               return null;
          }

          auto fileMatch = std.regex.matchFirst(std.path.baseName(fileEntry.name), fileRegex);
          if (fileMatch.empty) {
               return null;
          }
          const string dateExpr = fileMatch[1];
          const string strDate = dateExpr[0..4] ~ "-" ~ dateExpr[4..6] ~ "-" ~ dateExpr[6..8];
          
          Date *dirDate = new Date() ;
          try *dirDate = Date.fromISOExtString(strDate);
          catch(DateTimeException d) return null;

          return dirDate;
     }
}

const FileDateExtractor[] extractors = [
     new ISOExtractor(), 
     new VideoShowExtractor(),
     new VidWaExtractor(),
     new ImgWaExtractor(),
     ];

Date* extractFileDate(scope ref const std.file.DirEntry fileEntry) {
     foreach(e; extractors) {
          auto date = e.extractFileDate(fileEntry);
          if (date != null) {
               return date;
          }
     }

     return null;
}
