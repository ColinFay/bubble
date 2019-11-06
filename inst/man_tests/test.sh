#!/bin/bash

R -e 'devtools::build("../../", path = ".")'

docker build -t bubble .

docker run bubble

rm bubble_*tar.gz
