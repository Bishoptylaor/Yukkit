#!/bin/bash

set -ex

scripts/init.sh

top="$(pwd -P)"

(
  mkdir -p work
  cd work

  if [ ! -d data ]; then
    cp -r "$top"/modules/BuildData data
  fi

  working="$(pwd -P)"
  ver=$(jq -r '.minecraftVersion' data/info.json)

  if [ ! -f "$ver".jar ]; then
    curl -o "$ver".jar "$(jq -r '.serverUrl' data/info.json)"
    [ "$(md5sum "$ver".jar | cut -d ' ' -f 1)" = "$(jq -r '.minecraftHash' data/info.json)" ] || return
  fi

  if [ ! -f "$ver"-class.jar ]; then
    java -jar data/bin/SpecialSource-2.jar map \
      -i "$ver".jar \
      -m data/mappings/"$(jq -r '.classMappings' data/info.json)" \
      -o "$ver"-class.jar
  fi

  if [ ! -f "$ver"-member.jar ]; then
    java -jar data/bin/SpecialSource-2.jar map \
      -i "$ver"-class.jar \
      -m data/mappings/"$(jq -r '.memberMappings' data/info.json)" \
      -o "$ver"-member.jar
  fi

  if [ ! -f "$ver"-mapped.jar ]; then
    java -jar data/bin/SpecialSource.jar \
      --kill-lvt \
      -i "$ver"-member.jar \
      --access-transformer data/mappings/"$(jq -r '.accessTransforms' data/info.json)" \
      -m data/mappings/"$(jq -r '.packageMappings' data/info.json)" \
      -o "$ver"-mapped.jar
  fi

  mvn install:install-file \
    -Dfile="$working"/"$ver"-mapped.jar \
    -Dpackaging=jar \
    -DgroupId=org.spigotmc \
    -DartifactId=minecraft-server \
    -Dversion="$ver"-SNAPSHOT

  if [ ! -d nms ]; then
    mkdir -p nms
    (
      cd nms
      jar -xf "$working"/"$ver"-mapped.jar net/minecraft/server
      java -jar "$working"/data/bin/fernflower.jar -dgs=1 -hdc=0 -asc=1 -udv=0 . .
      find . -type f -iname '*.class' -print0 | xargs -0 rm -f
    )
  fi

  if [ ! -d cb ]; then
    cp -r "$top"/modules/CraftBukkit cb
  fi
)
