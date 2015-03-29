#!/bin/sh


rm -f _build/*
rm -f build.tmp
find . -name '*.lslp' -exec echo ./build.pl \"{}\" \"_build\" \; > build.tmp
sh build.tmp
rm build.tmp
