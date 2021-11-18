# BashDynamicPaper
Dynamic wallpaper setter written in bash that works on Linux and MacOS. Using all of the features, it 
will change your wallpaper based both on the time of day and the weather. The time of day is divided 
into four categories: morning, day, evening, and night. A sunrise/sunset api is used, which means that
the code will adjust as the seasons change and night grows shorter or longer. The supported weather types
right now are just rain, sun, and snow. If there are more of them you'd like to see I'm more than happy to add support.
It requires both [jq](https://stedolan.github.io/jq/) and [feh](https://feh.finalrewind.org/)
on linux. On mac it still requires [jq](https://stedolan.github.io/jq/) but instead of feh,
[coreutils](https://formulae.brew.sh/formula/coreutils) (For shuf and gdate). Additionally on both linux and MacOS, if you
want to use the embed feature, you will also need [imagemagick](https://imagemagick.org/script/download.php). The code will
also play nicely with [pywal](https://github.com/dylanaraps/pywal) should you want
 to change your themes w/r/t the wallpaper. Right now it uses [wttr.in]()'s ability
to get the location via IP so if you're using a VPN it might not play nicely.

### Example

![Example](./example.gif)

### Usage
```
USAGE: dynamicWallpaper -p [PAPER_PREFIX]
    -p: The prefix of your wallpaper folder without a trailing /
    -e: Embed a weather report into the middle of the background (OPTIONAL)
 --wal: Use pywal if it's installed (OPTIONAL)
```

### File Formatting
There are four different time chunks to sort your wallpapers into: Morning,
Day, Evening, and Night. This will be set dynamically based on the time of
the sunrise and sunset in your time-zone (based on airport code).

Weather specific papers should be stored in subdirectories of the four time
directories. Currently the code respects 3 types of weather: "Sun", "Rain",
and "Snow". Additionally, a "Misc" folder can be used to store backgrounds that
don't fit any of the three categories and these will be added to the wallpaper
pool for ALL weather types.

Ergo an example of a rainy day wallpaper might be:
`/home/joe/Pictures/Wallpapers/Day/Rain/wet_park_bench.png`

As long as the folder structure is correct the actual images can be named whatever
you like. Technically, if you have time of day folders, but no weather folders,
the script will still work correctly. It will just default to selecting any image
located in the time folder.

[Personal Wallpapers](https://www.dropbox.com/sh/nlgpsqia9mpxwqj/AACw_yVfhz_0K8jzVi44vkFja?dl=0)

Here are the personal wallpapers I use if you want a small, already sorted, collection to start with.

### A Note on macOS
Unfortunately, macOS does not have an accessible API for "spaces", or the virtual
desktops that you can access with 3 fingered swipes. Most wallpaper switchers
(that I've seen) overcome this limitation by running `killall Dock` after changing
the wallpaper and thus forcing a refresh. To me this seems like it's asking for
trouble. Thanks to the help of my very clever [friend](https://github.com/AndrewLitteken),
a different solution has been found. Right now the solution is to make a new
directory `~/Pictures/Weather Wallpaper`.  After doing so, set up the system wallpaper
changer to randomly set a new wallpaper from that folder. Run your cron-job at an 
interval slightly shorter than the interval you've set to rotate the wallpaper. 
The script will then manage the images in this folder, but allow the system to 
actually manage the wallpaper, obviously albiet from a limited selection. Thus 
we overcome the limitations while avoiding killing the dock every time we want to
change a paper.
