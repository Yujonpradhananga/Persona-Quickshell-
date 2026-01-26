cmake_minimum_required(VERSION 3.20)
project(HyprlandMonitor)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Network)

set(QML_IMPORT_PATH "${CMAKE_INSTALL_PREFIX}" CACHE STRING "" FORCE)

qt_add_qml_module(hyprlandmonitor
    URI HyprlandMonitor
    VERSION 1.0
    SOURCES
        hyprlandmonitor.cpp
        hyprlandmonitor.hpp
    NO_PLUGIN_OPTIONAL
    OUTPUT_DIRECTORY "${CMAKE_INSTALL_PREFIX}/HyprlandMonitor"
)

target_link_libraries(hyprlandmonitor PRIVATE
    Qt6::Core
    Qt6::Qml
    Qt6::Network
)
