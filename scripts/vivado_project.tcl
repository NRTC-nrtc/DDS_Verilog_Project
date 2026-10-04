if {$argc != 1} { error "Usage: vivado -mode batch -source scripts/vivado_project.tcl -tclargs FPGA_PART" }
set root [file normalize [file join [file dirname [info script]] ..]]
create_project dds [file join $root vivado_project] -part [lindex $argv 0] -force
add_files [glob [file join $root rtl *.v]]
set lut [file normalize [file join $root mem sine_lut.hex]]
add_files $lut
set_property file_type {Memory Initialization Files} [get_files $lut]
set_property top dds_top [get_filesets sources_1]
set_property generic [list ROM_FILE=\"$lut\"] [get_filesets sources_1]
add_files -fileset constrs_1 [file join $root constraints dds.xdc]
add_files -fileset sim_1 [glob [file join $root tb *.v]]
set_property top dds_tb [get_filesets sim_1]
set_property generic [list ROM_FILE=\"$lut\"] [get_filesets sim_1]
# Prepare the normal managed XSim working directory for testbench output files.
file mkdir [file join $root vivado_project dds.sim sim_1 behav xsim results]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
