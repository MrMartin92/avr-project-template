PROJECT := projectname
MCU := atmega328pb
PROGRAMMER := atmelice_isp

#ATPACK_DIR := ../lina/toolchains/avr/atpacks/Atmel.ATmega_DFP.1.4.351

SRCS := main.c

# Below this line you will find black magic!
# ------------------------------------------------------------------------------

# Special targets
.SECONDEXPANSION:
.DELETE_ON_ERROR:

# Folders
SRC_DIR := src
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj
DEP_DIR := $(BUILD_DIR)/dep

# Programs
CC := avr-gcc
OBJCOPY := avr-objcopy
OBJDUMP := avr-objdump
RM := rm -rf
AVRDUDE := avrdude

# Flags
CFLAGS := -mmcu=$(MCU) -Os
LDFLAGS := -mmcu=$(MCU)

ifdef ATPACK_DIR
	CFLAGS += -B $(ATPACK_DIR)/gcc/dev/$(MCU) -I $(ATPACK_DIR)/include
	LDFLAGS += -B $(ATPACK_DIR)/gcc/dev/$(MCU)
endif

# Compiling/Linking
.PHONY: all
all: $(PROJECT).elf $(PROJECT).hex $(PROJECT).eep size

$(PROJECT).elf: $(SRCS:%.c=$(OBJ_DIR)/%.o)
	$(CC) $(LDFLAGS) -o $@ $^

$(PROJECT).hex: $(PROJECT).elf
	$(OBJCOPY) -j .text -j .data -O ihex $< $@

$(PROJECT).eep: $(PROJECT).elf
	$(OBJCOPY) -j .eeprom -O ihex $< $@

$(OBJ_DIR)/%.o $(DEP_DIR)/%.d: $(SRC_DIR)/%.c | $(OBJ_DIR)/$$(*D)/. $(DEP_DIR)/$$(*D)/. # The stuff behind "|" will create all subfolders
	$(CC) -c $(CFLAGS) -MD -MP -MF $(DEP_DIR)/$*.d -o $(OBJ_DIR)/$*.o $^

# Programming
.PHONY: flash
flash: $(PROJECT).hex
	$(AVRDUDE) -p $(MCU) -c $(PROGRAMMER) -s -U flash:w:$<:i

.PHONY: flash_eeprom
flash_eeprom: $(PROJECT).eep
	$(AVRDUDE) -p $(MCU) -c $(PROGRAMMER) -s -U eeprom:w:$<:i

.PHONY: erase
erase:
	$(AVRDUDE) -p $(MCU) -c $(PROGRAMMER) -s -e

#avr-size --mcu=$(MCU) -C $< # Old Version, with only supported AVRs
#New Version, all AVRs supported. But needs quite new toolchain
.PHONY: size
size: $(PROJECT).elf
	$(OBJDUMP) -Pmem-usage $<


# Misc. Targets
.PHONY: clean
clean:
	$(RM) $(BUILD_DIR)
	$(RM) $(PROJECT).elf 
	$(RM) $(PROJECT).hex
	$(RM) $(PROJECT).eep

# The following two targets are creating all subfolders
.PRECIOUS: $(BUILD_DIR)/. $(BUILD_DIR)%/.
$(BUILD_DIR)/.:
	mkdir -p $@

$(BUILD_DIR)%/.:
	mkdir -p $@

-include $(SRCS:%.c=$(DEP_DIR)/%.d)