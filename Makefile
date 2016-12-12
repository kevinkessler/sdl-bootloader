PROJECT_NAME := dfu_dual_bank_ble_s110_ble400

MAKEFILE_NAME := $(MAKEFILE_LIST)
MAKEFILE_DIR := $(dir $(MAKEFILE_NAME) ) 

OUTPUT_FILENAME := sdl-bootloader

ifeq ($(OS),Windows_NT)
	SDK_BASE      := D:/NRF5/SDK9
	COMPONENTS    := $(SDK_BASE)/components
	TEMPLATE_PATH := $(COMPONENTS)/toolchain/gcc
	GNU_INSTALL_ROOT=D:/ARM/GNUTOOLS/5.2-2015q4
	MESH_BASE     := D:/NRF5/nRF51-ble-bcast-mesh/nRF51
	OPENOCD_BASE  := D:/NRF5/openocd-0.9.0
	NRFJPROG_BASE := C:/Program Files (x86)/Nordic Semiconductor/nrf5x/bin
else
	SDK_BASE      := ${HOME}/nrf5/SDK9
	COMPONENTS    := $(SDK_BASE)/components
	TEMPLATE_PATH := $(COMPONENTS)/toolchain/gcc
	GNU_INSTALL_ROOT := /usr/local/gcc-arm-none-eabi-5_2-2015q4
	MESH_BASE     := ${HOME}/nrf5/nRF51-ble-bcast-mesh/nRF51
	OPENOCD_BASE  := ${HOME}/nrf5/openocd-0.9.0
	NRFJPROG_BASE := ${HOME}/nrf5/nrfjprog
endif

MK := mkdir
RM := rm -rf
VERBOSE = 1
#echo suspend
ifeq ("$(VERBOSE)","1")
NO_ECHO := 
else
NO_ECHO := @
endif

GNU_INSTALL_ROOT := /usr/local/gcc-arm-none-eabi-5_2-2015q4
GNU_PREFIX = arm-none-eabi

# Toolchain commands
CC       		:= $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-gcc
AS       		:= $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-as
AR       		:= $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-ar -r
LD       		:= $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-ld
NM       		:= $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-nm
OBJDUMP  		:= $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-objdump
OBJCOPY  		:= $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-objcopy
SIZE    		:= $(GNU_INSTALL_ROOT)/bin/$(GNU_PREFIX)-size

NRFJPROG := "$(NRFJPROG_BASE)/nrfjprog"

#function for removing duplicates in a list
remduplicates = $(strip $(if $1,$(firstword $1) $(call remduplicates,$(filter-out $(firstword $1),$1))))

#source common to all targets
C_SOURCE_FILES += $(COMPONENTS)/libraries/util/app_error.c
C_SOURCE_FILES += $(COMPONENTS)/libraries/scheduler/app_scheduler.c
C_SOURCE_FILES += $(COMPONENTS)/libraries/timer/app_timer.c
C_SOURCE_FILES += $(COMPONENTS)/libraries/timer/app_timer_appsh.c
C_SOURCE_FILES += $(COMPONENTS)/libraries/bootloader_dfu/bootloader.c
C_SOURCE_FILES += $(COMPONENTS)/libraries/bootloader_dfu/bootloader_settings.c
C_SOURCE_FILES += $(COMPONENTS)/libraries/bootloader_dfu/bootloader_util.c
C_SOURCE_FILES += $(COMPONENTS)/libraries/crc16/crc16.c
C_SOURCE_FILES += $(COMPONENTS)/libraries/bootloader_dfu/dfu_dual_bank.c
C_SOURCE_FILES += $(COMPONENTS)/libraries/bootloader_dfu/dfu_init_template.c
C_SOURCE_FILES += $(COMPONENTS)/libraries/bootloader_dfu/dfu_transport_ble.c
C_SOURCE_FILES += $(COMPONENTS)/libraries/hci/hci_mem_pool.c
C_SOURCE_FILES += $(COMPONENTS)/libraries/util/nrf_assert.c
C_SOURCE_FILES += $(COMPONENTS)/drivers_nrf/hal/nrf_delay.c
C_SOURCE_FILES += $(COMPONENTS)/drivers_nrf/pstorage/pstorage_raw.c
C_SOURCE_FILES += dfu_ble_svc.c 
C_SOURCE_FILES += main.c
C_SOURCE_FILES += $(COMPONENTS)/ble/common/ble_advdata.c
C_SOURCE_FILES += $(COMPONENTS)/ble/common/ble_conn_params.c
C_SOURCE_FILES += $(COMPONENTS)/ble/ble_services/ble_dfu/ble_dfu.c
C_SOURCE_FILES += $(COMPONENTS)/ble/common/ble_srv_common.c
C_SOURCE_FILES += $(COMPONENTS)/toolchain/system_nrf51.c
C_SOURCE_FILES += $(COMPONENTS)/softdevice/common/softdevice_handler/softdevice_handler.c
C_SOURCE_FILES += $(COMPONENTS)/softdevice/common/softdevice_handler/softdevice_handler_appsh.c

#assembly files common to all targets
ASM_SOURCE_FILES  += $(COMPONENTS)/toolchain/gcc/gcc_startup_nrf51.s

#includes common to all targets
INC_PATHS += -Iconfig
INC_PATHS += -I$(COMPONENTS)/libraries/util
INC_PATHS += -I$(COMPONENTS)/libraries/timer
INC_PATHS += -I$(COMPONENTS)/toolchain
INC_PATHS += -I$(COMPONENTS)/toolchain/gcc
INC_PATHS += -I$(COMPONENTS)/libraries/bootloader_dfu
INC_PATHS += -I$(COMPONENTS)/libraries/scheduler
INC_PATHS += -I$(COMPONENTS)/softdevice/s110/headers
INC_PATHS += -I$(COMPONENTS)/../examples/bsp
INC_PATHS += -I$(COMPONENTS)/drivers_nrf/pstorage
INC_PATHS += -I$(COMPONENTS)/toolchain/gcc
INC_PATHS += -I$(COMPONENTS)/libraries/bootloader_dfu/ble_transport
INC_PATHS += -I$(COMPONENTS)/device
INC_PATHS += -I$(COMPONENTS)/libraries/hci
INC_PATHS += -I$(COMPONENTS)/softdevice/common/softdevice_handler
INC_PATHS += -I$(COMPONENTS)/libraries/crc16
INC_PATHS += -I$(COMPONENTS)/ble/ble_services/ble_dfu
INC_PATHS += -I$(COMPONENTS)/drivers_nrf/hal
INC_PATHS += -I$(COMPONENTS)/ble/common

OBJECT_DIRECTORY = build
LISTING_DIRECTORY = $(OBJECT_DIRECTORY)
OUTPUT_BINARY_DIRECTORY = $(OBJECT_DIRECTORY)

# Sorting removes duplicates
BUILD_DIRECTORIES := $(sort $(OBJECT_DIRECTORY) $(OUTPUT_BINARY_DIRECTORY) $(LISTING_DIRECTORY) )

#flags common to all targets
CFLAGS  = -DSWI_DISABLE0
CFLAGS += -DBOARD_CUSTOM
CFLAGS += -DBOARD_BLE400
CFLAGS += -DSOFTDEVICE_PRESENT
CFLAGS += -DNRF51
CFLAGS += -DS110
CFLAGS += -D__HEAP_SIZE=0
CFLAGS += -DBLE_STACK_SUPPORT_REQD
CFLAGS += -DBSP_DEFINES_ONLY
CFLAGS += -mcpu=cortex-m0
CFLAGS += -mthumb -mabi=aapcs --std=gnu99
CFLAGS += -Wall -Werror -Os
CFLAGS += -mfloat-abi=soft
# keep every function in separate section. This will allow linker to dump unused functions
CFLAGS += -ffunction-sections -fdata-sections -fno-strict-aliasing
CFLAGS += -fno-builtin --short-enums

# keep every function in separate section. This will allow linker to dump unused functions
LDFLAGS += -Xlinker -Map=$(LISTING_DIRECTORY)/$(OUTPUT_FILENAME).map
LDFLAGS += -mthumb -mabi=aapcs -L $(TEMPLATE_PATH) -T$(LINKER_SCRIPT)
LDFLAGS += -mcpu=cortex-m0
# let linker to dump unused sections
LDFLAGS += -Wl,--gc-sections
# use newlib in nano version
LDFLAGS += --specs=nano.specs -lc -lnosys

# Assembler flags
ASMFLAGS += -x assembler-with-cpp
ASMFLAGS += -DSWI_DISABLE0
ASMFLAGS += -DBOARD_PCA10028
ASMFLAGS += -DSOFTDEVICE_PRESENT
ASMFLAGS += -DNRF51
ASMFLAGS += -DS110
ASMFLAGS += -D__HEAP_SIZE=0
ASMFLAGS += -DBLE_STACK_SUPPORT_REQD
ASMFLAGS += -DBSP_DEFINES_ONLY
#default target - first one defined
default: clean nrf51422_xxac

#building all targets
all: clean
	$(NO_ECHO)$(MAKE) -f $(MAKEFILE_NAME) -C $(MAKEFILE_DIR) -e cleanobj
	$(NO_ECHO)$(MAKE) -f $(MAKEFILE_NAME) -C $(MAKEFILE_DIR) -e nrf51422_xxac

#target for printing all targets
help:
	@echo following targets are available:
	@echo 	nrf51422_xxac


C_SOURCE_FILE_NAMES = $(notdir $(C_SOURCE_FILES))
C_PATHS = $(call remduplicates, $(dir $(C_SOURCE_FILES) ) )
C_OBJECTS = $(addprefix $(OBJECT_DIRECTORY)/, $(C_SOURCE_FILE_NAMES:.c=.o) )

ASM_SOURCE_FILE_NAMES = $(notdir $(ASM_SOURCE_FILES))
ASM_PATHS = $(call remduplicates, $(dir $(ASM_SOURCE_FILES) ))
ASM_OBJECTS = $(addprefix $(OBJECT_DIRECTORY)/, $(ASM_SOURCE_FILE_NAMES:.s=.o) )

vpath %.c $(C_PATHS)
vpath %.s $(ASM_PATHS)

OBJECTS = $(C_OBJECTS) $(ASM_OBJECTS)

nrf51422_xxac: LINKER_SCRIPT=./dfu_gcc_nrf51.ld
nrf51422_xxac: $(BUILD_DIRECTORIES) $(OBJECTS)
	@echo Linking target: $(OUTPUT_FILENAME).out
	$(NO_ECHO)$(CC) $(LDFLAGS) $(OBJECTS) $(LIBS) -o $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out
	$(NO_ECHO)$(MAKE) -f $(MAKEFILE_NAME) -C $(MAKEFILE_DIR) -e finalize

## Create build directories
$(BUILD_DIRECTORIES):
	echo $(MAKEFILE_NAME)
	$(MK) $@

# Create objects from C SRC files
$(OBJECT_DIRECTORY)/%.o: %.c
	@echo Compiling file: $(notdir $<)
	$(NO_ECHO)$(CC) $(CFLAGS) $(INC_PATHS) -c -o $@ $<

# Assemble files
$(OBJECT_DIRECTORY)/%.o: %.s
	@echo Compiling file: $(notdir $<)
	$(NO_ECHO)$(CC) $(ASMFLAGS) $(INC_PATHS) -c -o $@ $<


# Link
$(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out: $(BUILD_DIRECTORIES) $(OBJECTS)
	@echo Linking target: $(OUTPUT_FILENAME).out
	$(NO_ECHO)$(CC) $(LDFLAGS) $(OBJECTS) $(LIBS) -o $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out


## Create binary .bin file from the .out file
$(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).bin: $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out
	@echo Preparing: $(OUTPUT_FILENAME).bin
	$(NO_ECHO)$(OBJCOPY) -O binary $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).bin

## Create binary .hex file from the .out file
$(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex: $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out
	@echo Preparing: $(OUTPUT_FILENAME).hex
	$(NO_ECHO)$(OBJCOPY) -O ihex $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex

finalize: genbin genhex echosize

genbin:
	@echo Preparing: $(OUTPUT_FILENAME).bin
	$(NO_ECHO)$(OBJCOPY) -O binary $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).bin

## Create binary .hex file from the .out file
genhex: 
	@echo Preparing: $(OUTPUT_FILENAME).hex
	$(NO_ECHO)$(OBJCOPY) -O ihex $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex

echosize:
	-@echo ""
	$(NO_ECHO)$(SIZE) $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).out
	-@echo ""

clean:
	$(RM) $(BUILD_DIRECTORIES)

cleanobj:
	$(RM) $(BUILD_DIRECTORIES)/*.o

flash:
	@echo "Flashing..." $(OUTPUT_FILENAME)
#	$(NO_ECHO)$(OPENOCD) -s $(OPENOCD_BASE)/scripts -f interface/stlink-v2.cfg -f target/nrf51.cfg -c "program $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_NAME).hex verify reset exit"
#	$(NO_ECHO) $(NRFJPROG) --erasepage 0x00000-0x3fc00
	$(NO_ECHO) $(NRFJPROG) --eraseall
	$(NO_ECHO) $(NRFJPROG) --program $(COMPONENTS)/softdevice/s110/hex/s110_softdevice.hex
	$(NO_ECHO) $(NRFJPROG) --program $(OUTPUT_BINARY_DIRECTORY)/$(OUTPUT_FILENAME).hex
	$(NO_ECHO) $(NRFJPROG) --reset

## Flash softdevice