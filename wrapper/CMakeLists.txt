cmake_minimum_required(VERSION 3.10)
project(llama_tokenizer_jni)

set(CMAKE_CXX_STANDARD 17)

# Paths to llama.cpp includes and library
set(LLAMA_DIR ${CMAKE_SOURCE_DIR}/../llama.cpp/)
set(LLAMA_BUILD_DIR ${LLAMA_DIR}/build/bin)

include_directories(${LLAMA_DIR})
include_directories(${LLAMA_DIR}/include)
include_directories(${LLAMA_DIR}/ggml/include)
include_directories(${LLAMA_DIR}/common)
include_directories(${LLAMA_DIR}/log)
link_directories(${LLAMA_BUILD_DIR})

add_library(llamatokenizer SHARED llama_tokenizer_api.cpp)
target_link_libraries(llamatokenizer llama pthread dl)