#!/bin/sh -e
# vim: set et sw=2 ts=2:

# Get the url to latest release tarball
UTPLSQL_GITHUB_API=https://api.github.com/repos/utPLSQL/utPLSQL/releases/latest
UTPLSQL_DOWNLOAD_URL=$(
    curl --silent $UTPLSQL_GITHUB_API          \
  | awk '/browser_download_url/ { print $2 }'  \
  | tr -d \" | grep .tar.gz$)

# Download the latest release tarball
curl -Lks "${UTPLSQL_DOWNLOAD_URL}" -o utPLSQL.tar.gz

# Extract downloaded tarball
tar xzf utPLSQL.tar.gz
