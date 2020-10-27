# BashDynamicPaper
Dynamic wallpaper setter written in bash, I recommend you use it with a cron-job

### Usage
```
USAGE: dynamicWallpaper -p [PAPER_PREFIX] -w [AIRPORT_ID]
    -p: The prefix of your wallpaper folder without a trailing /
    -w: Optional argument specifying whether or not to use weather data, takes an airport identifier [E.G. LAX]
```

### File Formatting
There are four different time chunks to sort your wallpapers into: Morning,
Day, Evening, and Night. This will be set dynamically based on the time of
the sunrise and sunset in your time-zone (currently hard-coded to EST).

Weather specific papers should be stored in subdirectories of the four time
directories. Currently the code respects 3 types of weather: "Sun", "Rain",
and "Snow". Additionally, a "Misc" folder can be used to store backgrounds that
don't fit any of the three categories and these will be added to the wallpaper
pool for ALL weather types.

Ergo an example of a rainy day wallpaper might be:
`/home/joe/Pictures/Wallpapers/Day/Rain/wet_park_bench.png`

As long as the folder structure is correct the actual images can be named whatever
you like.
