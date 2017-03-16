# Ektoplayer

Ektoplayer is a console audio player for [ektplazm.com](http://www.ektoplazm.com).

![Screenshot 2017-03-16](http://pixelbanane.de/yafu/2856546263/ekto_1.png)
![Screenshot 2017-03-16](http://pixelbanane.de/yafu/3175329883/ekto_2.png)

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
  * Mouse is supported
  * Colors are supported (up to 256!)
  * Local sound file cache
  * Vi-Bindings
  * Highly configurable

## Authors

  * [Benjamin Abendroth](https://github.com/braph)

## See also

  * [Soundcloud2000](https://github.com/grobie/soundcloud2000)
  * [Audite](https://github.com/georgi/audite)

