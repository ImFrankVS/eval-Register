cmake_minimum_required(VERSION 3.5)
project(evalRegister VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_MACOSX_RPATH 1)
set(CMAKE_SKIP_BUILD_RPATH FALSE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE)

set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR})
find_package(Julia REQUIRED)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Copy the files .jl into the binary dir
file(COPY methods/CODE_STEP_00.jl
          methods/CODE_STEP_01.jl
          methods/CODE_STEP01_Figures.jl
          methods/CODE_SPEC.jl
          methods/CODE_BinBehavior.jl
          methods/DEPS_01.jl
          methods/Suppressor.jl
          methods/AllSTEPs.jl

     DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/methods
)

file(COPY styles/ManjaroMix.qss
          styles/Wstartpage.qss
          styles/Ubuntu.qss
          styles/ElegantDark.qss
          styles/ConsoleStyle.qss
          styles/MaterialDark.qss
          styles/darkstyle

     DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/styles
)

file(COPY ${CMAKE_SOURCE_DIR}/resources

     DESTINATION ${CMAKE_BINARY_DIR}
)

file(COPY ${CMAKE_SOURCE_DIR}/icon.ico

     DESTINATION ${CMAKE_BINARY_DIR}
)

find_package(Qt5 5.15.2 REQUIRED COMPONENTS Widgets)

# Resources
set(APP_ICON_RESOURCE_WINDOWS
    "${CMAKE_CURRENT_SOURCE_DIR}/myapp.rc"
)
set(SOURCE_FILES
    main.cpp
    evalregister.ui
    evalregister.h evalregister.cpp
    FigureViewer.h FigureViewer.cpp
)

add_executable(evalRegister
    ${SOURCE_FILES}
    ${APP_ICON_RESOURCE_WINDOWS}
)

target_include_directories(evalRegister PUBLIC
  "$<BUILD_INTERFACE:${Julia_INCLUDE_DIRS}>"
)

target_link_libraries(evalRegister
    PRIVATE Qt5::Widgets
    PRIVATE $<BUILD_INTERFACE:${Julia_LIBRARY}>
)

set_target_properties(evalRegister PROPERTIES
    ${BUNDLE_ID_OPTION}
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

include(GNUInstallDirs)
install(TARGETS evalRegister
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
