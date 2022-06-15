#!/usr/bin/env sh

if [ -z "$1" ]
  then
    echo "No argument supplied"
    exit 1;
fi

# Abort on errors
set -e
# Build
yarn run build
# Navigate into the build output directory
cd dist
# If you are deploying to a custom domain
# echo 'www.example.com' > CNAME
git init
git add -A
git commit -m $1
git push -f git@github.com:brandiny/pure_css_smoothed_corners.git master:gh-pages
cd - 