# Ektoplayer

Ektoplayer is a console audio player for [ektplazm.com](http://www.ektoplazm.com).

![Screenshot 2017-03-16](http://pixelbanane.de/yafu/118231024/ekto1.png)
![Screenshot 2017-03-16](http://pixelbanane.de/yafu/324630271/ekto2.png)

## Requirements

  * Ruby (1.9)
  * Portaudio (19)
  * Mpg123 (1.14)

## Installation

Assuming you have Ruby/Rubygems installed, you need portaudio and mpg123 as
library to compile the native extensions.

### OSX (not yet tested)

    xcode-select --install
    brew install portaudio
    brew install mpg123
    gem install ektoplayer

### Debian / Ubuntu (not yet tested)

    apt-get install portaudio19-dev libmpg123-dev libncurses-dev ruby1.9.1-dev
    gem install ektoplayer

## Features

  * Browse ektoplazm by artists/albums/styles
  * Vi-Bindings
  * Mouse is supported
  * 256 colors are supported
  * Local sound file cache
  * Highly configurable

## Authors

  * [Benjamin Abendroth](https://github.com/braph)

## See also

  * [Soundcloud2000](https://github.com/grobie/soundcloud2000)
  * [Audite](https://github.com/georgi/audite)

