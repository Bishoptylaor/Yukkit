#!/bin/bash

set -ex

scripts/init.sh

working=$(pwd -P)
ver=$(jq -r .minecraftVersion modules/BuildData/info.json)

if [ ! -f nms-"$ver".jar ]; then
  curl -o nms-"$ver".jar "$(jq -r .serverUrl modules/BuildData/info.json)"
  [ "$(md5sum nms-"$ver".jar | cut -d ' ' -f 1)" = "$(jq -r .minecraftHash modules/BuildData/info.json)" ]
fi

if [ ! -f nms-"$ver"-class.jar ]; then
  java -jar modules/BuildData/bin/SpecialSource-2.jar map \
    -i nms-"$ver".jar \
    -m modules/BuildData/mappings/"$(jq -r .classMappings modules/BuildData/info.json)" \
    -o nms-"$ver"-class.jar
fi

if [ ! -f nms-"$ver"-member.jar ]; then
  java -jar modules/BuildData/bin/SpecialSource-2.jar map \
    -i nms-"$ver"-class.jar \
    -m modules/BuildData/mappings/"$(jq -r .memberMappings modules/BuildData/info.json)" \
    -o nms-"$ver"-member.jar
fi

if [ ! -f nms-"$ver"-mapped.jar ]; then
  java -jar modules/BuildData/bin/SpecialSource.jar \
    --kill-lvt \
    -i nms-"$ver"-member.jar \
    --access-transformer modules/BuildData/mappings/"$(jq -r .accessTransforms modules/BuildData/info.json)" \
    -m modules/BuildData/mappings/"$(jq -r .packageMappings modules/BuildData/info.json)" \
    -o nms-"$ver"-mapped.jar
fi

(
  mvntmp=$(mktemp -d)
  mkdir -p "$mvntmp"
  cd "$mvntmp"
  mvn install:install-file \
    -Dfile="$working"/nms-"$ver"-mapped.jar \
    -Dpackaging=jar \
    -DgroupId=org.spigotmc \
    -DartifactId=minecraft-server \
    -Dversion="$ver"-SNAPSHOT
)

if [ ! -d nms ]; then
  (
    mkdir -p nms/class
    cd nms/class
    jar -xf "$working"/nms-"$ver"-mapped.jar net/minecraft/server
  )
  (
    mkdir -p nms/src
    cd nms
    java -jar "$working"/modules/BuildData/bin/fernflower.jar -dgs=1 -hdc=0 -asc=1 -udv=0 class src
  )
fi

reset_branch() {
  branch=$1
  if [ "$(git branch --list "$branch")" ]; then
    git branch -D "$branch"
  fi
  git switch -C "$branch"
}

(
  cd modules/CraftBukkit

  src=src/main/java
  nmspkg=net/minecraft/server

  # *craftbukkit
  git switch -C craftbukkit
  git switch --detach HEAD

  # *cbnms: NMS + *craftbukkit < nms-patches(CraftBukkit)
  git switch craftbukkit
  reset_branch cbnms

  rm -rf ${src:?}/$nmspkg
  mkdir -p $src/$nmspkg

  find nms-patches -mindepth 1 -maxdepth 1 -type f -iname '*'.patch -print0 | \
    xargs -0 -P 0 basename -z -s .patch | \
    xargs -0 -P 0 -I {} /bin/bash -c \
      "cp -v $working/nms/src/$nmspkg/{}.java $src/$nmspkg && patch $src/$nmspkg/{}.java < nms-patches/{}.patch"

  git add $src
  git commit --message "NMS + CraftBukkit < nms-patches(CraftBukkit) | $(date)"

  git switch --detach craftbukkit

  # *spigot: *cbnms < CraftBukkit-Patches(Spigot)
  git switch cbnms
  reset_branch spigot

  find "$working"/modules/Spigot/CraftBukkit-Patches -mindepth 1 -maxdepth 1 -type f -iname '*'.patch -print0 | \
    xargs -0 git am --3way

  git switch --detach craftbukkit

  # *paper: *spigot + mcdev imports < Spigot-Server-Patches(Paper)
  git switch spigot
  reset_branch paper

  imports=(
    AxisAlignedBB
    BaseBlockPosition
    BiomeBase
    BlockBed
    BiomeBigHills
    BiomeJungle
    BiomeMesa
    BlockBeacon
    BlockChest
    BlockFalling
    BlockFurnace
    BlockIceFrost
    BlockObserver
    BlockPosition
    BlockRedstoneComparator
    BlockSnowBlock
    BlockStateEnum
    ChunkCache
    ChunkCoordIntPair
    ChunkProviderFlat
    ChunkProviderGenerate
    ChunkProviderHell
    CombatTracker
    CommandAbstract
    CommandScoreboard
    CommandWhitelist
    ControllerJump
    DataBits
    DataConverterMaterialId
    DataInspectorBlockEntity
    DataPalette
    DefinedStructure
    DragonControllerLandedFlame
    EnchantmentManager
    Enchantments
    EnderDragonBattle
    EntityIllagerIllusioner
    EntityLlama
    EntitySquid
    EntityTypes
    EntityWaterAnimal
    EntityWitch
    EnumItemSlot
    EULA
    FileIOThread
    IHopper
    ItemBlock
    ItemFireworks
    ItemMonsterEgg
    IRangedEntity
    LegacyPingHandler
    LotoSelectorEntry
    NavigationAbstract
    NBTTagCompound
    NBTTagList
    Packet
    PacketEncoder
    PacketPlayInUseEntity
    PacketPlayOutMapChunk
    PacketPlayOutPlayerListHeaderFooter
    PacketPlayOutScoreboardTeam
    PacketPlayOutTitle
    PacketPlayOutUpdateTime
    PacketPlayOutWindowItems
    PathfinderAbstract
    PathfinderGoal
    PathfinderGoalFloat
    PathfinderGoalGotoTarget
    PathfinderWater
    PersistentScoreboard
    PersistentVillage
    PlayerConnectionUtils
    RegionFile
    Registry
    RegistryBlockID
    RegistryMaterials
    RemoteControlListener
    RecipeBookServer
    ServerPing
    SoundEffect
    StructureBoundingBox
    StructurePiece
    StructureStart
    TileEntityEnderChest
    TileEntityLootable
    WorldGenStronghold
    WorldProvider
  )

  echo "${imports[@]}" | \
    tr ' ' '\n' | \
    xargs -P 0 -I {} cp -nv "$working"/nms/src/$nmspkg/{}.java $src/$nmspkg

  git add $src
  git commit --message "*spigot + mcdev imports | $(date)"

  find "$working"/modules/Paper/Spigot-Server-Patches -mindepth 1 -maxdepth 1 -type f -iname '*'.patch -print0 | \
    xargs -0 git am --3way

  git switch --detach craftbukkit

  # *yukkit
  git switch paper
  reset_branch yukkit
  git switch --detach craftbukkit
)

(
  cd modules/Bukkit

  # *bukkit
  git switch -C bukkit
  git switch --detach HEAD

  # *spigot-api: Bukkit < Bukkit-Patches(Spigot)
  git switch bukkit
  reset_branch spigot-api
  find "$working"/modules/Spigot/Bukkit-Patches -mindepth 1 -maxdepth 1 -type f -iname '*'.patch -print0 | xargs -0 git am --3way
  git switch --detach bukkit

  # *paper-api: *spigot-api < Spigot-API-Patches(Paper)
  git switch spigot-api
  reset_branch paper-api
  find "$working"/modules/Paper/Spigot-API-Patches -mindepth 1 -maxdepth 1 -type f -iname '*'.patch -print0 | xargs -0 git am --3way
  git switch --detach bukkit

  # *yukkit-api
  git switch paper-api
  reset_branch yukkit-api
  git switch --detach bukkit
)

rm -rf src
git clone --branch paper modules/CraftBukkit src/server
git clone --branch yukkit-api modules/Bukkit src/api
