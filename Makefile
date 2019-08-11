###################### Initialize project variables: ##########################
# Executable name:
TARGET_APP = MCMap
# Build type: either Debug or Release
CONFIG?=Release
# Enable or disable verbose output
VERBOSE?=0
V_AT:=$(shell if [ $(VERBOSE) != 1 ]; then echo '@'; fi)


# Project directories:
PROJECT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
SOURCE_DIR:=$(PROJECT_DIR)/Source
BUILD_DIR:=$(PROJECT_DIR)/build/$(CONFIG)
OBJDIR:=$(BUILD_DIR)/intermediate

TARGET_BUILD_PATH:=$(PROJECT_DIR)/$(TARGET_APP)

# Command used to strip unneeded symbols from object files:
STRIP?=strip

# Use the build system's architecture by default.
TARGET_ARCH?=-march=native

# Command used to clean out build files:
CLEANCMD:=rm -rf $(OBJDIR)


########################## Primary build target: ##############################
$(TARGET_BUILD_PATH) : build
	@echo Linking "$(TARGET_APP):"
	$(V_AT)$(CXX) $(LINK_ARGS)

###################### Build/configure gzstream lib: ##########################
GZSTREAM_DIR:=$(PROJECT_DIR)/gzstream
include $(GZSTREAM_DIR)/Makefile

############################### Set build flags: ##############################
#### Config-specific flags: ####
ifeq ($(CONFIG),Debug)
    OPTIMIZATION?=0
    GDB_SUPPORT?=1
    # Debug-specific preprocessor definitions:
    CONFIG_FLAGS=-DDEBUG=1
endif

ifeq ($(CONFIG),Release)
    OPTIMIZATION?=1
    GDB_SUPPORT?=0
endif

# Set optimization level flags:
ifeq ($(OPTIMIZATION),1)
    CONFIG_CFLAGS=-O3 -flto
    CONFIG_LDFLAGS:=-flto
else
    CONFIG_CFLAGS=-O0
endif

# Set debugger flags:
ifeq ($(GDB_SUPPORT),1)
    CONFIG_CFLAGS:=$(CONFIG_CFLAGS) -g -ggdb
else
    CONFIG_LDFLAGS:=$(CONFIG_LDFLAGS) -fvisibility=hidden
endif

#### C compilation flags: ####
CFLAGS:=$(TARGET_ARCH) $(CONFIG_CFLAGS) $(CFLAGS)

#### C++ compilation flags: ####
CXXFLAGS:=-std=gnu++17 $(CXXFLAGS)

#### C Preprocessor flags: ####

# Include directories:
INCLUDE_FLAGS:=-I$(SOURCE_DIR) -I$(GZSTREAM_DIR) $(INCLUDE_FLAGS)

# Disable dependency generation if multiple architectures are set
DEPFLAGS:=$(if $(word 2, $(TARGET_ARCH)), , -MMD)

PKG_CONFIG_LIBS=libpng

DEFINE_FLAGS:=

CPPFLAGS:=-pthread \
          $(DEPFLAGS) \
          $(CONFIG_FLAGS) \
          $(DEFINE_FLAGS) \
          $(INCLUDE_FLAGS) \
          $(shell pkg-config --cflags $(PKG_CONFIG_LIBS)) \
          $(CPPFLAGS)

#### Linker flags: ####
        
LDFLAGS := -lpthread $(TARGET_ARCH) $(CONFIG_LDFLAGS) \
            $(shell pkg-config --libs $(PKG_CONFIG_LIBS)) \
            $(GZ_LDFLAGS) \
	        $(LDFLAGS)

#### Aggregated build arguments: ####

OBJECTS:=$(OBJDIR)/Main.o $(OBJDIR)/MapImage.o $(OBJDIR)/MCAFile.o $(OBJECTS)


# Complete set of flags used to compile source files:
BUILD_FLAGS:=$(CFLAGS) $(CXXFLAGS) $(CPPFLAGS)

# Complete set of arguments used to link the program:
LINK_ARGS:= -o $(TARGET_BUILD_PATH) $(OBJECTS) $(LDFLAGS)

###################### Supporting Build Targets: ##############################
.PHONY: gz_default build

build : gz_default $(OBJECTS)

$(OBJECTS) :
	@echo "Compiling $(<F):"
	$(V_AT)mkdir -p $(OBJDIR)
	$(V_AT)$(CXX) $(BUILD_FLAGS) -o "$@" -c "$<"

-include $(OBJECTS:%.o=%.d)

$(OBJDIR)/Main.o: \
	$(SOURCE_DIR)/Main.cpp
$(OBJDIR)/MapImage.o: \
	$(SOURCE_DIR)/MapImage.cpp
$(OBJDIR)/MCAFile.o: \
	$(SOURCE_DIR)/MCAFile.cpp
