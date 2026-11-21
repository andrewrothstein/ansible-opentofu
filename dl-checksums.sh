#!/usr/bin/env sh
set -e
DIR=$(mktemp -d)
trap 'rm -rf "$DIR"' EXIT
MIRROR="https://github.com/opentofu/opentofu/releases/download"

dl() {
    local ver=$1
    local lchecksums=$2
    local os=$3
    local arch=$4
    local archive_type=${5:-zip}
    local platform="${os}_${arch}"
    local file="tofu_${ver}_${platform}.${archive_type}"
    # https://github.com/opentofu/opentofu/releases/download/v1.6.0/tofu_1.6.0_linux_amd64.zip
    local url=$MIRROR/v$ver/$file
    local sum
    sum=$(awk -v f="$file" '$2 == f || $2 == "*" f {print $1}' "$lchecksums")
    # openbsd_386 stopped being published in 1.12.12; older versions still have it
    if [ -z "$sum" ] && [ "$platform" = "openbsd_386" ]
    then
        return 0
    fi
    if ! printf '%s' "$sum" | grep -Eq '^[0-9a-f]{64}$'
    then
        echo "bad or missing checksum for $file: '$sum'" >&2
        exit 1
    fi
    printf "    # %s\n" "$url"
    printf "    %s: sha256:%s\n" "$platform" "$sum"
}

dl_ver() {
    local ver=$1
    local checksums="tofu_${ver}_SHA256SUMS"

    # https://github.com/opentofu/opentofu/releases/download/v1.6.0/tofu_1.6.0_SHA256SUMS
    local url=$MIRROR/v$ver/$checksums

    local lchecksums=$DIR/$checksums
    curl -fsSL --proto '=https' --tlsv1.2 -o "$lchecksums" "$url"

    printf "  # %s\n" $url
    printf "  '%s':\n" $ver

    dl $ver $lchecksums darwin amd64
    dl $ver $lchecksums darwin arm64
    dl $ver $lchecksums freebsd arm
    dl $ver $lchecksums freebsd 386
    dl $ver $lchecksums freebsd amd64
    dl $ver $lchecksums linux 386
    dl $ver $lchecksums linux amd64
    dl $ver $lchecksums linux arm
    dl $ver $lchecksums linux arm64
    dl $ver $lchecksums openbsd 386
    dl $ver $lchecksums openbsd amd64
    dl $ver $lchecksums solaris amd64
    dl $ver $lchecksums windows 386
    dl $ver $lchecksums windows amd64
}

dl_ver ${1:-1.13.9}
