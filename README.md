# imagesort

Console utility to sort photos from Google Takeout (or any directory with a lot of photos) by date.

# Description

## How it works

The program scans files in the provided `src` directory, extracts date from file name and puts file to corresponding directory in the provided `dst` directory. For example if you have this in the `myphotos` directory 

```
./myphotos/
├── 20190413_173941.jpg
├── 20190413_173945.jpg
├── bar
│    ├── 20221109_184734.jpg
│    └── 20221109_184742.jpg
└── foo
    ├── 20190503_111619.jpg
    ├── 20190503_111621.jpg
    └── 20190503_111853.jpg
```

and run 

```bash
imagesort.exe --src myphotos --dst sortedphotos --do
```

you will get this in the `sortedphotos` directory

```
./sortedphotos/
├── 2019-04-13
│    ├── 20190413_173941.jpg
│    └── 20190413_173945.jpg
├── 2019-05-03
│    ├── 20190503_111619.jpg
│    ├── 20190503_111621.jpg
│    └── 20190503_111853.jpg
└── 2022-11-09
    ├── 20221109_184734.jpg
    └── 20221109_184742.jpg
```

## Date extracting

Program tries to parse file name and extract date. It supports several file name formats.

### Samsung's (and maybe others) camera app

Format: `YYYYMMDD_anytext.extension`

Example: 20190413_189456.jpg

### VideoShow files

Format: `Video_YYYYMMDDdigits_anytext.extension`

Example: Video_20170224593769017_by_videoshow.mp4

### VID...WA videos (dont remember what produced this)

Format: `VID-YYYYMMDD-WAdigits.extension`

Example: VID-20180425-WA0000.mp4

### IMG...WA images (dont remember what produced this)

Format: `IMG-YYYYMMDD-WAdigits.extension`

Example: IMG-20170105-WA0000.jpg

## Destionation directories handling

If directory 'YYYY-MM-DD' already exists, the program will use it.

All directories with names starting with 'YYYY-MM-DD', for example '2021-02-04 Travel to Nowhere' or '2030-07-04 Weekend in the future' treated as 'YYYY-MM-DD' directories so files will be copied there.

So you can run program, rename directories, then run program again to sort more images and it will use your existing directories with meaningful names.

# How to use

Create directory where you want your sorted images will be then run command

```
imagesort --src {/path/to/src/dir} --dst {/path/to/dst/dir} --do
```

For example, you want to sort Samsung's camera files in Onedrive and move them to `d:\sortedphotos`.

```
imagesort --src "C:\Users\Me\OneDrive\Pictures\Samsung Gallery\DCIM\Camera" --dst d:\sortedphotos --do
```

## Command line switches

### --src

Path to source directory. If it contains spaces use quotes.

```
-- src "c:\Users\John Smith\Pictures\my photos"
```

### --dst

Path to destination directory. If it contains spaces use quotes.

```
-- dst "c:\Users\John Smith\Pictures\sorted photos"
```

### --rmdups

Instruct the program to remove duplicates (files with same names) in source directory. First file found will be moved, others will be just deleted.

### --verbose

Enable verbose output. All commands program executes will be printed.

Example output:

```
imagesort.exe --src d:\test\myphotos --dst d:\test\sortedphotos --verbose

Performing test flight - no changes to file system will be done!
mkdir "d:\test\sortedphotos\2019-05-03"
copy "d:\test\myphotos\20190503_110619.jpg" "d:\test\sortedphotos\2019-05-03\20190503_110619.jpg"
remove d:\test\myphotos\20190503_110619.jpg
copy "d:\test\myphotos\20190503_110621.jpg" "d:\test\sortedphotos\2019-05-03\20190503_110621.jpg"
remove d:\test\myphotos\20190503_110621.jpg
copy "d:\test\myphotos\20190503_110853.jpg" "d:\test\sortedphotos\2019-05-03\20190503_110853.jpg"
remove d:\test\myphotos\20190503_110853.jpg
copy "d:\test\myphotos\bar\20190413_172941.jpg" "d:\test\sortedphotos\2019-04-13\20190413_172941.jpg"
remove d:\test\myphotos\bar\20190413_172941.jpg
d:\test\sortedphotos\2019-04-13\20190413_172945.jpg already exists
copy "d:\test\myphotos\foo\20190503_110619.jpg" "d:\test\sortedphotos\2019-05-03\20190503_110619.jpg"
remove d:\test\myphotos\foo\20190503_110619.jpg
copy "d:\test\myphotos\foo\20190503_110621.jpg" "d:\test\sortedphotos\2019-05-03\20190503_110621.jpg"
remove d:\test\myphotos\foo\20190503_110621.jpg
copy "d:\test\myphotos\foo\20190503_110853.jpg" "d:\test\sortedphotos\2019-05-03\20190503_110853.jpg"
remove d:\test\myphotos\foo\20190503_110853.jpg
Summary:
1 dst dirs found
1 dst dirs created
8 total files found
2 files moved to existing dirs
6 files moved to new dirs
7 files processed
1 files skipped
0 duplicates removed
```

### --do

Instructs program to actually execute actions. Without this option program will print actions (if `--verbose` provided) and print summary, but will not touch your files.

Example output without `--do`. Note the "Performing test flight - no changes to file system will be done!" message.

```
$ imagesort.exe --src d:\test\myphotos --dst d:\test\sortedphotos

Performing test flight - no changes to file system will be done!
Summary:
1 dst dirs found
1 dst dirs created
8 total files found
2 files moved to existing dirs
6 files moved to new dirs
7 files processed
1 files skipped
0 duplicates removed
```

Example with `--do`

```
$ imagesort.exe --src d:\test\myphotos --dst d:\test\sortedphotos --do

Summary:
1 dst dirs found
1 dst dirs created
8 total files found
2 files moved to existing dirs
6 files moved to new dirs
4 files processed
4 files skipped
0 duplicates removed
```

## Understanding summary

```
Summary:
1 dst dirs found
1 dst dirs created
8 total files found
2 files moved to existing dirs
6 files moved to new dirs
4 files processed
4 files skipped
0 duplicates removed
```

`1 dst dirs found` - count of alredy existing `YYYY-MM-DD` directories found.

`1 dst dirs created` - count of `YYYY-MM-DD` directories created.

`8 total files found` - total files count found in provided source directory.

`2 files moved to existing dirs` - files count moved to existing directories.

`6 files moved to new dirs` - files count moved to new directories.

`4 files processed` - files count with recognizable date.

`4 files skipped` - skipped files count. The program skips file if it cant parse file name or file is duplicated but no `--rmdups` switch provided.

`0 duplicates removed` - count of removed duplicates. Always 0 if no `--rmdups` switch provided.
