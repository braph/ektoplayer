#!/bin/bash

set -e

rm -f ektoplayer-*.gem
gem build ektoplayer.gemspec
gem push  ektoplayer-*.gem
rm -f ektoplayer-*.gem
