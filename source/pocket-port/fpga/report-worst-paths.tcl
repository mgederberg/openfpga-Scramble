package require ::quartus::project
package require ::quartus::sta

project_open ap_core
create_timing_netlist
read_sdc
update_timing_netlist

set clocks [get_clocks *]
puts "=== AVAILABLE CLOCKS ==="
foreach_in_collection clk $clocks {
    puts [get_clock_info -name $clk]
}

puts "=== WORST SETUP PATHS ==="
report_timing \
    -setup \
    -npaths 10 \
    -detail full_path \
    -file worst-setup-paths.txt

delete_timing_netlist
project_close
