#!/bin/bash

cd ../bib_files
ls
filename="./macros/journal_macros_short.bib"
cat $filename | sed "s/@string{//" | sed "s/ = /\t/" | sed -r "s/\"}//" | sed -r "s/\"//" | cut -f 2
