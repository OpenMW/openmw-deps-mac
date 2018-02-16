include(ExternalProject)

cmake_minimum_required(VERSION 3.1.0)

# by default, install to openmw-deps subfolder in build directory
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  if (OPENMW_DEPS_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
      set(CMAKE_INSTALL_PREFIX "${OPENMW_DEPS_BINARY_DIR}/openmw-deps" CACHE PATH "OPENMW_DEPS install prefix" FORCE)
  endif ()
endif ()

set(CMAKE_OSX_DEPLOYMENT_TARGET "10.9")
set(CMAKE_OSX_SYSROOT "macosx10.13")
set(CMAKE_CXX_STANDARD 11)

# use CMAKE_OSX_SYSROOT as is if it points to existing directory, lookup full path otherwise
if(NOT EXISTS CMAKE_OSX_SYSROOT)
  execute_process(COMMAND xcrun --show-sdk-path --sdk ${CMAKE_OSX_SYSROOT} OUTPUT_VARIABLE CMAKE_OSX_SYSROOT OUTPUT_STRIP_TRAILING_WHITESPACE)
endif ()

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
  URL https://dl.bintray.com/boostorg/release/1.66.0/source/boost_1_66_0.tar.bz2
  URL_HASH SHA256=5721818253e6a0989583192f96782c4a98eb6204965316df9f5ad75819225ca9
  PATCH_COMMAND ${PATCH_WRAPPER} ${BOOST_DARWIN_PATCH}

  BUILD_IN_SOURCE 1
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/boost
  CONFIGURE_COMMAND ./bootstrap.sh ${BOOST_BOOTSTRAP_ARGS}
  BUILD_COMMAND ./b2 ${BOOST_B2_ARGS}
)

set(BULLET_CMAKE_ARGS "${SUBPROJECT_CMAKE_ARGS};-DBUILD_BULLET3=OFF;-DBUILD_BULLET2_DEMOS=OFF;-DBUILD_CPU_DEMOS=OFF;-DBUILD_EXTRAS=OFF")

ExternalProject_Add(
  bullet
  URL https://github.com/bulletphysics/bullet3/archive/2.87.tar.gz
  URL_HASH SHA256=438c151c48840fe3f902ec260d9496f8beb26dba4b17769a4a53212903935f95

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
  URL https://ffmpeg.org/releases/ffmpeg-2.8.13.tar.bz2
  URL_HASH SHA256=df9b98cb584a004ce8e29b4c954cfb8d9e45dac52b4c6d036f25dfbaa3086778

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg/configure ${FFMPEG_CONFIGURE_ARGS}
  BUILD_COMMAND make COMMAND sh ${AUTOTOOLS_POSTBUILD_SCRIPT}
)

ExternalProject_Add(
  libpng
  URL https://dl.bintray.com/homebrew/mirror/libpng-1.6.25.tar.xz
  URL_HASH SHA256=09fe8d8341e8bfcfb3263100d9ac7ea2155b28dd8535f179111c1672ac8d8811

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libpng
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/libpng/configure --prefix=${CMAKE_INSTALL_PREFIX}
  BUILD_COMMAND make COMMAND sh ${AUTOTOOLS_POSTBUILD_SCRIPT}
)

ExternalProject_Add(
  freetype2
  DEPENDS libpng
  URL http://download.savannah.gnu.org/releases/freetype/freetype-2.6.5.tar.bz2
  URL_HASH SHA256=e20a6e1400798fd5e3d831dd821b61c35b1f9a6465d6b18a53a9df4cf441acf0

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
  URL https://github.com/MyGUI/mygui/archive/b1e4bc802a63fef015fc1d213d45a520eddc99b3.zip
  URL_HASH SHA256=c905e4e152b501f91e8ac9eb0fe9cd3f3e845faae6de45edcadd917be5bfece1

  PATCH_COMMAND ${PATCH_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/mygui.patch
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/mygui
  CMAKE_ARGS ${MYGUI_CMAKE_ARGS}
)

ExternalProject_Add(
  SDL2
  URL https://libsdl.org/release/SDL2-2.0.7.tar.gz
  URL_HASH SHA256=ee35c74c4313e2eda104b14b1b86f7db84a04eeab9430d56e001cea268bf4d5e

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
  URL https://github.com/OpenMW/osg/archive/2b4c8e37268e595b82da4b9aadd5507852569b87.zip
  URL_HASH SHA256=cffee367ee98f6a6953206893772ab99ef90cbfbda5e2ea3e2e135c22659eb01
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
  URL https://github.com/twogood/unshield/archive/1.4.2.tar.gz
  URL_HASH SHA256=5dd4ea0c7e97ad8e3677ff3a254b116df08a5d041c2df8859aad5c4f88d1f774
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
