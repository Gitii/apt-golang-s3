#!/bin/bash
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e # Exit on non-zero return codes
set -u # Exit on undefined variables

PACKAGE_NAME=apt-golang-s3
VERSION=${1:-1}
ARCH=${2:-amd64}

# Set Go cross-compilation environment variables if not already set
export GOOS=${GOOS:-linux}
export GOARCH=${GOARCH:-$ARCH}
export CGO_ENABLED=${CGO_ENABLED:-0}

# Convert architecture names for fpm compatibility
case $ARCH in
  amd64)
    FPM_ARCH=amd64
    ;;
  arm64)
    FPM_ARCH=arm64
    ;;
  arm)
    FPM_ARCH=armhf
    ;;
  *)
    FPM_ARCH=$ARCH
    ;;
esac

go get

go build -ldflags '-s -w' -o $PACKAGE_NAME

chmod +x ./$PACKAGE_NAME

fpm -s dir \
  --output-type deb \
  --force \
  --description "An apt transport method for downloading packages from repositories hosted in s3. Written in Go." \
  --name $PACKAGE_NAME \
  --version $VERSION \
  --maintainer fabric-infrastructure-team \
  --replaces apt-transport-s3 \
  --url https://github.com/google/apt-golang-s3 \
  --vendor "Google Fabric" \
  --architecture $FPM_ARCH \
  ./$PACKAGE_NAME=/usr/lib/apt/methods/s3 ${@:3}
