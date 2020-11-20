#!/usr/bin/tclsh
# Copyright 2020 Efabless Corporation
# Copyright 2020 Sylvain Munaut
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


set ::env(OPENLANE_ROOT) [file dirname [file normalize [info script]]]

lappend ::auto_path "$::env(OPENLANE_ROOT)/scripts/"
package require openlane; # provides the utils as well

proc gen_pdn_sram {args} {
    puts_info " SRAM PDN generation..."
    try_catch python3 $::env(DESIGN_DIR)/sram_power.py -l $::env(MERGED_LEF) -id $::env(CURRENT_DEF) -o $::env(CURRENT_DEF).sram.def |& tee $::env(TERMINAL_OUTPUT) $::env(LOG_DIR)/sram_power.log
    set_def $::env(CURRENT_DEF).sram.def
}


proc run_non_interactive_mode {args} {
	set options {
		{-design required}
		{-save_path optional}
	}
	set flags {-save}
	parse_key_args "run_non_interactive_mode" args arg_values $options flags_map $flags -no_consume

	prep {*}$args

	run_synthesis
	run_floorplan
	run_placement
	run_cts
	gen_pdn
	gen_pdn_sram
	run_routing

	if { $::env(DIODE_INSERTION_STRATEGY) == 2 } {
		run_antenna_check
		heal_antenna_violators; # modifies the routed DEF
	}

	run_magic

	run_magic_spice_export

	if {  [info exists flags_map(-save) ] } {
		if { [info exists arg_values(-save_path)] } {
			save_views 	-lef_path $::env(magic_result_file_tag).lef \
				-def_path $::env(tritonRoute_result_file_tag).def \
				-gds_path $::env(magic_result_file_tag).gds \
				-mag_path $::env(magic_result_file_tag).mag \
				-spice_path $::env(magic_result_file_tag).spice \
				-verilog_path $::env(CURRENT_NETLIST) \
				-save_path $arg_values(-save_path) \
				-tag $::env(RUN_TAG)
		} else  {
			save_views 	-lef_path $::env(magic_result_file_tag).lef \
				-def_path $::env(tritonRoute_result_file_tag).def \
				-mag_path $::env(magic_result_file_tag).mag \
				-gds_path $::env(magic_result_file_tag).gds \
				-spice_path $::env(magic_result_file_tag).spice \
				-verilog_path $::env(CURRENT_NETLIST) \
				-tag $::env(RUN_TAG)
		}
	}

	# Physical verification

	run_magic_drc

	run_lvs; # requires run_magic_spice_export

	run_antenna_check

	generate_final_summary_report

	puts_success "Flow Completed Without Fatal Errors."
}

puts_info {
	___   ____   ___  ____   _       ____  ____     ___
	/   \ |    \ /  _]|    \ | |     /    ||    \   /  _]
	|     ||  o  )  [_ |  _  || |    |  o  ||  _  | /  [_
	|  O  ||   _/    _]|  |  || |___ |     ||  |  ||    _]
	|     ||  | |   [_ |  |  ||     ||  _  ||  |  ||   [_
	\___/ |__| |_____||__|__||_____||__|__||__|__||_____|

}
if {[catch {exec git --git-dir $::env(OPENLANE_ROOT)/.git describe --tags} ::env(OPENLANE_VERSION)]} {
	# if no tags yet
	if {[catch {exec git --git-dir $::env(OPENLANE_ROOT)/.git log --pretty=format:'%h' -n 1} ::env(OPENLANE_VERSION)]} {
		set ::env(OPENLANE_VERSION) "N/A"
	}
}

puts_info "Version: $::env(OPENLANE_VERSION)"
puts_info "Running non-interactively"
run_non_interactive_mode {*}$argv
