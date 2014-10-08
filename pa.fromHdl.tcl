
# PlanAhead Launch Script for Pre-Synthesis Floorplanning, created by Project Navigator

create_project -name v6pcie -dir "C:/work/xilinx/ml605/planAhead_run_1" -part xc6vlx240tff1156-1
set_param project.pinAheadLayout yes
set srcset [get_property srcset [current_run -impl]]
set_property target_constrs_file "C:/work/xilinx/ml605/MyUCF/ABB3_pcie_4_lane_Emu_FIFO_elink.ucf" [current_fileset -constrset]
set hdlfile [add_files [list {MySource/v6abb64Package_efifo_elink.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/pcie_bram_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/gtx_tx_sync_rate_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/gtx_rx_valid_filter_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/gtx_drp_chanalign_fix_3752_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/FF_tagram64x36.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/DMA_FSM.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/DMA_Calculate.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_sfifo_15x128.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/pcie_pipe_misc_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/pcie_pipe_lane_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/pcie_brams_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/gtx_wrapper_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/Tx_Output_Arbitor.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/tx_Mem_Reader.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/rx_usDMA_Channel.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/rx_MWr_Channel.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/rx_MRd_Channel.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/rx_dsDMA_Channel.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/rx_CplD_Channel.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/RxIn_Delays.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/Interrupts.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/pcie_upconfig_fix_3451_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/pcie_pipe_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/pcie_gtx_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/pcie_bram_top_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_mBuf_128x72.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {MyUserLogic/UserLogic_00/user_logic_cw.ngc}]
add_files [list {MyUserLogic/UserLogic_00/inout_logic_cw.ngc}]
set hdlfile [add_files [list {MySource/tx_Transact.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/rx_Transact.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/Registers.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/DDR_Blinker.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_prime_fifo_plain.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/pcie_reset_delay_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/pcie_clocking_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/pcie_2_0_v6.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_eb_fifo_counted_resized.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_bram4096x64.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MyUserLogic/UserLogic_00/PCIe_UserLogic_00.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/tlpControl.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/FIFO_Wrapper_Loopback.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/FIFO_Wrapper.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/Emul.v}]]
set_property file_type Verilog $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/bram_DDRs_Control_Loopback.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/bram_DDRs_Control.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {ipcore_dir_ISE13.3/v6_pcie_v1_7_x4/source/v6_pcie_v1_7_x4.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
set hdlfile [add_files [list {MySource/v6eb_pcie.vhd}]]
set_property file_type VHDL $hdlfile
set_property library work $hdlfile
add_files [list {ipcore_dir_ISE13.3/v6_bram4096x64.ngc}]
add_files [list {ipcore_dir_ISE13.3/v6_eb_fifo_counted_resized.ngc}]
add_files [list {ipcore_dir_ISE13.3/v6_mBuf_128x72.ngc}]
add_files [list {ipcore_dir_ISE13.3/v6_prime_fifo_plain.ngc}]
add_files [list {ipcore_dir_ISE13.3/v6_sfifo_15x128.ngc}]
set_property top v6pcieDMA $srcset
add_files [list {C:/work/xilinx/ml605/MyUCF/ABB3_pcie_4_lane_Emu_FIFO_elink.ucf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_bram4096x64.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_eb_fifo_counted_new.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_eb_fifo_counted_resized.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_mBuf_128x72.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_prime_fifo_plain.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir_ISE13.3/v6_sfifo_15x128.ncf}] -fileset [get_property constrset [current_run]]
open_rtl_design -part xc6vlx240tff1156-1
