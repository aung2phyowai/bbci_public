#!/bin/bash

echo "Generating .php file from bib file"
python generate_bsdlab_publications.py
echo "Done!"

echo "Login to the webserver"
HOST=www.bsdlab.uni-freiburg.de
USER=wsbsdlab
sftp -v $USER"@"$HOST << EOT
ascii
prompt
cd /u/www/www.bsdlab.uni-freiburg.de/htdocs/publications
ls -la
put index.php
bye
EOT
