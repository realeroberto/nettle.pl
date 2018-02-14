#!/bin/sh -e
# vim: set et sw=2 ts=2:

# Get the url to latest release "zip" file
UTPLSQL_GITHUB_API=https://api.github.com/repos/utPLSQL/utPLSQL/releases/latest
UTPLSQL_DOWNLOAD_URL=$(
    curl --silent $UTPLSQL_GITHUB_API          \
  | awk '/browser_download_url/ { print $2 }'  \
  | grep ".zip" | sed 's/"//g')

# Download the latest release "zip" file
curl -Lk "${UTPLSQL_DOWNLOAD_URL}" -o utPLSQL.zip

# Extract downloaded "zip" file
unzip -q utPLSQL.zip
