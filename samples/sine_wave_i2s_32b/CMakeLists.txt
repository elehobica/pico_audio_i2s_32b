cmake_minimum_required(VERSION 3.13)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)
include($ENV{PICO_EXTRAS_PATH}/external/pico_extras_import.cmake)

set(project_name "sine_wave_i2s_32b" C CXX ASM)
project(${project_name})
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

add_subdirectory(../../src/pico_audio_32b pico_audio_32b)
add_subdirectory(../.. pico_audio_i2s_32b)

set(bin_name ${PROJECT_NAME})
add_executable(${PROJECT_NAME}
    sine_wave.cpp
)

pico_enable_stdio_usb(${bin_name} 1)
pico_enable_stdio_uart(${bin_name} 1)

target_link_libraries(${bin_name} PRIVATE
    pico_stdlib
    pico_audio_32b
    pico_audio_i2s_32b
)

# set PIO and DMA for I2S
# set core1 process i2s_callback
#target_compile_definitions(${PROJECT_NAME} PRIVATE
#    PICO_AUDIO_I2S_PIO=1
#    PICO_AUDIO_I2S_DMA_IRQ=1
#    CORE1_PROCESS_I2S_CALLBACK
#)

pico_add_extra_outputs(${bin_name})
