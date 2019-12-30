#!/bin/bash

function create(){
    cd /[PATH TO create.py]
    python3 create.py $1 #Using python3 to open create.py file
    cd /Users/[PATH TO FOLDER]/$1 #Make sure you have path to go to
    #Execute boilerplate git code + initial commit
    git init
    git remote add origin git@github.com:[USERNAME]/$1.git
    touch README.md
    git add .
    git commit -m "Initial commit"
    git push -u origin master
}
