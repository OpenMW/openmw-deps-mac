include(ExternalProject)

# by default, install to openmw-deps subfolder in build directory
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  if (OPENMW_DEPS_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
      set(CMAKE_INSTALL_PREFIX "${OPENMW_DEPS_BINARY_DIR}/openmw-deps" CACHE PATH "OPENMW_DEPS install prefix" FORCE)
  endif ()
endif ()

set(CMAKE_OSX_DEPLOYMENT_TARGET "10.8")
set(CMAKE_OSX_SYSROOT "macosx10.11")

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: Debug, Release" FORCE)
endif ()

if (NOT PATH_TO_QT)
  message (FATAL_ERROR "Path to your Qt installation is required")
endif ()

set(SUBPROJECT_CMAKE_ARGS
                        "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
                        "-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}"
                        "-DCMAKE_PREFIX_PATH=${CMAKE_INSTALL_PREFIX}$<SEMICOLON>${PATH_TO_QT}"
                        "-DPKG_CONFIG_USE_CMAKE_PREFIX_PATH=ON"
                        "-DCMAKE_OSX_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
                        "-DCMAKE_OSX_SYSROOT=${CMAKE_OSX_SYSROOT}"
                        "-DCMAKE_MACOSX_RPATH=ON"
                        "-DCMAKE_INSTALL_RPATH=${CMAKE_INSTALL_PREFIX}/lib"
                      )

set(BULLET_CMAKE_ARGS "${SUBPROJECT_CMAKE_ARGS};-DBUILD_BULLET3=OFF;-DBUILD_BULLET2_DEMOS=OFF;-DBUILD_CPU_DEMOS=OFF;-DBUILD_EXTRAS=OFF")

ExternalProject_Add(
  bullet
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/bullet
  CMAKE_ARGS ${BULLET_CMAKE_ARGS}
)

set(FFMPEG_CFLAGS "-mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
set(FFMPEG_LDFLAGS ${FFMPEG_CFLAGS})
set(FFMPEG_CONFIGURE_ARGS
  "--prefix=${CMAKE_INSTALL_PREFIX}"
  "--disable-programs"
  "--disable-iconv"
  "--disable-doc"
  "--disable-demuxer=matroska"
  "--disable-network"
  "--disable-securetransport"
  "--disable-videotoolbox"
  "--extra-cflags=${FFMPEG_CFLAGS}"
  "--extra-ldflags=${FFMPEG_LDFLAGS}"
)

ExternalProject_Add(
  ffmpeg
  URL https://ffmpeg.org/releases/ffmpeg-2.8.1.tar.bz2
  URL_HASH SHA256=e2ed5ab28dee1af94336739173eb0019afc21a54e38a96f4e3208e94a07866e2

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg
  CONFIGURE_COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg/configure ${FFMPEG_CONFIGURE_ARGS}
  BUILD_COMMAND make
)

ExternalProject_Add(
  freetype2
  URL http://download.savannah.gnu.org/releases/freetype/freetype-2.6.tar.bz2
  URL_HASH SHA256=8469fb8124764f85029cc8247c31e132a2c5e51084ddce2a44ea32ee4ae8347e

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/freetype2
  CONFIGURE_COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/freetype2/configure --prefix=${CMAKE_INSTALL_PREFIX} --without-harfbuzz
  BUILD_COMMAND make
)

ExternalProject_Add(
  libpng
  URL https://dl.bintray.com/homebrew/mirror/libpng-1.6.18.tar.xz
  URL_HASH SHA256=2e10c13b7949883ac961db6177c516d778184432d440317e9f0391305c360963

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libpng
  CONFIGURE_COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/libpng/configure --prefix=${CMAKE_INSTALL_PREFIX}
  BUILD_COMMAND make
)

ExternalProject_Add(
  libjpeg
  URL http://www.ijg.org/files/jpegsrc.v8d.tar.gz
  URL_HASH SHA256=00029b1473f0f0ea72fbca3230e8cb25797fbb27e58ae2e46bb8bf5a806fe0b3

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg
  CONFIGURE_COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg/configure --prefix=${CMAKE_INSTALL_PREFIX}
  BUILD_COMMAND make
)

set(MYGUI_CMAKE_ARGS "${SUBPROJECT_CMAKE_ARGS};-DMYGUI_RENDERSYSTEM=1;-DMYGUI_BUILD_DEMOS=OFF;-DMYGUI_BUILD_TOOLS=OFF;-DMYGUI_BUILD_PLUGINS=OFF")

ExternalProject_Add(
  mygui
  DEPENDS freetype2
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/mygui
  CMAKE_ARGS ${MYGUI_CMAKE_ARGS}
)

ExternalProject_Add(
  SDL2
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/SDL2
  CONFIGURE_COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/SDL2/configure --prefix=${CMAKE_INSTALL_PREFIX} --without-x
  BUILD_COMMAND make
)

set(OSG_CMAKE_ARGS "${SUBPROJECT_CMAKE_ARGS}"
                    "-DOSG_WINDOWING_SYSTEM=Cocoa"
                    "-DOSG_USE_FLOAT_MATRIX=ON"
                    "-DOSG_USE_FLOAT_PLANE=ON"
                    "-DBUILD_OSG_APPLICATIONS=OFF"
                    "-DBUILD_OSG_EXAMPLES=OFF"
                    "-DOSG_CXX_LANGUAGE_STANDARD=C++98"
                    "-DCMAKE_DISABLE_FIND_PACKAGE_FFmpeg=1"
)

ExternalProject_Add(
  openscenegraph
  URL http://trac.openscenegraph.org/downloads/developer_releases/OpenSceneGraph-3.4.0.zip
  URL_HASH MD5=a5e762c64373a46932e444f6f7332496
  PATCH_COMMAND patch -p1 -d ${CMAKE_CURRENT_SOURCE_DIR}/openscenegraph < ${CMAKE_CURRENT_SOURCE_DIR}/osg.patch
  DEPENDS SDL2 freetype2 libpng libjpeg
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/openscenegraph
  CMAKE_ARGS ${OSG_CMAKE_ARGS}
)

set(UNSHIELD_CMAKE_ARGS
  "${SUBPROJECT_CMAKE_ARGS}"
  "-DUSE_OUR_OWN_MD5=ON"
)

ExternalProject_Add(
  unshield
  URL https://github.com/twogood/unshield/archive/1.3.tar.gz
  URL_HASH SHA256=31a49c43b60e86b3ed731e0a1b988b88d35b755c85d103e93e1507278328bf73
  PATCH_COMMAND patch -p1 -d ${CMAKE_CURRENT_SOURCE_DIR}/unshield < ${CMAKE_CURRENT_SOURCE_DIR}/unshield.patch
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/unshield
  CMAKE_ARGS ${UNSHIELD_CMAKE_ARGS}
)
