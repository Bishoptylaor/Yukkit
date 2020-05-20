#!/bin/bash

set -ex

scripts/clean.sh

touch .gitmodules
git submodule add https://hub.spigotmc.org/stash/scm/spigot/bukkit.git modules/Bukkit
git submodule add https://hub.spigotmc.org/stash/scm/spigot/craftbukkit.git modules/CraftBukkit
git submodule add https://hub.spigotmc.org/stash/scm/spigot/builddata.git modules/BuildData
git submodule add https://hub.spigotmc.org/stash/scm/spigot/spigot.git modules/Spigot
git submodule add https://github.com/PaperMC/Paperclip.git modules/Paperclip
git submodule add https://github.com/PaperMC/Paper.git modules/Paper
git submodule update --init --force

( cd modules/Bukkit && git switch --detach 558fdf5f54b0f527cd48903daf9368ac4b862876 )
( cd modules/CraftBukkit && git switch --detach acbc348e925cbdbae41b2055d60bbe40031d470c )
( cd modules/BuildData && git switch --detach be360cc298a06b5355ecd057f5b1feb894a73f0f )
( cd modules/Spigot && git switch --detach 79a30d7d26b9078dbf6071cbbfa060673bf117b2 )
( cd modules/Paper && git switch --detach 77cce8236ff09d52730b66c7a146265ce3415185 )
git add modules

git submodule status
