
# PlanAhead Launch Script for Post PAR Floorplanning, created by Project Navigator

create_project -name v6pcie -dir "/home/vladimir/ISEAC701/planAhead_run_1" -part xc7a200tfbg676-2
set srcset [get_property srcset [current_run -impl]]
set_property design_mode GateLvl $srcset
set_property edif_top_file "/home/vladimir/ISEAC701/v6pcieDMA_cs.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {/home/vladimir/ISEAC701} {MyUserLogic/UserLogic_00} {ipcore_dir} {ipcore_dir_ISE13.3} }
add_files [list {ipcore_dir/v7_mBuf_128x72.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/v7_eb_fifo_counted_resized.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/v7_sfifo_15x128.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/fifomodule.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_eb_fifo_counted_new.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_bram4096x64.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_mBuf_128x72.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_prime_fifo_plain.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_eb_fifo_counted_resized.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_sfifo_15x128.ncf}] -fileset [get_property constrset [current_run]]
set_property target_constrs_file "/home/vladimir/ISEAC701/MyUCF/ABB3_pcie_4_lane_Emu_FIFO_elink.ucf" [current_fileset -constrset]
add_files [list {/home/vladimir/ISEAC701/MyUCF/ABB3_pcie_4_lane_Emu_FIFO_elink.ucf}] -fileset [get_property constrset [current_run]]
link_design
read_xdl -file "/home/vladimir/ISEAC701/v6pcieDMA.ncd"
if {[catch {read_twx -name results_1 -file "/home/vladimir/ISEAC701/v6pcieDMA.twx"} eInfo]} {
   puts "WARNING: there was a problem importing \"/home/vladimir/ISEAC701/v6pcieDMA.twx\": $eInfo"
}
