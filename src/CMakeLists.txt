include(ExternalProject)

cmake_minimum_required(VERSION 3.1.0)

# by default, install to openmw-deps subfolder in build directory
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  if (OPENMW_DEPS_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
      set(CMAKE_INSTALL_PREFIX "${OPENMW_DEPS_BINARY_DIR}/openmw-deps" CACHE PATH "OPENMW_DEPS install prefix" FORCE)
  endif ()
endif ()

set(CMAKE_OSX_DEPLOYMENT_TARGET "10.9")
set(CMAKE_OSX_SYSROOT "macosx10.12")
set(CMAKE_CXX_STANDARD 11)

execute_process(COMMAND xcrun --show-sdk-path --sdk ${CMAKE_OSX_SYSROOT} OUTPUT_VARIABLE FULL_SYSROOT_PATH OUTPUT_STRIP_TRAILING_WHITESPACE)

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: Debug, Release" FORCE)
endif ()

set(CONFIGURE_WRAPPER "${OPENMW_DEPS_BINARY_DIR}/configure-wrapper.sh")
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/configure-wrapper.sh.in" ${CONFIGURE_WRAPPER} @ONLY)

set(PATCH_WRAPPER "${CMAKE_CURRENT_SOURCE_DIR}/patch-wrapper.sh")

set(SUBPROJECT_CMAKE_ARGS
  "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
  "-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}"
  "-DCMAKE_PREFIX_PATH=${CMAKE_INSTALL_PREFIX}"
  "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
  "-DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
  "-DCMAKE_MACOSX_RPATH=ON"
  "-DCMAKE_INSTALL_RPATH=${CMAKE_INSTALL_PREFIX}/lib"
  "-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}"
)

set(AUTOTOOLS_POSTBUILD_SCRIPT "${OPENMW_DEPS_BINARY_DIR}/autotools-postbuild.sh")
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/autotools-postbuild.sh" ${AUTOTOOLS_POSTBUILD_SCRIPT} COPYONLY)

set(BOOST_B2_USER_CONFIG "${OPENMW_DEPS_BINARY_DIR}/boost-user-config.jam")
set(BOOST_DARWIN_PATCH "${OPENMW_DEPS_BINARY_DIR}/boost.patch")
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/boost-user-config.jam.in" ${BOOST_B2_USER_CONFIG})
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/boost.patch" ${BOOST_DARWIN_PATCH} COPYONLY)

if (CMAKE_BUILD_TYPE EQUAL "Debug")
  set(BOOST_VARIANT "debug")
else ()
  set(BOOST_VARIANT "release")
endif ()

set(BOOST_BOOTSTRAP_ARGS
  "--without-icu"
  "--without-libraries=python,mpi"
)

set(BOOST_B2_ARGS
  "--prefix=${CMAKE_INSTALL_PREFIX}"
  "--user-config=${BOOST_B2_USER_CONFIG}"
  "--variant=${BOOST_VARIANT}"
  "--with-atomic"
  "--with-date_time"
  "--with-chrono"
  "--with-system"
  "--with-filesystem"
  "--with-program_options"
  "--with-thread"
  "install"
  "link=shared"
  "threading=multi"
)

ExternalProject_Add(
  boost
  URL https://downloads.sourceforge.net/project/boost/boost/1.60.0/boost_1_60_0.tar.bz2
  URL_HASH SHA256=686affff989ac2488f79a97b9479efb9f2abae035b5ed4d8226de6857933fd3b
  PATCH_COMMAND ${PATCH_WRAPPER} ${BOOST_DARWIN_PATCH}

  BUILD_IN_SOURCE 1
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/boost
  CONFIGURE_COMMAND ./bootstrap.sh ${BOOST_BOOTSTRAP_ARGS}
  BUILD_COMMAND ./b2 ${BOOST_B2_ARGS}
)

set(BULLET_CMAKE_ARGS "${SUBPROJECT_CMAKE_ARGS};-DBUILD_BULLET3=OFF;-DBUILD_BULLET2_DEMOS=OFF;-DBUILD_CPU_DEMOS=OFF;-DBUILD_EXTRAS=OFF")

ExternalProject_Add(
  bullet
  URL https://github.com/bulletphysics/bullet3/archive/2.86.1.tar.gz
  URL_HASH SHA256=c058b2e4321ba6adaa656976c1a138c07b18fc03b29f5b82880d5d8228fbf059

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/bullet
  CMAKE_ARGS ${BULLET_CMAKE_ARGS}
)

set(FFMPEG_CONFIGURE_ARGS
  "--prefix=${CMAKE_INSTALL_PREFIX}"
  "--disable-programs"
  "--disable-iconv"
  "--disable-doc"
  "--disable-demuxer=matroska"
  "--disable-network"
  "--disable-securetransport"
  "--disable-videotoolbox"
  "--extra-cflags=-Wno-shift-negative-value"
)

ExternalProject_Add(
  ffmpeg
  URL https://ffmpeg.org/releases/ffmpeg-2.8.1.tar.bz2
  URL_HASH SHA256=e2ed5ab28dee1af94336739173eb0019afc21a54e38a96f4e3208e94a07866e2

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg/configure ${FFMPEG_CONFIGURE_ARGS}
  BUILD_COMMAND make COMMAND sh ${AUTOTOOLS_POSTBUILD_SCRIPT}
)

ExternalProject_Add(
  libpng
  URL https://dl.bintray.com/homebrew/mirror/libpng-1.6.20.tar.xz
  URL_HASH SHA256=55c5959e9f3484d96141a3226c53bc9da42a4845e70879d3e1d6e94833d1918b

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libpng
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/libpng/configure --prefix=${CMAKE_INSTALL_PREFIX}
  BUILD_COMMAND make COMMAND sh ${AUTOTOOLS_POSTBUILD_SCRIPT}
)

ExternalProject_Add(
  freetype2
  DEPENDS libpng
  URL http://download.savannah.gnu.org/releases/freetype/freetype-2.6.tar.bz2
  URL_HASH SHA256=8469fb8124764f85029cc8247c31e132a2c5e51084ddce2a44ea32ee4ae8347e

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/freetype2
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/freetype2/configure --prefix=${CMAKE_INSTALL_PREFIX} --without-harfbuzz
  BUILD_COMMAND make COMMAND sh ${AUTOTOOLS_POSTBUILD_SCRIPT}
)

ExternalProject_Add(
  libjpeg
  URL http://www.ijg.org/files/jpegsrc.v8d.tar.gz
  URL_HASH SHA256=00029b1473f0f0ea72fbca3230e8cb25797fbb27e58ae2e46bb8bf5a806fe0b3

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg/configure --prefix=${CMAKE_INSTALL_PREFIX}
  BUILD_COMMAND make COMMAND sh ${AUTOTOOLS_POSTBUILD_SCRIPT}
)

set(MYGUI_CMAKE_ARGS "${SUBPROJECT_CMAKE_ARGS};-DMYGUI_RENDERSYSTEM=1;-DMYGUI_BUILD_DEMOS=OFF;-DMYGUI_BUILD_TOOLS=OFF;-DMYGUI_BUILD_PLUGINS=OFF")

ExternalProject_Add(
  mygui
  DEPENDS freetype2
  GIT_REPOSITORY https://github.com/MyGUI/mygui.git
  GIT_TAG 1c5a49c792c23d8b9b6760bb4877447c337e53f6
  PATCH_COMMAND ${PATCH_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/mygui.patch
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/mygui
  CMAKE_ARGS ${MYGUI_CMAKE_ARGS}
)

ExternalProject_Add(
  SDL2
  URL https://libsdl.org/release/SDL2-2.0.5.tar.gz
  URL_HASH SHA256=442038cf55965969f2ff06d976031813de643af9c9edc9e331bd761c242e8785
  PATCH_COMMAND ${PATCH_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/SDL2.patch

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/SDL2
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/SDL2/configure --prefix=${CMAKE_INSTALL_PREFIX} --without-x
  BUILD_COMMAND make COMMAND sh ${AUTOTOOLS_POSTBUILD_SCRIPT}
)

set(OSG_CMAKE_ARGS
  "${SUBPROJECT_CMAKE_ARGS}"
  "-DOSG_WINDOWING_SYSTEM=Cocoa"
  "-DOSG_USE_FLOAT_MATRIX=ON"
  "-DOSG_USE_FLOAT_PLANE=ON"
  "-DBUILD_OSG_APPLICATIONS=OFF"
  "-DBUILD_OSG_EXAMPLES=OFF"
  "-DOSG_CXX_LANGUAGE_STANDARD=C++${CMAKE_CXX_STANDARD}"
  "-DCMAKE_DISABLE_FIND_PACKAGE_FFmpeg=1"
)

ExternalProject_Add(
  openscenegraph
  URL https://github.com/OpenMW/osg/archive/0eff5bb794b5e7daf8a5801147fef7f876dd2ed6.zip
  URL_HASH SHA256=2e532acb5a46b55c57adaa75116a1755ba5b6b51f7a7041f2273b26f371593e6
  PATCH_COMMAND ${PATCH_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/osg.patch
  DEPENDS freetype2 libpng libjpeg
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/openscenegraph
  CMAKE_ARGS ${OSG_CMAKE_ARGS}
)

set(UNSHIELD_CMAKE_ARGS
  "${SUBPROJECT_CMAKE_ARGS}"
  "-DUSE_OUR_OWN_MD5=ON"
)

ExternalProject_Add(
  unshield
  URL https://github.com/twogood/unshield/archive/1.4.tar.gz
  URL_HASH SHA256=8ae91961212193a7d3d7973c1c9464f3cd1967c179d6099feb1bb193912f8231
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/unshield
  CMAKE_ARGS ${UNSHIELD_CMAKE_ARGS}
)

execute_process(
  COMMAND git rev-parse --short HEAD
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  OUTPUT_VARIABLE GIT_SHORT_COMMIT_HASH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

install(DIRECTORY "${CMAKE_INSTALL_PREFIX}" USE_SOURCE_PERMISSIONS DESTINATION "." COMPONENT Runtime)
set(CPACK_GENERATOR "ZIP")
set(CPACK_PACKAGE_FILE_NAME "openmw-deps-${GIT_SHORT_COMMIT_HASH}")
set(CPACK_INCLUDE_TOPLEVEL_DIRECTORY OFF)
include(CPack)
