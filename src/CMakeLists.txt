include(ExternalProject)

cmake_minimum_required(VERSION 3.1.0)

# by default, install to openmw-deps subfolder in build directory
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  if (OPENMW_DEPS_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
      set(CMAKE_INSTALL_PREFIX "${OPENMW_DEPS_BINARY_DIR}/openmw-deps" CACHE PATH "OPENMW_DEPS install prefix" FORCE)
  endif ()
endif ()

set(CMAKE_OSX_DEPLOYMENT_TARGET "10.9")
set(CMAKE_OSX_SYSROOT "macosx10.14" CACHE PATH "macOS SDK")
set(CMAKE_CXX_STANDARD 11)

# use CMAKE_OSX_SYSROOT as is if it points to existing directory, lookup full path otherwise
if (NOT EXISTS CMAKE_OSX_SYSROOT)
  find_program(XCRUN xcrun)
  if (NOT XCRUN)
    message(FATAL_ERROR "xcrun not found, please install Xcode CLI tools")
  endif ()
  execute_process(COMMAND
    ${XCRUN} --show-sdk-path --sdk ${CMAKE_OSX_SYSROOT}
    OUTPUT_VARIABLE CMAKE_OSX_SYSROOT OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_VARIABLE XCRUN_ERROR ERROR_STRIP_TRAILING_WHITESPACE
  )
  if (XCRUN_ERROR)
    message(FATAL_ERROR ${XCRUN_ERROR})
    unset(XCRUN_ERROR)
  endif ()
  unset(XCRUN)
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
  "-DCMAKE_LIBRARY_PATH=${CMAKE_INSTALL_PREFIX}/lib"
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
  "--with-iostreams"
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

set(BULLET_CMAKE_ARGS "${SUBPROJECT_CMAKE_ARGS};-DBUILD_BULLET3=OFF;-DBUILD_BULLET2_DEMOS=OFF;-DBUILD_CPU_DEMOS=OFF;-DBUILD_EXTRAS=OFF;-DUSE_DOUBLE_PRECISION=ON")

ExternalProject_Add(
  bullet
  URL https://github.com/bulletphysics/bullet3/archive/2.89.tar.gz
  URL_HASH SHA256=621b36e91c0371933f3c2156db22c083383164881d2a6b84636759dc4cbb0bb8

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/bullet
  CMAKE_ARGS ${BULLET_CMAKE_ARGS}
)

set(FFMPEG_CONFIGURE_ARGS
  "--prefix=${CMAKE_INSTALL_PREFIX}"
  "--disable-programs"
  "--disable-iconv"
  "--disable-sdl2"
  "--disable-doc"
  "--disable-demuxer=matroska"
  "--disable-network"
  "--disable-securetransport"
  "--disable-videotoolbox"
  "--disable-audiotoolbox"
  "--disable-avfilter"
  "--disable-avdevice"
  "--disable-lzma"
  "--extra-cflags=-Wno-shift-negative-value"
)

ExternalProject_Add(
  ffmpeg
  URL https://ffmpeg.org/releases/ffmpeg-3.2.4.tar.bz2
  URL_HASH SHA256=c0fa3593a2e9e96ace3c1757900094437ad96d1d6ca19f057c378b5f394496a4

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
  URL https://download.savannah.gnu.org/releases/freetype/freetype-2.6.5.tar.bz2
  URL_HASH SHA256=e20a6e1400798fd5e3d831dd821b61c35b1f9a6465d6b18a53a9df4cf441acf0

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/freetype2
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/freetype2/configure --prefix=${CMAKE_INSTALL_PREFIX} --without-harfbuzz
  BUILD_COMMAND make COMMAND sh ${AUTOTOOLS_POSTBUILD_SCRIPT}
)

ExternalProject_Add(
  libjpeg
  URL https://www.ijg.org/files/jpegsrc.v8d.tar.gz
  URL_HASH SHA256=d625ad6b3375a036bf30cd3b0b40e8dde08f0891bfd3a2960650654bdb50318c

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg/configure --prefix=${CMAKE_INSTALL_PREFIX}
  BUILD_COMMAND make COMMAND sh ${AUTOTOOLS_POSTBUILD_SCRIPT}
)

set(LZ4_CMAKE_ARGS "${SUBPROJECT_CMAKE_ARGS};-DBUILD_STATIC_LIBS=ON;-DBUILD_SHARED_LIBS=OFF")

ExternalProject_Add(
  lz4
  URL https://github.com/lz4/lz4/archive/v1.9.2.tar.gz
  URL_HASH SHA256=658ba6191fa44c92280d4aa2c271b0f4fbc0e34d249578dd05e50e76d0e5efcc

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/lz4
  SOURCE_SUBDIR contrib/cmake_unofficial
  CMAKE_ARGS ${LZ4_CMAKE_ARGS}
)

set(MYGUI_CMAKE_ARGS "${SUBPROJECT_CMAKE_ARGS};-DMYGUI_RENDERSYSTEM=1;-DMYGUI_BUILD_DEMOS=OFF;-DMYGUI_BUILD_TOOLS=OFF;-DMYGUI_BUILD_PLUGINS=OFF")

ExternalProject_Add(
  mygui
  DEPENDS freetype2
  URL https://github.com/MyGUI/mygui/archive/1c5a49c792c23d8b9b6760bb4877447c337e53f6.zip
  URL_HASH SHA256=aadf20093b32fc4083fb0fc1142e901081ed8e016c910ef927f85058bf7d4b3e

  PATCH_COMMAND ${PATCH_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/mygui.patch
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/mygui
  CMAKE_ARGS ${MYGUI_CMAKE_ARGS}
)

ExternalProject_Add(
  SDL2
  URL https://github.com/libsdl-org/SDL/archive/033c0abb58e7aa6ba2bf7ad4952b73d9061f3f59.zip
  URL_HASH SHA256=dbcb7aa78e24a32bb9f4c88f64d6977a6cd7c4e09ab468593cb450da5ea3cd42

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
  "-DBUILD_OSG_DEPRECATED_SERIALIZERS=OFF"
  "-DBUILD_OSG_PLUGINS_BY_DEFAULT=OFF"
  "-DBUILD_OSG_PLUGIN_BMP=1"
  "-DBUILD_OSG_PLUGIN_DDS=1"
  "-DBUILD_OSG_PLUGIN_FREETYPE=1"
  "-DBUILD_OSG_PLUGIN_JPEG=1"
  "-DBUILD_OSG_PLUGIN_OSG=1"
  "-DBUILD_OSG_PLUGIN_PNG=1"
  "-DBUILD_OSG_PLUGIN_TGA=1"
  "-DOSG_CXX_LANGUAGE_STANDARD=C++${CMAKE_CXX_STANDARD}"
  "-DCMAKE_DISABLE_FIND_PACKAGE_FFmpeg=1"
)

ExternalProject_Add(
  openscenegraph
  URL https://github.com/OpenMW/osg/archive/76e061739610bc9a3420a59e7c9395e742ce2f97.zip
  URL_HASH SHA256=fa1100362eae260192819d65d90b29ec0b88fdf80e30cee677730b7a0d68637e
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
install(CODE "
  execute_process(COMMAND bash -c \"find '\${CMAKE_INSTALL_PREFIX}' -name '*.pc' -exec sed -i '' 's=${CMAKE_INSTALL_PREFIX}=/private/tmp/openmw-deps=g' {} \;\")
")
message(STATUS "CPACK_INSTALL_COMMANDS ${CPACK_INSTALL_COMMANDS}")
include(CPack)
