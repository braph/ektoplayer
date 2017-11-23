# Ektoplayer

Ektoplayer is a commandline client for [ektoplazm.com](http://www.ektoplazm.com), a website where you can listen and download freely licensed psytrance, techno and downtempo music. 

It allows you to
  * Search for tracks by tags (artist, album, style, ...)
  * Play tracks located at ektoplazm.com
  * Display information about albums
  * Download whole albums as mp3

## Features

  * Mouse support
  * Vi-like keybindings (`hjkl`, `^d`, `^u`, `/`, `?`, `n`, `N`, ...)
  * Up to 256 colors are supported
  * Local sound file cache
  * Song prefetching

## Screenshots

![Screenshot 2017-03-20](http://pixelbanane.de/yafu/454463454/ekto1.gif)
![Screenshot 2017-03-20](http://pixelbanane.de/yafu/1213960318/ekto2.gif)
![Screenshot 2017-03-20](http://pixelbanane.de/yafu/1573688123/ekto3.gif)
![Screenshot 2017-03-20](http://pixelbanane.de/yafu/3388136564/ekto4.gif)

## Requirements

  * Ruby (1.9)
  * Mpg123 (1.14)
  * Sqlite3 
  * One of the following ncurses gems: curses, ffi-ncurses, ncurses, ncuresw

## Optional Requirements

  * For extracting album archives either `unzip`, `7z` or the Gem `RubyZip` is needed

## Installation

*Note*: Running ruby gems requires to change the `$PATH` variable.
See `gem env gempath`.

### Arch Linux

  * Using yaourt:
      ```
      yaourt -S ektoplayer
      ```

  * Using gem:

      ```
      pacman -S ruby mpg123 sqlite3 ncurses --needed
      gem install ektoplayer
      ```

### Debian / Ubuntu (not yet tested)
   * using gem:

      ```
      apt-get install ruby ruby-dev libz libz-dev ruby-ncurses ruby-nokogiri ruby-sqlite3 \
                      mpg123 sqlite3 libncurses5
      gem install ektoplayer
      ```

### OpenSuse
   * using gem:

      ```
      zypper in ruby ruby-devel gcc sqlite3 sqlite3-devel ncurses ncurses-devel zlib zlib-devel \
                mpg123 
      gem install ffi-curses ektoplayer
      ```

## Configuration

Ektoplayer keeps it's default configuration file under `~/.config/ektoplayer/ektoplayer.rc`.

Available configuration commands:
   * `set <option> <value>`
   * `bind <window> <key> <command>`
   * `undbind <window> <key>`
   * `unbind_all`
   * `color <name> <fg> [<bg> [<attribute> ...]]`
   * `color_mono <name> <fg> [<bg> [<attribute> ...]]`
   * `color_256 <name> <fg> [<bg> [<attribute> ...]]`

See [ektoplayer.rc](https://github.com/braph/ektoplayer/blob/master/doc/ektoplayer.rc) for a configuration file with the default values.

## Authors

  * [Benjamin Abendroth](https://github.com/braph)

## See also

  * Ektoplayer was inspired by [Soundcloud2000](https://github.com/grobie/soundcloud2000) and [ncmpcpp](https://github.com/arybczak/ncmpcpp)
