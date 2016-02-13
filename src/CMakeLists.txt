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

set(CONFIGURE_WRAPPER "${OPENMW_DEPS_BINARY_DIR}/configure-wrapper.sh")
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/configure-wrapper.sh.in" ${CONFIGURE_WRAPPER} @ONLY)

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

set(BOOST_B2_USER_CONFIG "${OPENMW_DEPS_BINARY_DIR}/boost-user-config.jam")
set(BOOST_DARWIN_PATCH "${OPENMW_DEPS_BINARY_DIR}/boost-darwin.patch")
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/boost-user-config.jam.in" ${BOOST_B2_USER_CONFIG})
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/boost-darwin.patch.in" ${BOOST_DARWIN_PATCH} @ONLY)

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
  PATCH_COMMAND patch -p1 -d ${CMAKE_CURRENT_SOURCE_DIR}/boost < ${BOOST_DARWIN_PATCH}

  BUILD_IN_SOURCE 1
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/boost
  CONFIGURE_COMMAND ./bootstrap.sh ${BOOST_BOOTSTRAP_ARGS}
  BUILD_COMMAND ./b2 ${BOOST_B2_ARGS}
)

set(BULLET_CMAKE_ARGS "${SUBPROJECT_CMAKE_ARGS};-DBUILD_BULLET3=OFF;-DBUILD_BULLET2_DEMOS=OFF;-DBUILD_CPU_DEMOS=OFF;-DBUILD_EXTRAS=OFF")

ExternalProject_Add(
  bullet
  URL https://github.com/bulletphysics/bullet3/archive/2.83.6.tar.gz
  URL_HASH SHA256=dcd5448f31ded71c7bd22fddd7d816ac590ae7b97e1fdda8d1253f8ff3655571

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
)

ExternalProject_Add(
  ffmpeg
  URL https://ffmpeg.org/releases/ffmpeg-2.8.1.tar.bz2
  URL_HASH SHA256=e2ed5ab28dee1af94336739173eb0019afc21a54e38a96f4e3208e94a07866e2

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/ffmpeg/configure ${FFMPEG_CONFIGURE_ARGS}
  BUILD_COMMAND make
)

ExternalProject_Add(
  freetype2
  URL http://download.savannah.gnu.org/releases/freetype/freetype-2.6.tar.bz2
  URL_HASH SHA256=8469fb8124764f85029cc8247c31e132a2c5e51084ddce2a44ea32ee4ae8347e

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/freetype2
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/freetype2/configure --prefix=${CMAKE_INSTALL_PREFIX} --without-harfbuzz
  BUILD_COMMAND make
)

ExternalProject_Add(
  libpng
  URL https://dl.bintray.com/homebrew/mirror/libpng-1.6.20.tar.xz
  URL_HASH SHA256=55c5959e9f3484d96141a3226c53bc9da42a4845e70879d3e1d6e94833d1918b

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libpng
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/libpng/configure --prefix=${CMAKE_INSTALL_PREFIX}
  BUILD_COMMAND make
)

ExternalProject_Add(
  libjpeg
  URL http://www.ijg.org/files/jpegsrc.v8d.tar.gz
  URL_HASH SHA256=00029b1473f0f0ea72fbca3230e8cb25797fbb27e58ae2e46bb8bf5a806fe0b3

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/libjpeg/configure --prefix=${CMAKE_INSTALL_PREFIX}
  BUILD_COMMAND make
)

set(MYGUI_CMAKE_ARGS "${SUBPROJECT_CMAKE_ARGS};-DMYGUI_RENDERSYSTEM=1;-DMYGUI_BUILD_DEMOS=OFF;-DMYGUI_BUILD_TOOLS=OFF;-DMYGUI_BUILD_PLUGINS=OFF")

ExternalProject_Add(
  mygui
  DEPENDS freetype2
  GIT_REPOSITORY https://github.com/MyGUI/mygui.git
  GIT_TAG 1c5a49c792c23d8b9b6760bb4877447c337e53f6
  PATCH_COMMAND patch -p1 -d ${CMAKE_CURRENT_SOURCE_DIR}/mygui < ${CMAKE_CURRENT_SOURCE_DIR}/mygui.patch
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/mygui
  CMAKE_ARGS ${MYGUI_CMAKE_ARGS}
)

ExternalProject_Add(
  SDL2
  URL https://libsdl.org/release/SDL2-2.0.4.tar.gz
  URL_HASH SHA256=da55e540bf6331824153805d58b590a29c39d2d506c6d02fa409aedeab21174b

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/SDL2
  CONFIGURE_COMMAND ${CONFIGURE_WRAPPER} ${CMAKE_CURRENT_SOURCE_DIR}/SDL2/configure --prefix=${CMAKE_INSTALL_PREFIX} --without-x
  BUILD_COMMAND make
)

set(OSG_CMAKE_ARGS
  "${SUBPROJECT_CMAKE_ARGS}"
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
