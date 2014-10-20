
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name v6pcie -dir "/home/vladimir/NEWAC701/ISEAC701/planAhead_run_2" -part xc7a200tfbg676-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "/home/vladimir/NEWAC701/ISEAC701/v6pcieDMA_cs.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {/home/vladimir/NEWAC701/ISEAC701} {ipcore_dir} }
add_files [list {ipcore_dir/v7_mBuf_128x72.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/v7_eb_fifo_counted_resized.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/v7_sfifo_15x128.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/fifomodule.ncf}] -fileset [get_property constrset [current_run]]
set_property target_constrs_file "ABB3_pcie_4_lane_Emu_FIFO_elink.ucf" [current_fileset -constrset]
add_files [list {ABB3_pcie_4_lane_Emu_FIFO_elink.ucf}] -fileset [get_property constrset [current_run]]
link_design
