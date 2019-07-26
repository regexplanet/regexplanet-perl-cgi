#!/bin/bash

docker build -t regexplanet-perl .
docker run \
	--hostname perl.regexplanet.com \
	--publish 4000:8080 \
	--expose 4000 \
	--env  PORT='8080' \
	--env COMMIT=$(git rev-parse --short HEAD) \
	--env LASTMOD=$(date -u +%Y-%m-%dT%H:%M:%SZ) \
	--mount type=bind,source="$(pwd)"/www,destination=/var/www \
	regexplanet-perl
