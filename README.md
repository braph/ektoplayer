# Ektoplayer

Ektoplayer is a console audio player for [ektoplazm.com](http://www.ektoplazm.com).

![Screenshot 2017-03-16](http://pixelbanane.de/yafu/118231024/ekto1.png)
![Screenshot 2017-03-16](http://pixelbanane.de/yafu/324630271/ekto2.png)

## Requirements

  * Ruby (1.9)
  * Portaudio (19)
  * Mpg123 (1.14)
  * LibZip
  * Sqlite3 

## Installation

Assuming you have Ruby/Rubygems installed, you need portaudio and mpg123 as
library to compile the native extensions.

### Arch Linux

    pacman -S ruby portaudio mpg123 sqlite3 ncurses zlib base-devel --needed
    gem install ektoplayer

### Debian / Ubuntu (not yet tested)

    apt-get install ruby ruby-dev portaudio19-dev libmpg123-dev sqlite3 libsqlite3-dev libncurses-dev libz1g-dev build-essential
    gem install ektoplayer

## Features

  * Listen to ektoplazm tracks
  * Download whole albums
  * Browse database by tags
  * Vi keybindings (`hjkl`, `^d`, `^u`, `/`, `?`, `n`, `N`, ...)
  * Mouse is supported
  * Supports 256/16/mono colors
  * Local sound file cache and download archive
  * Highly configurable

## Authors

  * [Benjamin Abendroth](https://github.com/braph)

## See also

  * Ektoplayer was inspired by [Soundcloud2000](https://github.com/grobie/soundcloud2000) and [ncmpcpp](https://github.com/arybczak/ncmpcpp)
  * It uses [Audite](https://github.com/georgi/audite) as playback engine and [Nokogiri](http://www.nokogiri.org/) for parsing HTML

