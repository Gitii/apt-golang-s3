# apt-golang-s3

_An s3 transport method for the `apt` package management system_

[![Build Status](https://travis-ci.org/google/apt-golang-s3.svg?branch=master)](https://travis-ci.org/google/apt-golang-s3)
[![Go Report Card](https://goreportcard.com/badge/github.com/google/apt-golang-s3)](https://goreportcard.com/report/github.com/google/apt-golang-s3)
[![GoDoc](https://godoc.org/github.com/google/apt-golang-s3?status.svg)](https://godoc.org/github.com/google/apt-golang-s3)

The apt-golang-s3 project provides support for hosting private
[apt](https://en.wikipedia.org/wiki/APT_(Debian)) repositories in
[Amazon S3](https://aws.amazon.com/s3/). This is useful if you have private
packages, vendored public packages, or forks of public packages that your
software or business depend on. There are several opensource projects that
solve this problem, but they come with some limitations.

1. They are unmaintained.
1. They don't support the S3v4 request signature method.
1. They are written in a language that requires a runtime or other dependencies.

This project is an attempt to address those limitations.

## TL;DR
1. Build the binary `$ go build -o apt-golang-s3 main.go`
1. Install the binary `$ sudo cp apt-golang-s3 /usr/lib/apt/methods/s3`
1. Add your s3 based source to a package list `$ echo "deb s3://access-key:access-secret@s3.amazonaws.com/private-repo-bucket stable main" > /etc/apt/sources.list.d/private-repo.list`
1. Update and install packages `$ sudo apt-get update && sudo apt-get install your-private-package`

## Building the go program

There is an included Dockerfile to setup an environment for building the binary
in a sandboxed environment:

```
$ ls
Dockerfile  main.go  method  README.md

$ docker build -t apt-golang-s3 .
...

$ docker run -it --rm -v $(pwd):/app apt-golang-s3 bash

root@83823fffd369:/app# ls
Dockerfile  README.md  build-deb.sh  go.mod  go.sum  main.go  method

root@83823fffd369:/app# go build -o apt-golang-s3 main.go
...

root@83823fffd369:/app# ls
Dockerfile  README.md  apt-golang-s3  build-deb.sh  go.mod  go.sum  main.go  method

root@83823fffd369:/app# exit
exit

$ ls
apt-golang-s3  build-deb.sh  Dockerfile  go.mod  go.sum  main.go  method  README.md
```

## Building a debian package

For convenience, there is a small bash script in the repository that can build
the binary and package it as a .deb.

```
$ ls
build-deb.sh  Dockerfile  go.mod  go.sum  main.go  method  README.md

$ docker build -t apt-golang-s3 .

$ docker run -it --rm -v $(pwd):/app apt-golang-s3 /app/build-deb.sh
...
Created package {:path=>"apt-golang-s3_1_amd64.deb"}

$ ls
apt-golang-s3  apt-golang-s3_1_amd64.deb  build-deb.sh  Dockerfile  go.mod  go.sum  main.go  method  README.md
```

## Cross-compilation for Different Architectures

This project supports cross-compilation for different architectures to enable deployment on various platforms, including ARM-based devices like Raspberry Pi.

### Supported Architectures

- **amd64**: Intel/AMD 64-bit (default)
- **arm64**: ARM 64-bit (e.g., Raspberry Pi 4, Apple M1)
- **armhf**: ARM 32-bit (e.g., older Raspberry Pi models)

### Method 1: Using Docker with Build Arguments

Build for ARM64 (Raspberry Pi 4 and newer):
```bash
docker build --build-arg TARGETARCH=arm64 -t apt-golang-s3-arm64 .
docker run -it --rm -v $(pwd):/app apt-golang-s3-arm64 /app/build-deb.sh 1 arm64
```

Build for ARMHF (older Raspberry Pi models):
```bash
docker build --build-arg TARGETARCH=arm -t apt-golang-s3-armhf .
docker run -it --rm -v $(pwd):/app apt-golang-s3-armhf /app/build-deb.sh 1 arm
```

Build for AMD64 (default):
```bash
docker build -t apt-golang-s3 .
docker run -it --rm -v $(pwd):/app apt-golang-s3 /app/build-deb.sh
```

### Method 2: Using Docker Buildx (Multi-platform)

For building multiple architectures simultaneously:
```bash
# Enable buildx
docker buildx create --use

# Build for multiple platforms
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t apt-golang-s3 .

# Build specific architecture
docker buildx build --platform linux/arm64 -t apt-golang-s3-arm64 .
```

### Method 3: Direct Go Cross-compilation

For direct compilation without Docker:

ARM64 (Raspberry Pi 4+):
```bash
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -ldflags '-s -w' -o apt-golang-s3 main.go
```

ARMHF (older Raspberry Pi):
```bash
GOOS=linux GOARCH=arm CGO_ENABLED=0 go build -ldflags '-s -w' -o apt-golang-s3 main.go
```

AMD64 (default):
```bash
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -ldflags '-s -w' -o apt-golang-s3 main.go
```

### Method 4: Using the Enhanced build-deb.sh Script

The `build-deb.sh` script now supports an architecture parameter:

```bash
# Build for ARM64
./build-deb.sh 1.0.0 arm64

# Build for ARMHF
./build-deb.sh 1.0.0 arm

# Build for AMD64 (default)
./build-deb.sh 1.0.0
```

The script will automatically set the correct Go cross-compilation environment variables and package architecture.

### Architecture Verification

To verify the architecture of a compiled binary:
```bash
file apt-golang-s3
```

Expected outputs:
- **AMD64**: `ELF 64-bit LSB executable, x86-64`
- **ARM64**: `ELF 64-bit LSB executable, ARM aarch64`
- **ARMHF**: `ELF 32-bit LSB executable, ARM, EABI5`

### Installation on Target Systems

After building the architecture-specific package:

1. Transfer the `.deb` file to your target system
2. Install using `dpkg`:
   ```bash
   sudo dpkg -i apt-golang-s3_1_arm64.deb
   ```

For Raspberry Pi users, make sure to build for the correct architecture:
- Raspberry Pi 4 and newer: use `arm64`
- Raspberry Pi 3 and older: use `arm` (armhf)

## Installing in production

The `apt-golang-s3` binary is an executable. To install it copy it to
`/usr/lib/apt/methods/s3` on your computer. The .deb file produced by
`build-deb.sh` will install the method in the correct place.


## Configuration
### APT Repository Source Configuration

We recommend issuing a separate set of API keys, with read-only access, to the
S3 bucket that hosts your repository. The keys are specified in the apt sources
list configuration as follows:

```
$ cat /etc/apt/sources.list.d/my-private-repo.list
deb s3://aws-access-key-id:aws-secret-access-key@s3.amazonaws.com/my-private-repo-bucket stable main
```

### APT Method Configuration

The current default AWS region is set to `us-east-1`, but can be overridden by
adding an option in your apt configuration, e.g.

```plain
echo "Acquire::s3::region us-east-1;" > /etc/apt/apt.conf.d/s3
```

You may also override the endpoint used for S3 requests. This is useful when
connecting to S3-compatible services.

```plain
echo "Acquire::s3::endpoint https://minio.example.com;" > /etc/apt/apt.conf.d/s3
```

Alternatively, you may specify an IAM role to assume before connecting to S3.
The role will be assumed using the default credential chain; this option is
mutually exclusive with static credentials in the S3 URL.

```plain
echo "Acquire::s3::role arn:aws:iam::123456789012:role/s3-apt-reader;" > /etc/apt/apt.conf.d/s3
```

Additional configuration options may be added in the future.

## How it works

Apt creates a child process using the `/usr/lib/apt/methods/s3` binary and
writes to that processes standard input using a specific protocol. The method
interprets the input, downloads the requested files, and communicates back to
apt by writing to its standard output. The protocol spec is available here
[http://www.fifi.org/doc/libapt-pkg-doc/method.html/ch2.html](http://www.fifi.org/doc/libapt-pkg-doc/method.html/ch2.html).

## Similar Projects
* [https://github.com/kyleshank/apt-transport-s3](https://github.com/kyleshank/apt-transport-s3)
* [https://github.com/brianm/apt-s3](https://github.com/brianm/apt-s3)
* [https://github.com/BashtonLtd/apt-transport-s3](https://github.com/BashtonLtd/apt-transport-s3)
* [https://github.com/lucidsoftware/apt-boto-s3/](https://github.com/lucidsoftware/apt-boto-s3/)

## Disclaimer
This is not an officially supported Google product.
