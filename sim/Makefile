# =============================================================================
# Makefile — AXI4-Lite UVM Simulation (VCS)
# =============================================================================
# Usage:
#   make compile        — compile only
#   make run_random     — compile + run axi4_lite_random_test
#   make run_wr_rd      — compile + run axi4_lite_wr_rd_test
#   make coverage       — open DVE and generate coverage report
#   make clean          — remove all generated artefacts
#   make all            — compile + run_random (default)
# =============================================================================

# -----------------------------------------------------------------------------
# Tool
# -----------------------------------------------------------------------------
VCS      := vcs
DVE      := dve
VERDI    := verdi

# -----------------------------------------------------------------------------
# Directory layout (relative to sim/)
# -----------------------------------------------------------------------------
ROOT     := ..
RTL_DIR  := $(ROOT)/rtl
TB_DIR   := $(ROOT)/tb
SIM_DIR  := .

# -----------------------------------------------------------------------------
# UVM
# -----------------------------------------------------------------------------
UVM_HOME ?= $(VCS_HOME)/etc/uvm-1.2
UVM_OPTS  := -ntb_opts uvm-1.2

# -----------------------------------------------------------------------------
# Compilation flags
# -----------------------------------------------------------------------------
VCS_FLAGS := \
    -sverilog                          \
    $(UVM_OPTS)                        \
    -timescale=1ns/1ps                 \
    -debug_access+all                  \
    -cm line+cond+fsm+tgl+branch       \
    -cm_dir $(SIM_DIR)/coverage.vdb    \
    -assert svaext                     \
    -full64                            \
    -l $(SIM_DIR)/compile.log

# Include paths
VCS_INCDIRS := \
    +incdir+$(TB_DIR)                  \
    +incdir+$(TB_DIR)/sequences        \
    +incdir+$(TB_DIR)/agents           \
    +incdir+$(TB_DIR)/tests            \
    +incdir+$(TB_DIR)/interfaces       \
    +incdir+$(UVM_HOME)/src

# -----------------------------------------------------------------------------
# Source file list  (strict compilation order)
# -----------------------------------------------------------------------------
# 1. UVM package is pulled in automatically via -ntb_opts uvm-1.2
# 2. Project package (includes all TB classes via `include)
# 3. Interface (must be compiled before tb_top)
# 4. DUT
# 5. Assertions
# 6. TB top

SRC_FILES := \
    $(TB_DIR)/axi4_lite_pkg.sv         \
    $(TB_DIR)/interfaces/axi4_lite_if.sv \
    $(RTL_DIR)/axi4_lite_slave.sv      \
    $(TB_DIR)/axi4_lite_assertions.sv  \
    $(TB_DIR)/axi4_lite_env.sv         \
    $(TB_DIR)/tests/axi4_lite_test.sv  \
    $(TB_DIR)/axi4_lite_tb_top.sv

# Top-level module
TOP := axi4_lite_tb_top

# Simulation binary
SIMV := $(SIM_DIR)/simv

# -----------------------------------------------------------------------------
# Simulation run flags
# -----------------------------------------------------------------------------
SIM_FLAGS := \
    -cm line+cond+fsm+tgl+branch       \
    -cm_dir $(SIM_DIR)/coverage.vdb    \
    +UVM_VERBOSITY=UVM_MEDIUM          \
    +ntb_random_seed_automatic

# -----------------------------------------------------------------------------
# Targets
# -----------------------------------------------------------------------------
.PHONY: all compile run_random run_wr_rd coverage clean

all: compile run_random

# ── Compile ──────────────────────────────────────────────────────────────────
compile: $(SIMV)

$(SIMV): $(SRC_FILES)
	@echo "============================================================"
	@echo " Compiling AXI4-Lite UVM testbench"
	@echo "============================================================"
	$(VCS) $(VCS_FLAGS) $(VCS_INCDIRS) \
	    -top $(TOP)                    \
	    $(SRC_FILES)                   \
	    -o $(SIMV)
	@echo "[compile] Done — binary: $(SIMV)"

# ── Run: random test ─────────────────────────────────────────────────────────
run_random: compile
	@echo "============================================================"
	@echo " Running: axi4_lite_random_test"
	@echo "============================================================"
	$(SIMV) $(SIM_FLAGS)                       \
	    +UVM_TESTNAME=axi4_lite_random_test    \
	    -l $(SIM_DIR)/run_random.log
	@echo "[run_random] Log: $(SIM_DIR)/run_random.log"

# ── Run: write-read-back test ─────────────────────────────────────────────────
run_wr_rd: compile
	@echo "============================================================"
	@echo " Running: axi4_lite_wr_rd_test"
	@echo "============================================================"
	$(SIMV) $(SIM_FLAGS)                       \
	    +UVM_TESTNAME=axi4_lite_wr_rd_test     \
	    -l $(SIM_DIR)/run_wr_rd.log
	@echo "[run_wr_rd] Log: $(SIM_DIR)/run_wr_rd.log"

# ── Coverage report ───────────────────────────────────────────────────────────
coverage:
	@echo "============================================================"
	@echo " Generating coverage report"
	@echo "============================================================"
	urg -dir $(SIM_DIR)/coverage.vdb  \
	    -report $(SIM_DIR)/cov_report \
	    -format both
	@echo "[coverage] HTML report: $(SIM_DIR)/cov_report/dashboard.html"

# ── Clean ─────────────────────────────────────────────────────────────────────
clean:
	@echo "[clean] Removing generated files ..."
	rm -rf $(SIMV) $(SIMV).daidir
	rm -rf csrc
	rm -rf *.log ucli.key
	rm -rf $(SIM_DIR)/coverage.vdb $(SIM_DIR)/cov_report
	rm -rf DVEfiles novas.* verdiLog
	@echo "[clean] Done"
