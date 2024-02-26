#!/bin/bash

docker build -t tangramor/svn_ssl_admin:alma9 -f Dockerfile.alma9 .

docker tag tangramor/svn_ssl_admin:alma9 tangramor/svn_ssl_admin:latest