# =============================================================================
# Usage:
#   make setup                              — Download UVM 2017-1.0 sources
#   make build                              — Compile
#   make run                                — Build and run default test
#   make run TEST=axi4_lite_wr_rd_test      — Run write-read-back test
#   make clean                              — Remove build artifacts
#   make rebuild                            — Clean and rebuild
# =============================================================================

VERILATOR = verilator

# Root of the repository (resolve relative to this Makefile's location)
MKFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
REPO_ROOT  := $(abspath $(MKFILE_DIR)/..)

# Paths
RTL_DIR = $(REPO_ROOT)/rtl
TB_DIR  = $(REPO_ROOT)/tb

# Top-level testbench module
TOP_MODULE = axi4_lite_tb_top

# UVM source path (downloaded from Accellera if not present)
UVM_HOME ?= $(REPO_ROOT)/1800.2-2017-1.0/src

# -----------------------------------------------------------------------------
# Verilator flags
# -----------------------------------------------------------------------------
VFLAGS  = --binary
VFLAGS += --timing
VFLAGS += --top-module $(TOP_MODULE)
VFLAGS += -j 0
VFLAGS += -Wno-fatal
VFLAGS += --x-assign 0
VFLAGS += --x-initial 0

# UVM-specific flags (per Antmicro Verilator UVM guide)
VFLAGS += +incdir+$(UVM_HOME)
VFLAGS += +define+UVM_NO_DPI

# Project include directories
VFLAGS += +incdir+$(TB_DIR)
VFLAGS += +incdir+$(TB_DIR)/interfaces
VFLAGS += +incdir+$(TB_DIR)/sequences
VFLAGS += +incdir+$(TB_DIR)/agents
VFLAGS += +incdir+$(TB_DIR)/tests
VFLAGS += +incdir+$(MKFILE_DIR)

# Suppress common Verilator warnings
VFLAGS += -Wno-WIDTHEXPAND
VFLAGS += -Wno-WIDTHTRUNC
VFLAGS += -Wno-UNUSEDSIGNAL
VFLAGS += -Wno-UNOPTFLAT
VFLAGS += -Wno-BLKSEQ
VFLAGS += -Wno-CASEINCOMPLETE
VFLAGS += -Wno-LATCH
VFLAGS += -Wno-INITIALDLY
VFLAGS += -Wno-MULTIDRIVEN
VFLAGS += -Wno-TIMESCALEMOD

# -----------------------------------------------------------------------------
# Source files — strict compilation order:
#   1. UVM package (foundation)
#   2. Interface (referenced by pkg and tb_top)
#   3. Project package (pulls in all TB classes via `include)
#   4. DUT
#   5. Assertion module
#   6. Testbench top
# -----------------------------------------------------------------------------
SRC = \
    $(UVM_HOME)/uvm_pkg.sv                   \
    $(TB_DIR)/interfaces/axi4_lite_if.sv     \
    $(TB_DIR)/axi4_lite_pkg.sv               \
    $(RTL_DIR)/axi4_lite_slave.sv            \
    $(TB_DIR)/axi4_lite_assertions.sv        \
    $(TB_DIR)/axi4_lite_tb_top.sv

# Output directory and binary
OBJ_DIR = obj_dir
BINARY  = $(OBJ_DIR)/V$(TOP_MODULE)

# Default test name (override with: make run TEST=axi4_lite_wr_rd_test)
TEST ?= axi4_lite_random_test

# UVM download URL
UVM_TARBALL_URL = https://www.accellera.org/images/downloads/standards/uvm/Accellera-1800.2-2017-1.0.tar.gz
UVM_PKG_SV      = $(UVM_HOME)/uvm_pkg.sv

# -----------------------------------------------------------------------------
# Targets
# -----------------------------------------------------------------------------
.PHONY: all build run clean rebuild help setup

all: run

build: $(BINARY)

# Download UVM sources if not present
setup: $(UVM_PKG_SV)

$(UVM_PKG_SV):
	@echo "=== Downloading UVM 2017-1.0 sources ==="
	curl -sL $(UVM_TARBALL_URL) -o /tmp/uvm-2017.tar.gz
	tar -xzf /tmp/uvm-2017.tar.gz -C $(REPO_ROOT)
	rm -f /tmp/uvm-2017.tar.gz
	@echo "=== UVM sources installed to $(REPO_ROOT)/1800.2-2017-1.0 ==="

$(BINARY): $(UVM_PKG_SV) $(wildcard $(RTL_DIR)/*.sv) $(wildcard $(TB_DIR)/*.sv) \
           $(wildcard $(TB_DIR)/interfaces/*.sv) $(wildcard $(TB_DIR)/agents/*.sv) \
           $(wildcard $(TB_DIR)/sequences/*.sv)  $(wildcard $(TB_DIR)/tests/*.sv)
	@echo "=== Building AXI4-Lite UVM testbench with Verilator ==="
	@echo "UVM_HOME  = $(UVM_HOME)"
	@echo "REPO_ROOT = $(REPO_ROOT)"
	$(VERILATOR) $(VFLAGS) $(SRC)
	@echo "=== Build complete: $(BINARY) ==="

run: $(BINARY)
	@echo "=== Running UVM Test: $(TEST) ==="
	$(BINARY) +UVM_TESTNAME=$(TEST)
	@echo "=== Simulation Complete ==="

clean:
	@echo "=== Cleaning build artifacts ==="
	rm -rf $(OBJ_DIR)
	@echo "=== Clean done ==="

rebuild: clean all

help:
	@echo "Usage:"
	@echo "  make setup                                   - Download UVM 2017-1.0 sources (run once)"
	@echo "  make build                                   - Compile (auto-downloads UVM if needed)"
	@echo "  make run                                     - Build and run default test (axi4_lite_random_test)"
	@echo "  make run TEST=axi4_lite_random_test          - Run 20 random read/write transactions"
	@echo "  make run TEST=axi4_lite_wr_rd_test           - Run 10 write-read-back pairs"
	@echo "  make run TEST=axi4_lite_base_test            - Run base test"
	@echo "  make clean                                   - Remove build artifacts"
	@echo "  make rebuild                                 - Clean and rebuild"
