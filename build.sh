#!/usr/bin/env bash

docker build -t tidbyt .
docker save tidbyt:latest | gzip > tidbyt.tar.gz
