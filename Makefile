# Tool binary names
IVERILOG ?= iverilog
GTKWAVE ?= gtkwave

# File paths
SRC_DIR ?= src
TEST_DIR ?= test
BUILD_DIR := build

SRC_FILES := $(shell find $(SRC_DIR)/ -type f -name "*.v")
TB_FILES := $(shell find $(TEST_DIR)/ -type f -name "*_tb.v")


build/%.d: %.v
	@mkdir -p $(dir $@)

sim run::
ifeq ($(V),)
	$(error Define target name first, e.g.: make $@ V=myfile)
endif

build/%.sim build/%.vcd &: %.v build/%.d
	$(IVERILOG) -g2012 -I $(SRC_DIR) -I test/ -DVCD_FILE='"build/$(<:.v=.vcd)"' -o "build/$(<:.v=.sim)" $(SRC_FILES) $<

.PHONY: run
run:: build/$(V:.v=.sim)
	./$< | tee run.log

.PHONY: sim
wave:: build/$(V:.v=.vcd)
	$(GTKWAVE) build/$(V:.v=.vcd)

.PHONY: test
test::
	@echo "Running tests: $(TB_FILES)"
	@set -e; \
	for v in $(TB_FILES); do \
		echo $(MAKE) run V=$$v; \
		$(CHRONIC) $(MAKE) run V=$$v; \
		grep "^// TEST:" $$v | sed 's|// TEST:||' > /tmp/expected_tests.txt; \
		fail=0; \
		while read testname; do \
			echo "Trying to find [TEST:$$testname PASSED] in run.log ..."; \
			if ! grep -q "\[TEST:$$testname PASSED\]" run.log; then \
				echo "ERROR: Test $$testname did not pass."; \
				fail=1; \
			fi; \
		done < /tmp/expected_tests.txt; \
		rm /tmp/expected_tests.txt; \
		if [ $$fail -ne 0 ]; then exit 1; fi; \
	done; \
	echo "All testbenches PASSED."

help:
	@echo "Usage: make [TARGET] V=mysource"
	@echo "Targets:"
	@echo "  run V=[file.v]  Run specific verilog simulation."
	@echo "  wave            Open VCD file in GtkWave."
	@echo "  test            Run simulation of all testbentches."
	@echo "  clean           Remove generated files"
	@echo "  help            Show this help message"
