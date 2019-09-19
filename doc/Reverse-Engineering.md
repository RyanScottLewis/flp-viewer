# Reverse Engineering the FL Studio Proprietary File Format

## Goal

I (along with many music producers) have a great deal of project files, some of which are very old,
and I would like to weed out the crappy ones containing maybe just a beat or an experiment and only
search for projects containing substance.

FL Studio keeps track of project creation time and project working time, which are excellent metrics
for finding such projects.

Unfortunately, the proprietary FLP format is not exactly friendly. The little amount of documentation
on it and the few open-source FLP parser implementations leave much to be desired. In fact, I can't
find a single one which can actually parse project creation/working times.

This information is obviously in the file, though. So, that means it must be reverse engineered.

> Editors note: This changes during the course of writing this article, as FLPEdit can in fact parse
> project times and is used as reference once found.

## Steps

### Create a Parser

Luckily, there are implementations of FLP file format parsers out there. I decided on using Crystal
as it's expressive but strongly typed, which is perfect for parsing binary data. Doing so in Ruby is
a String manipulation nightmare waiting to happen.

So, really all I did was port the parser to Crystal from the multiple different projects:

* https://github.com/andrewrk/PyDaw (Python implementation)
* https://github.com/monadgroup/FLParser (C-Sharp implementation)
* https://github.com/LMMS/lmms (C++ implementation)
  * Sidenote: I had no idea LMMS could import FLP projects until now.
* https://github.com/RoadCrewWorker/FLPEdit (C-Sharp implementation)
  * By far the best resource so far, found while creating this article.

> Note how similar their sources are, you can tell they've all either derived from the same scarce
> documentation, or from each other (which is our case).

The parser works by identifying and reading the two chunks in order, then proceding to identify and
read events based on their type until it reaches the end of the file.

#### File Format

The file format is a mess, but it breaks down like so:

There are two chunks, the header chunk and the data chunk.

The header chunk contains some basic information but was largely abandoned and can be ignored for
the most part, only pertinent information contained in the header is the project channel count and
PPQ (parts per quarter (?)) attribute.

The data chunk simply contains a series of "events", identified by the first byte which determines
how much data to read and seems to support 8, 16, and 32 bit integers and arbitrary text data.

Most of these events have been identified, however there is none for what we actually want; which is
the project creation and working times.

## Comparing Data

So, to figure out these creation & working time values, I created two projects from the same 
template and saved them a few minutes apart from each other with no modifications.  
This way, the only difference in the two projects should be the project creation times.

I converted these projects to hex dumps using `xxd a.flp > a.hex` and diff'd them with
`nvim -d a.hex b.hex`. At this point, it was obvious that only a very small chunk of data has
changed.

I ran both projects through the parser and sure enough, only one event was different with the event
identifier `237`:

`a.flp`

```
[237, "J\f\u0002\u0013\xD9Y\xE5@\u0000\u0000\u0000\xA8\xACl:?"]
```

`b.flp`

```
[237, "\x80\xA1\xE5\u001C\xD9Y\xE5@\u0000\u0000\u0000@OI\u0012?"]
```

The data for this type was arbitrary text data, 16 bytes long. To identify what this chunk was, I 
opened op the first of my projects, kept active by selecting windows and such for a few minutes, 
then saved with a `-worked-on` postfix in the filename. I then diffed the parser output from those
files.

This showed that again that `237` event data was the only difference. This time, however, only the
first 8 bytes remained the same:

`a.flp`

```
[237, "J\f\u0002\u0013\xD9Y\xE5@\u0000\u0000\u0000\xA8\xACl:?"]
```

`a-worked-on.flp`

```
[237, "J\f\u0002\u0013\xD9Y\xE5@\u0000\u0000\u0000\u00184BL?"]
```

## Identifying Data

Here, I've printed out the data for the `237` event from many projects and formatted it in order to
compare the bytes:

```
              Offsets   0    1    2    3    4    5    6    7   8  9  10   11   12   13   14   16

old-0.flp         Bytes[234, 220, 179, 209, 215, 40,  229, 64, 0, 0, 64,  66,  151, 53,  139, 63]
old-1.flp         Bytes[166, 217, 159, 13,  88,  7,   229, 64, 0, 0, 128, 110, 3,   179, 171, 63]
old-2.flp         Bytes[206, 226, 0,   84,  1,   25,  229, 64, 0, 0, 208, 129, 37,  186, 164, 63]
old-3.flp         Bytes[106, 179, 117, 145, 156, 247, 228, 64, 0, 0, 208, 204, 19,  206, 175, 63]
old-4.flp         Bytes[230, 170, 239, 48,  141, 58,  229, 64, 0, 0, 96,  205, 213, 11,  180, 63]
old-5.flp         Bytes[148, 213, 17,  30,  31,  37,  229, 64, 0, 0, 160, 140, 166, 101, 154, 63]
data/a.flp        Bytes[74,  12,  2,   19,  217, 89,  229, 64, 0, 0, 0,   168, 172, 108, 58,  63]
data/a-worked.flp Bytes[74,  12,  2,   19,  217, 89,  229, 64, 0, 0, 0,   24,  52,  66,  76,  63]
data/b.flp        Bytes[128, 161, 229, 28,  217, 89,  229, 64, 0, 0, 0,   64,  79,  73,  18,  63]
```

Things to note are: 

* `old-*` are random, old projects.
* `a.flp` and `a-worked.flp` have the same creation time.
* `a.flp`, `a-worked.flp`, and `b.flp` were created on the same date, minutes from each other.
*  Bytes at offsets 16 are identical for all projects.
*  Bytes at offsets 7-9 are identical for all projects.
*  Bytes at offset 6 is identical for all projects, with the exception of `old-3.flp`.

### Breakthrough

It was around this time that I found the FLPEdit project by RoadCrewWorker on GitHub which actually
seems to parse project times:

```cs
// ...
ID_Project_Time = FLP_Text + 45,
// ...
```

The `FLP_Text` ID is `192`, which places `ID_Project_Time` at `192 + 45` which is `237`, our
unidentified event ID! This confirms that it is actually the project time that we were inspecting.

Now to identify the data using FLPEdit's source.

Diving deeper into the FLPEdit source, I find the `FLPE_Project_Time` class, which is stating that
the data is actually a Delphi time format. This seems to have an origin at the year `1900` and is
stored in a `double`. The class even shows that the data is formatted in a 

> I would have never guessed this, having completely forgotten that FL Studio was programmed in Delphi.

## Parsing the Data

Now that we have identified the data contained within our now identified project time data, we can
move on to parsing this data. Crystal has alot of support for coding/decoding binary data, in this
case a `double` which is a 64-bit floating point number (`Float64` in Crystal):

```cr
TIME_ORIGIN = Time.new(1899, 12, 30)

# ...

bytes = data.as(String).to_slice

start_date = IO::ByteFormat::LittleEndian.decode(Float64, bytes[0, 8])
start_date = Time::Span.new(1, 0, 0, 0) * start_date
start_date = TIME_ORIGIN + start_date

work_time = IO::ByteFormat::LittleEndian.decode(Float64, bytes[8, 8])
work_time = Time::Span.new(1, 0, 0, 0) * work_time
```

We're decoding the data from little endian as floats. The data is stored as `days` so we create a
time span with the length of 1 day, and scale it by the value.

In the case of start date, we add that time span to the Delphi origin date to retrieve the project
creation time.

## Summary

Well, this one was a bit of a struggle and truth be told, I was stuck trying to identify the contents
of the then mysterious event `237`. Even to the point where I was scanning for data type just to try
to see if any values could be recognized as a date time value or value partial. I'm truely indebted
to RoadCrewWorker for somehow figuring out this Delphi date time debacle.

However, I can at least take pride in correctly identifying the event type which needed to be parsed
by analyzing differences in a binary file which has become the first tool I reach for in my reverse
engineering toolbox.

