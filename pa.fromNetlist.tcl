
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name v6pcie -dir "/home/vladimir/NEWDMA/planAhead_run_1" -part xc6vlx240tff1156-1
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "/home/vladimir/NEWDMA/v6pcieDMA.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {/home/vladimir/NEWDMA} {MyUserLogic/UserLogic_00} {ipcore_dir_ISE13.3} }
add_files [list {ipcore_dir_ISE13.3/v6_eb_fifo_counted_new.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_bram4096x64.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_mBuf_128x72.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_prime_fifo_plain.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_eb_fifo_counted_resized.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_sfifo_15x128.ncf}] -fileset [get_property constrset [current_run]]
set_property target_constrs_file "/home/vladimir/NEWDMA/MyUCF/ABB3_pcie_4_lane_Emu_FIFO_elink.ucf" [current_fileset -constrset]
add_files [list {/home/vladimir/NEWDMA/MyUCF/ABB3_pcie_4_lane_Emu_FIFO_elink.ucf}] -fileset [get_property constrset [current_run]]
link_design
