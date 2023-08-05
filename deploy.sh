#!bin/bash

ssh tps@do rm -rf /data/www/alpha/*
scp -r ./dist/* tps@do:/data/www/alpha