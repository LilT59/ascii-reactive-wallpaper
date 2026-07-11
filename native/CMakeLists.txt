cmake_minimum_required(VERSION 3.21)
project(ascii-reactive-pointer VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

add_library(asciireactivepointerplugin SHARED
    pointerplugin.cpp
    pointertracker.cpp
    pointertracker.h
    asciirenderer.cpp
    asciirenderer.h
)

target_link_libraries(asciireactivepointerplugin PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
)

set_target_properties(asciireactivepointerplugin PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_SOURCE_DIR}/../contents/ui/native"
)
