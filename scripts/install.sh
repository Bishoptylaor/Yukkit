#!/bin/bash

set -ex

scripts/init.sh

mkdir -p work
if [ ! -d work/submods ]; then
  cp -rf modules work/submods
fi

(
  cd work

  working="$(pwd -P)"
  builddata="$working"/submods/BuildData
  ver=$(jq -r '.minecraftVersion' "$builddata"/info.json)

  if [ ! -f "$ver".jar ]; then
    curl -o "$ver".jar "$(jq -r '.serverUrl' "$builddata"/info.json)"
    [ "$(md5sum "$ver".jar | cut -d ' ' -f 1)" = "$(jq -r '.minecraftHash' "$builddata"/info.json)" ] || return
  fi

  if [ ! -f "$ver"-class.jar ]; then
    java -jar "$builddata"/bin/SpecialSource-2.jar map \
      -i "$ver".jar \
      -m "$builddata"/mappings/"$(jq -r '.classMappings' "$builddata"/info.json)" \
      -o "$ver"-class.jar
  fi

  if [ ! -f "$ver"-member.jar ]; then
    java -jar "$builddata"/bin/SpecialSource-2.jar map \
      -i "$ver"-class.jar \
      -m "$builddata"/mappings/"$(jq -r '.memberMappings' "$builddata"/info.json)" \
      -o "$ver"-member.jar
  fi

  if [ ! -f "$ver"-mapped.jar ]; then
    java -jar "$builddata"/bin/SpecialSource.jar \
      --kill-lvt \
      -i "$ver"-member.jar \
      --access-transformer "$builddata"/mappings/"$(jq -r '.accessTransforms' "$builddata"/info.json)" \
      -m "$builddata"/mappings/"$(jq -r '.packageMappings' "$builddata"/info.json)" \
      -o "$ver"-mapped.jar
  fi

  (
    cd submods/CraftBukkit
    mvn install:install-file \
      -Dfile="$working"/"$ver"-mapped.jar \
      -Dpackaging=jar \
      -DgroupId=org.spigotmc \
      -DartifactId=minecraft-server \
      -Dversion="$ver"-SNAPSHOT
  )
)
