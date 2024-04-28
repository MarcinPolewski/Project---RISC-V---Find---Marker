cmake_minimum_required(VERSION 3.11.0)
project(stack VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED True)


# for both:
set(PROJECT_SOURCES projekt-cpp.cpp)


add_executable(projekt projekt-cpp.cpp  ${PROJECT_SOURCES_MAIN} )

