#!/bin/sh
#@Note Generated documentation branch at github by
#```
#mkdir ../docs #Which is in a pan_ip_switchtopology_proj parent directory, along with the pan_ip_switch_topology repo directory.
#cd ../docs
#git init
#git remote add origin git@github.com:nesi/pan_ip_switchtopology.git
#git fetch origin
#git checkout --orphan gh-pages
#```
#Now we have a documentation branch we can created documentation in, and check into git.
#Git will make this available at http://nesi.github.io/pan_ip_switchtopology/
#
/usr/local/bin/yard doc *.rb rlib/*.rb generators/*.rb --output-dir docs #Generate the documentation.

cp -r docs/* ../doc #This is the git repo with the documentation branch checked out.
rm -rf docs/* #We clean out the local copy of the docs, so the next run doesn't have stray files in it.
( cd ../doc; git add . ; git commit -a --allow-empty-message -m ""; git push origin gh-pages ) #Check in the doc branch.


