set ::env(DESIGN_NAME) "striVe_soc"

set ::env(VERILOG_FILES) "./designs/striVe_soc_oram/src/striVe_soc.v"

set ::env(EXTRA_LEFS) [glob $::env(DESIGN_DIR)/src/lef/*.lef]

set ::env(PDN_CFG) ./designs/striVe_soc_oram/pdn.tcl

set ::env(CLOCK_PERIOD) "10"
# which clock port ??
set ::env(CLOCK_PORT) "clk"


set ::env(CLOCK_NET) "clk"

# set ::env(SYNTH_NO_FLAT) 1
set ::env(RUN_MAGIC) 1
set ::env(MAGIC_ZEROIZE_ORIGIN) 1

set filename $::env(OPENLANE_ROOT)/designs/$::env(DESIGN_NAME)/$::env(PDK)_$::env(PDK_VARIANT)_config.tcl
if { [file exists $filename] == 1} {
	source $filename
}