#  Copyright (C) 2019-2022 by Shawn Chain BG5HHP for the X part

#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

TOP_DIR := ..


# MCU external clock frequency (Hz)
CLK_8MHz=8000000
CLK_12MHz=12000000
CLK_25MHz=25000000


MCU_TYPE?=AT32F403ARGT7
OSC?=$(CLK_8MHz)
ROM_OFFSET?=0x0

F4_LIB_PATH=../STM32F4XX_Lib

# Standard library path
STDLIB_PATH=./drivers
STDLIB_SRC_PATH=$(STDLIB_PATH)/src

RELEASE?=0

# Directory Structure
BINDIR=./bin

OBJDIR_F4=obj_a4

# Define the function that will generate each rule
# C compile rule
define CompileRule_C
$$(OBJDIR_F4)/%.o: $(1)/%.c
	$$(CC) $$(CFLAGS) $$< -o $$@
endef

# CXX compile rule
define CompileRule_CXX
$$(OBJDIR_F4)/%.o: $(1)/%.cpp
	$$(CXX) $$(CXXFLAGS) $$< -o $$@
endef

# Output files
BINLIB_F4=libat32f40x.a
BINMAP_F4=libat32f40x.map

# Header directories
INC_F4= .. . ./cmsis/cm4/core_support/ ./cmsis/cm4/device_support/
INC_F4+= $(STDLIB_PATH)/inc $(TOP_DIR)/at32

INCLUDES_F4=$(INC_F4:%=-I%)

# CMSIS libraries
LIBS_F4=

# GNU ARM Embedded Toolchain
CC=arm-none-eabi-gcc
CXX=arm-none-eabi-g++
LD=arm-none-eabi-ld
AR=arm-none-eabi-ar
AS=arm-none-eabi-as
CP=arm-none-eabi-objcopy
OD=arm-none-eabi-objdump
SIZE=arm-none-eabi-size
NM=arm-none-eabi-nm
A2L=arm-none-eabi-addr2line

CLEANCMD=rm -f $(OBJ_F4) $(BINDIR)/*.hex $(BINDIR)/*.bin $(BINDIR)/*.elf $(BINDIR)/*.a $(BINDIR)/*.so $(BINDIR)/*.map GitVersion.h
MDDIRS=mkdir $@

# Build object lists
OBJ_F4=

# The Standard Lib C code
CSRC_STDLIB=$(wildcard $(STDLIB_SRC_PATH)/*.c)
OBJ_F4 += $(CSRC_STDLIB:$(STDLIB_SRC_PATH)/%.c=$(OBJDIR_F4)/%.o)
$(eval $(call CompileRule_C, $(STDLIB_SRC_PATH)))

# MCU flags
MCFLAGS_F4=-mcpu=cortex-m4 -mthumb -mlittle-endian -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb-interwork

DEFS_F4= -DAT32 -DAT32F4 -D$(MCU_TYPE) -DHSE_VALUE=$(OSC) -DMADEBYMAKEFILE -DVECT_TAB_OFFSET=$(ROM_OFFSET)

ifeq ($(RELEASE),1)
	DEFS_F4+=-DRELEASE=1
else
	DEFS_F4+=-DRELEASE=0
endif

# Build compiler flags
CFLAGS_F4=-c $(MCFLAGS_F4) $(INCLUDES_F4)
CFLAGS_F4+= -Wall -std=c99 -nostdlib

CXXFLAGS_F4=-c $(MCFLAGS_F4) $(INCLUDES_F4)
CXXFLAGS_F4+= -std=c++11 -nostdlib -fno-exceptions

# Linker flags
LDFLAGS_F4 =-T $(LDFILE_F4) $(MCFLAGS_F4) --specs=nosys.specs $(LIBS_F4)
LDFLAGS_F4 +=-Wl,--gc-sections -Wl,-Map=$(BINDIR)/$(BINMAP_F4) -Wl,--no-wchar-size-warning

# Optimization flags
ifeq ($(RELEASE),1)
	# OPTS=-Os
	# OPTS=-Ofast
	OPTS=-O3
# else ifeq($(TRACE),1)
# 	OPTS=-O0 -g -DDEBUG
else
	OPTS=-O1 -g -DDEBUG
endif

# Common flags
CFLAGS=$(OPTS) -ffunction-sections -fdata-sections -fno-builtin -Wno-implicit
CXXFLAGS=$(OPTS) -fno-exceptions -ffunction-sections -fdata-sections -fno-builtin -fno-rtti -DCUSTOM_NEW -DNO_EXCEPTIONS
LDFLAGS=$(OPTS) --specs=nano.specs
# LDFLAGS+= -u _printf_float

ARFLAGS := ru

# Build Rules
.PHONY: all release lib clean

# Default target: f4 board
all: lib

lib: GitVersion.h
lib: CFLAGS+=$(CFLAGS_F4) $(DEFS_F4)
lib: CXXFLAGS+=$(CXXFLAGS_F4) $(DEFS_F4)
lib: LDFLAGS+=$(LDFLAGS_F4)
lib: release_lib

release_lib: $(BINDIR)
release_lib: $(OBJDIR_F4)
release_lib: $(BINDIR)/$(BINLIB_F4)

$(BINDIR):
	$(MDDIRS)

$(OBJDIR_F4):
	$(MDDIRS)

$(BINDIR)/$(BINLIB_F4): $(OBJ_F4)
#	$(CXX) $(OBJ_F4) $(LDFLAGS) -o $@
	$(AR) rcs $@ $(OBJ_F4)
	@echo "Generate $@ complete!\n"

clean:
	$(CLEANCMD)
	$(RM) -fr $(OBJDIR_F4)

# Export the current git version if the index file exists, else 000...
GitVersion.h:
ifdef SYSTEMROOT
	echo #define GITVERSION "0000000" > $@
else ifdef SystemRoot
	echo #define GITVERSION "0000000" > $@
else
ifneq ("$(wildcard .git/index)","")
	echo "#define GITVERSION \"$(shell git rev-parse --short HEAD)\"" > $@
else
	echo "#define GITVERSION \"0000000\"" > $@
endif
endif
