RTL := $(wildcard rtl/*.v)
.PHONY: test regression wave spectrum clean
test:
	mkdir -p results
	iverilog -g2005 -Wall -s dds_tb -o results/dds_sim $(RTL) tb/dds_reference.v tb/dds_tb.v
	vvp results/dds_sim
wave:
	$(MAKE) test
	vvp results/dds_sim +vcd
regression:
	mkdir -p results
	iverilog -g2005 -Wall -s dds_regression_tb -o results/dds_regression_sim $(RTL) tb/dds_reference.v tb/dds_regression_tb.v
	vvp results/dds_regression_sim
spectrum:
	python3 scripts/analyze_spectrum.py
clean:
	rm -f results/dds_sim results/dds.vcd results/waveform.csv
