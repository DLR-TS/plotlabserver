#********************************************************************************
#* Copyright (C) 2017-2020 German Aerospace Center (DLR). 
#* Eclipse ADORe, Automated Driving Open Research https://eclipse.org/adore
#*
#* This program and the accompanying materials are made available under the 
#* terms of the Eclipse Public License 2.0 which is available at
#* http://www.eclipse.org/legal/epl-2.0.
#*
#* SPDX-License-Identifier: EPL-2.0 
#*
#* Contributors: 
#*   Thomas Lobig - initial API and implementation
#********************************************************************************
cmake_minimum_required(VERSION 3.13)

project(plotlabserver 
        VERSION 0.0.1
        DESCRIPTION "Plotting server as part of the CSA framework"
        HOMEPAGE_URL "https://github.com/eclipse/adore/tree/master/plotlab/server"
)

#add_library(${PROJECT_NAME} INTERFACE)
#add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

set(CMAKE_MODULE_PATH
#    ${CMAKE_CURRENT_SOURCE_DIR}/../cmake
#    ${CMAKE_CURRENT_SOURCE_DIR}/../external
    CACHE INTERNAL "" FORCE
)
          
include(GNUInstallDirs)


set(stbimagepath ${CMAKE_CURRENT_SOURCE_DIR}/include/plotlabserver/)

list(APPEND CMAKE_PREFIX_PATH "$ENV{CMAKE_PREFIX_PATH}")

set(plotlablib_CMAKE_INSTALL_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../plotlablib/plotlablib/build/install")
list(APPEND CMAKE_PREFIX_PATH "${plotlablib_CMAKE_INSTALL_PATH}")


add_executable(plotlabserver)

find_package(plotlablib CONFIG REQUIRED)

find_package(Threads REQUIRED)
find_package(GLUT REQUIRED)
find_package(OpenGL REQUIRED)
find_package(CURL REQUIRED)

find_package(cppzmq CONFIG REQUIRED)
find_package(ZeroMQ CONFIG REQUIRED)
option(WITH_PERF_TOOL OFF)
option(ZMQ_BUILD_TESTS OFF)



target_sources(plotlabserver
  PRIVATE
    src/circleplot.cpp
    src/circlestrip.cpp
    src/figure.cpp
    src/lineplot.cpp
    src/patchplot.cpp
    src/plotlabserver.cpp
    src/plotobject.cpp
    src/stb_image.cpp
    src/textplot.cpp
    src/texturecache.cpp
    src/textureplot.cpp
    src/tristrip.cpp
)

target_include_directories(plotlabserver 
                             PRIVATE 
                               include
                          )

target_link_libraries(plotlabserver 
                        PRIVATE 
                          Threads::Threads 
                          ${GLUT_LIBRARIES} 
                          ${OPENGL_LIBRARIES} 
                          CURL::libcurl
                          plotlablib::plotlablib
                      )

target_compile_features(plotlabserver PRIVATE cxx_std_17)

set_target_properties(plotlabserver PROPERTIES POSITION_INDEPENDENT_CODE ON THREADS_PREFER_PTHREAD_FLAG ON)
