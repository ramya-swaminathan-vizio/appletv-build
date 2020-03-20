#!/bin/bash
##############################################################################
# build appletv 
#
# usage: build.sh --target=vs-sx7a|vs-sx7b|mtk-5581|mtk-5597|mtk2020
#                [--release-ver=<version>]
#                [--dev]
#                [--enable-debug]
#                [--rc]
#                [--clean]
#
#        If --release-ver is not specified, a development tarball is created
#
# This script assumes this directory structure:
#   <basedir>/ ........................ pre-exists
#   <basedir>/build/ .................. pre-exists, VS build scripts
#   <basedir>/appletv-build/ .......... pre-exists, appletv build scripts
#   <basedir>/appletv_basic_egl/ .................... pre-exists, appletv_basic_egl source
#   <basedir>/sx7_sdk/ ................ pre-exists, VS SDK --not needed for appletv
#
#   <basedir>/appletv_out/basic-egl/ ........... created, appletv build output--not used as vizio not building 
#   <basedir>/appletv_install/dev/ ............ created, dev image files
#   <basedir>/appletv_install/img/ ............ created, install image files
#   <basedir>/appletv_install/img/dragonfly/ .. created, VS .img files
#   <basedir>/appletv_install/img/leo/ ........ created, VS .img files
#   <basedir>/appletv_install/work/ ........... created, general workspace
#   <basedir>/appletv_install/work/basic-egl/ .. created, base installation files
#
##############################################################################

#-----------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------

ME=$(basename $0)
MYDIR=$(realpath $(dirname $0))
TARGET=vs-sx7b
MAKE_CLEAN=0
ENABLE_CHROMIUM_DEBUG=0
IS_DEV_BUILD=0
IS_RC_BUILD=0

APPLETV_FILES="
basic-egl
nadk-update-app-list
libCoreFP.so
libCoreADI.so
app_config.xml
setenv.sh
basic-egl.sh
"

APPLETV_PAK_DIRS="
basic-egl
"
VENDOR_FILES_UNUSED="
"

#-----------------------------------------------------------------------------
# functions
#-----------------------------------------------------------------------------

usage()
{
  rc=$1
  shift
  msg="$*"
  test -n "$msg" && echo $msg && echo
  echo "usage: $ME --target=vs-sx7a|vs-sx7b|mtk-5581|mtk-5597|mtk2020 [--release-ver=<version>] [--dev] [--clean]
"
  exit $rc
}


die()
{
  rc=$1
  shift
  msg="$*"
  test -n "$msg" && echo "!! $msg" && echo
  exit $rc
}

set_target()
{
  target=$1
  case $target in
    vs-sx7a|VS-SX7A)   TARGET=vs-sx7a ; incl=build-vs.incl      ;;
    vs-sx7b|VS-SX7B)   TARGET=vs-sx7b ; incl=build-vs.incl      ;;
    mtk-5581|MTK-5581) TARGET=mtk-5581; incl=build-mtk.incl     ;;
    mtk-5597|MTK-5597) TARGET=mtk-5597; incl=build-mtk.incl     ;;
    mtk2020|MTK2020)   TARGET=mtk2020 ; incl=build-mtk2020.incl ;;
    *) usage 2 "Error: unsupported target: '$1'" ;;
  esac
}

set_release_ver()
{
  RELEASE_VER=$1
  echo "RAMYA Iam in set_release_ver() RELEASE_VER= "$RELEASE_VER
}

set_symdir()
{
  SYMDIR=$1
}

parse_arguments()
{
  for arg in $*
  do
    case $arg in
      --target=*)      set_target `echo $arg | awk -F = '{print $2}'` ;;
      --release-ver=*) set_release_ver `echo $arg | awk -F = '{print $2}'` ;;
      --symdir=*)      set_symdir `echo $arg | awk -F = '{print $2}'` ;;
      --enable-debug)  ENABLE_CHROMIUM_DEBUG=1 ;;
      --dev)           IS_DEV_BUILD=1 ;;
      --rc)            IS_RC_BUILD=1 ;;
      --clean)         MAKE_CLEAN=1 ;;
      --help)          usage 0 ;;
      *)               usage 1 "Error: unsupported flag: '$arg'" ;;
    esac
  done
}

banner()
{
  echo "
==============================================================================
 $*
==============================================================================
"
}

show_settings()
{
  case "$TARGET" in
    "mtk-5581") target="MediaTek 5581" ;;
    "mtk-5597") target="MediaTek 5597" ;;
    "mtk2020")  target="MediaTek 2020" ;;
    "vs-sx7a")  target="V-Silicon SX7A" ;;
    "vs-sx7b")  target="V-Silicon SX7B" ;;
    *)          target="Unknown" ;;
  esac

  release="development tarball"
  test -n "$RELEASE_VER" && release="installable image version $RELEASE_VER"

  banner "Building $target $release"

}

make_clean()
{
  rm -rf $APPLETV_INSTALL_IMG_DIR
}


#=============================================================================
# start of execution
#=============================================================================
parse_arguments $*

# set up platform-independent environment variables
APPLETV_BUILD_ROOT=$(realpath $(dirname $0))
APPLETV_ROOT=`realpath $APPLETV_BUILD_ROOT/..`
#CONJURE_EXTRAS_DIR=`realpath $CONJURE_BUILD_ROOT/extras`

mkdir -p $APPLETV_ROOT/appletv_basic_egl
APPLETV_BASICEGL_ROOT=$APPLETV_ROOT/appletv_basic_egl
mkdir -p $APPLETV_ROOT/appletv_out
APPLETV_BASICEGLOUT_DIR=$APPLETV_ROOT/appletv_out

mkdir -p $APPLETV_ROOT/appletv_install/work
APPLETV_IMG_WORKDIR=$APPLETV_ROOT/appletv_install/work

mkdir -p $APPLETV_ROOT/appletv_install/img
APPLETV_INSTALL_IMG_DIR=$APPLETV_ROOT/appletv_install/img

mkdir -p $APPLETV_ROOT/appletv_install/dev
APPLETV_DEV_IMG_DIR=$APPLETV_ROOT/appletv_install/dev

# set up platform-dependent environment variables & functions
source $APPLETV_BUILD_ROOT/$incl

show_settings

if [ $MAKE_CLEAN -ne 0 ]; then
  banner "Cleaning up previous builds"
  make_clean
fi


if [ -n "$RELEASE_VER" ]; then
  banner "Untar build from appletv"
  #untaring to dest dir APPLETV_BASICEGL_ROOT = "$APPLETV_BASICEGL_ROOT
  tar -C $APPLETV_BASICEGL_ROOT -xvf $APPLETV_BASICEGL_ROOT/basic-egl.tar --exclude='.*DS_Store'
  banner "Building installable image"
  # build_install_img sets $FINAL_IMG_FILE
  build_install_img $RELEASE_VER $APPLETV_INSTALL_IMG_DIR
  banner "Installable image:
$FINAL_IMG_FILE"

else
  banner "Untar build from appletv"
  #untaring to dest dir APPLETV_BASICEGL_ROOT = "$APPLETV_BASICEGL_ROOT
  tar -C $APPLETV_BASICEGL_ROOT -xvf $APPLETV_BASICEGL_ROOT/basic-egl.tar --exclude='.*DS_Store'
  banner "Building development tarball"
  build_dev_tarball $APPLETV_DEV_IMG_DIR
  banner "Development tarball:
`ls $RELEASE_VER $APPLETV_DEV_IMG_DIR/*tgz`"
fi
