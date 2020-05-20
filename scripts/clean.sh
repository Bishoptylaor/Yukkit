#!/bin/bash

set -ex

if [ -f .gitmodules ]; then
  git submodule deinit --force --all
fi

rm -rf .git/modules
rm -f .gitmodules
rm -rf modules

git rm --ignore-unmatch .gitmodules
git rm -r --ignore-unmatch modules
