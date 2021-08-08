# I target a recent cmake, it shouldn't be a problem on a dev machine
cmake_minimum_required(VERSION 3.10)

# Generic GCC AVR
include(generic-gcc-avr.cmake)

# Project name
project(MyProject VERSION 1.0.0)

# Product filename
set(PRODUCT_NAME my_project)

## AVR Chip Configuration
# CPU frequency
set(F_CPU 16000000UL)
# CPU
set(MCU atmega328p)
# Default Baudrate for UART, read avr include/util/setbaud.h for usage
set(BAUD 9600)
# The programmer to use, read avrdude manual for list
set(PROG_TYPE avrisp2)
# Default port
set(PORT COM1)

# AVR Fuses, must be in concordance with your hardware and F_CPU
set(E_FUSE 0x05)
set(H_FUSE 0xde)
set(L_FUSE 0xff)
set(LOCK_BIT 0xff)

# Pass defines to compiler
add_definitions(
    -DF_CPU=${F_CPU}
    -DBAUD=${BAUD}
)
# mmcu MUST be passed to bot the compiler and linker, this handle the linker
set(CMAKE_EXE_LINKER_FLAGS -mmcu=${MCU})

# https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
add_compile_options(
    -mmcu=${MCU}
    -Os # optimize
    -Wall # enable warnings
    -Wno-main
    -Wundef
    -pedantic
    -Werror # make all warnings into errors
    -Wfatal-errors
    -Wl,--relax,--gc-sections
    -g
    -gdwarf-2
    -funsigned-char # a few optimizations
    -funsigned-bitfields
    -fpack-struct
    -fshort-enums
    -ffunction-sections
    -fdata-sections
    -fno-split-wide-types
    -fno-tree-scev-cprop
)

# Source directory
file(GLOB SRC_FILES src/*.cpp)

# Create one target
add_executable(${PRODUCT_NAME} ${SRC_FILES})

# Add libraries
add_subdirectory(libs)

# Include libraries directory
target_include_directories(${PRODUCT_NAME} PUBLIC libs)

# Link libraries
target_link_libraries(${PRODUCT_NAME} PUBLIC)

# Library compile options
# target_compile_options(MY_LIB)

# Rename the output to .elf as we will create multiple files
set_target_properties(${PRODUCT_NAME} PROPERTIES OUTPUT_NAME ${PRODUCT_NAME}.elf)

# Strip binary for upload
add_custom_target(strip ALL ${AVR_STRIP} ${PRODUCT_NAME}.elf DEPENDS ${PRODUCT_NAME})

# Transform binary into hex file, we ignore the eeprom segments in the step
add_custom_target(hex ALL ${AVR_OBJCOPY} -R .eeprom -O ihex ${PRODUCT_NAME}.elf ${PRODUCT_NAME}.hex DEPENDS strip)

# Transform binary into hex file, this is the eeprom part (empty if you don't use eeprom static variables)
add_custom_target(eeprom ${AVR_OBJCOPY} -j .eeprom  --set-section-flags=.eeprom="alloc,load"  --change-section-lma .eeprom=0 -O ihex ${PRODUCT_NAME}.elf ${PRODUCT_NAME}.eep DEPENDS strip)

# Upload the firmware with avrdude
add_custom_target(upload ${AVRDUDE} -c ${PROG_TYPE} -p ${MCU} -P ${PORT} -U flash:w:${PRODUCT_NAME}.hex DEPENDS hex)

# Upload the eeprom with avrdude
add_custom_target(upload_eeprom ${AVRDUDE} -c ${PROG_TYPE} -p ${MCU} -P ${PORT} -U eeprom:w:${PRODUCT_NAME}.eep DEPENDS eeprom)

# Burn fuses
add_custom_target(fuses ${AVRDUDE} -c ${PROG_TYPE} -p ${MCU} -P ${PORT} -U lfuse:w:${L_FUSE}:m -U hfuse:w:${H_FUSE}:m -U efuse:w:${E_FUSE}:m -U lock:w:${LOCK_BIT}:m )

# Monitor could be done with PuTTY tool (e.g. cli command to load already saved PuTTY configuration 'putty -load COM1@9600')
# More info https://documentation.help/PuTTY/using-cmdline.html
add_custom_target(monitor putty -load "${PORT}@${BAUD}")

# Clean extra files
set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES "${PRODUCT_NAME}.hex;${PRODUCT_NAME}.eeprom;${PRODUCT_NAME}.lst")
