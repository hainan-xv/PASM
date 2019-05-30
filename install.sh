#!/bin/bash

mkdir -p tools
cd tools

git clone https://github.com/clab/fast_align.git

cd fast_align

mkdir build
cd build
cmake ..
make
