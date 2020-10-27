# BashDynamicPaper
Dynamic wallpaper setter written in bash
I recommend you use it with a cron-job

### Usage
```
USAGE: dynamicWallpaper -p [PAPER_PREFIX] -w [1]
    -p: The prefix of your wallpaper folder without a trailing /
    -w: Optional argument specifying whether or not to use weather data
```

### File Formatting
There are four different time chunks to sort your wallpapers into: Morning,
Day, Evening, and Night. This will be set dynamically based on the time of
the sunrise and sunset in your time-zone (currently hard-coded to EST).

Weather specific papers should be formated with a prefix describing the weather
depicted in the paper. Currently the code respects 3 prefixes: "sun__", "rain___",
and "_snow__".

Ergo an example of a rainy day wallpaper might be:
`/home/joe/Pictures/Wallpapers/Day/rain__ParkBench.png`

All that matters for the time of day is the folder it's contained in, and all
that matters for the weather is the prefix of the filename.
