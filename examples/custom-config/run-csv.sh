#!/bin/sh
ponyc -V1 --runtimebc && \
  ./custom-config --ponynoyield -csv | tee data.csv
