cmake_minimum_required(VERSION 3.12)

set(PICO_SDK_PATH ${CMAKE_CURRENT_LIST_DIR}/../pico-sdk)

# Pull in PICO SDK (must be before project)
include(pico_sdk_import.cmake)

# We also need PICO EXTRAS
include(pico_extras_import.cmake)

set(project_name "sine_wave" C CXX)
project(${project_name})
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

add_subdirectory(my_pico_audio)
add_subdirectory(my_pico_audio_i2s)

set(bin_name "sine_wave")
add_executable(${bin_name}
    sine_wave.c
)

pico_enable_stdio_usb(${bin_name} 1)
pico_enable_stdio_uart(${bin_name} 1)

target_link_libraries(${bin_name} PRIVATE
    pico_stdlib
    my_pico_audio_i2s
)

target_compile_definitions(${bin_name} PRIVATE
    #define for our example code
    USE_AUDIO_I2S=1
)

pico_add_extra_outputs(${bin_name})
