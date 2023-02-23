#!/bin/bash

docker run -d -it \
	-p 3690:3690 \
	-p 443:443 \
	-p 80:80 \
    -v /etc/localtime:/etc/localtime \
	--name svn \
	tangramor/svn_ssl_admin:alma8