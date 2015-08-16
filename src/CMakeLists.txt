include(ExternalProject)

# by default, install to openmw-deps subfolder in build directory
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  if (OPENMW_DEPS_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
      set(CMAKE_INSTALL_PREFIX "${OPENMW_DEPS_BINARY_DIR}/openmw-deps" CACHE PATH "OPENMW_DEPS install prefix" FORCE)
  endif ()
endif ()

set(CMAKE_OSX_DEPLOYMENT_TARGET "10.8")
set(CMAKE_OSX_SYSROOT "macosx10.10")

if (NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: Debug, Release" FORCE)
endif ()

set(SUBPROJECT_CMAKE_ARGS
                        "-DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}"
                        "-DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}"
                        "-DCMAKE_PREFIX_PATH:PATH=${CMAKE_INSTALL_PREFIX}"
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

ExternalProject_Add(
  freetype2
  URL http://download.savannah.gnu.org/releases/freetype/freetype-2.6.tar.bz2
  URL_HASH SHA256=8469fb8124764f85029cc8247c31e132a2c5e51084ddce2a44ea32ee4ae8347e

  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/freetype2
  CONFIGURE_COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/freetype2/configure --prefix=${CMAKE_INSTALL_PREFIX} --without-harfbuzz
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
                    "-DDESIRED_QT_VERSION=4"
                    "-DOSG_CXX_LANGUAGE_STANDARD=C++98"
                    "-DCMAKE_DISABLE_FIND_PACKAGE_FFmpeg=1"

                    # this libs are not reqired on OS X since we have almighty ImageIO framework
                    "-DCMAKE_DISABLE_FIND_PACKAGE_PNG=1"
                    "-DCMAKE_DISABLE_FIND_PACKAGE_JPEG=1"
                    "-DCMAKE_DISABLE_FIND_PACKAGE_TIFF=1"
                    "-DCMAKE_DISABLE_FIND_PACKAGE_GIFLIB=1"
)

ExternalProject_Add(
  openscenegraph
  DEPENDS SDL2 freetype2
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/openscenegraph
  CMAKE_ARGS ${OSG_CMAKE_ARGS}
)
