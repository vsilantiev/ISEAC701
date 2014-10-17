----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:12:51 01 Feb 2010
-- Design Name: 
-- Module Name:    v6pcieDMA - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- 
-- Revision 1.00 - File Released
-- 
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.abb64Package.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity v6pcieDMA is
  generic 
  (
   constant pcieLanes            : integer     := 4; --C_NUM_PCIE_LANES
   PCIE_EXT_CLK                  : string :="FALSE";  -- Use External Clocking Module
   PL_FAST_TRAIN                 : string := "FALSE";
	UPSTREAM_FACING					: string := "TRUE";
   C_DATA_WIDTH                  : integer range 64 to 128 := 64
  );
  port 
  (
   userclk_66MHz		   			: in std_logic;    --66  MHz USER Socket SingleEnded
	userclk_200MHz_n              : in std_logic;    --200 MHz USER Socket LVDS N
	userclk_200MHz_p              : in std_logic;    --200 MHz USER Socket LVDS P
   -- DPR blinker
   LEDs_IO_pin                   : out   std_logic_vector(7 downto 0);
   -- PCIe transceivers
   pci_exp_rxp                   : in    std_logic_vector(pcieLanes - 1 downto 0);
   pci_exp_rxn                   : in    std_logic_vector(pcieLanes - 1 downto 0);
   pci_exp_txp                   : out   std_logic_vector(pcieLanes - 1 downto 0);
   pci_exp_txn                   : out   std_logic_vector(pcieLanes - 1 downto 0);
   -- Necessity signals
   sys_clk_p                     : in    std_logic; --125 MHz PCIe Clock
   sys_clk_n                     : in    std_logic; --125 MHz PCIe Clock
   sys_reset_n                   : in    std_logic;  --Reset			 
	-- PART ADC
	adc_clk_in_p          			: in  std_logic;
	adc_clk_in_n          			: in  std_logic;
	adc_data_in_p         			: in  std_logic_vector(7 downto 0);
	adc_data_in_n         			: in  std_logic_vector(7 downto 0);
	adc_data_or_p        			: in  std_logic;
	adc_data_or_n         			: in  std_logic;
	delay_clk             			: in  std_logic;
	real_strobe_signal			   : out std_logic;
	real_soa_signal 					: out std_logic
  );                       

end entity v6pcieDMA;
architecture Behavioral of v6pcieDMA is
-- PART ADC
   component pcie_axi_trn_bridge
  generic (
    C_DATA_WIDTH                  : integer range 32 to 128 := 64;
   -- RBAR_WIDTH                    : integer := 8;
	RBAR_WIDTH : integer := 7;
    REM_WIDTH                     : integer range 1 to 2 :=1
  );
  port (
    user_clk               : in  std_logic;
    user_reset             : in  std_logic;
    user_lnk_up            : in  std_logic;

    s_axis_tx_tdata        : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
    s_axis_tx_tvalid       : out std_logic;
    s_axis_tx_tready       : in  std_logic;
    s_axis_tx_tkeep        : out std_logic_vector((C_DATA_WIDTH/8)-1 downto 0);
    s_axis_tx_tlast        : out std_logic;
    s_axis_tx_tuser        : out std_logic_vector( 3 downto 0);

    m_axis_rx_tdata        : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    m_axis_rx_tvalid       : in  std_logic;
    m_axis_rx_tready       : out std_logic;
    m_axis_rx_tkeep        : in  std_logic_vector((C_DATA_WIDTH/8)-1 downto 0);
    m_axis_rx_tlast        : in  std_logic;
    m_axis_rx_tuser        : in  std_logic_vector(21 downto 0);

    trn_td                 : in  std_logic_vector(C_DATA_WIDTH-1 downto 0);
    trn_tsof               : in  std_logic;
    trn_teof               : in  std_logic;
    trn_tsrc_rdy           : in  std_logic;
    trn_tdst_rdy           : out std_logic;
    trn_tsrc_dsc           : in  std_logic;
    trn_trem               : in  std_logic_vector(0 downto 0);
    trn_terrfwd            : in  std_logic;
    trn_tstr               : in  std_logic;
    trn_tecrc_gen          : in  std_logic;

    trn_rd                 : out std_logic_vector(C_DATA_WIDTH-1 downto 0);
    trn_rsof               : out std_logic;
    trn_reof               : out std_logic;
    trn_rsrc_rdy           : out std_logic;
    trn_rdst_rdy           : in  std_logic;
    trn_rsrc_dsc           : out std_logic;
    trn_rrem               : out std_logic_vector(0 downto 0);
    trn_rerrfwd            : out std_logic;
    --trn_rbar_hit           : out std_logic_vector(7 downto 0)
	 trn_rbar_hit           : out std_logic_vector(6 downto 0)

  );
  end component;
 
 component v7_pcie    generic (
           PL_FAST_TRAIN                              : string := "FALSE";
      PCIE_EXT_CLK                               : string := "FALSE";
      UPSTREAM_FACING                            : string := "TRUE"
    );
    port (
     -------------------------------------------------------------------------------------------------------------------
     -- 1. PCI Express (pci_exp) Interface                                                                            --
     -------------------------------------------------------------------------------------------------------------------
      pci_exp_txp                                : out std_logic_vector(3 downto 0);
      pci_exp_txn                                : out std_logic_vector(3 downto 0);
      pci_exp_rxp                                : in std_logic_vector(3 downto 0);
      pci_exp_rxn                                : in std_logic_vector(3 downto 0);

     -------------------------------------------------------------------------------------------------------------------
     -- 2. Clocking Interface                                                                                         --
     -------------------------------------------------------------------------------------------------------------------
      PIPE_PCLK_IN                               : in std_logic;
      PIPE_RXUSRCLK_IN                           : in std_logic;
      PIPE_RXOUTCLK_IN                           : in std_logic_vector(3 downto 0);
      PIPE_DCLK_IN                               : in std_logic;
      PIPE_USERCLK1_IN                           : in std_logic;
      PIPE_USERCLK2_IN                           : in std_logic;
      PIPE_OOBCLK_IN                             : in std_logic;
      PIPE_MMCM_LOCK_IN                          : in std_logic;

      PIPE_TXOUTCLK_OUT                          : out std_logic;
      PIPE_RXOUTCLK_OUT                          : out std_logic_vector(3 downto 0);
      PIPE_PCLK_SEL_OUT                          : out std_logic_vector(3 downto 0);
      PIPE_GEN3_OUT                              : out std_logic;

     -------------------------------------------------------------------------------------------------------------------
     -- 3. AXI-S Interface                                                                                            --
     -------------------------------------------------------------------------------------------------------------------
      -- Common
      user_clk_out                               : out std_logic;
      user_reset_out                             : out std_logic;
      user_lnk_up                                : out std_logic;

      -- TX
      tx_buf_av                                  : out std_logic_vector(5 downto 0);
      tx_cfg_req                                 : out std_logic;
      tx_err_drop                                : out std_logic;
      s_axis_tx_tready                           : out std_logic;
      s_axis_tx_tdata                            : in std_logic_vector((C_DATA_WIDTH - 1) downto 0);
      s_axis_tx_tkeep                            : in std_logic_vector((C_DATA_WIDTH / 8 - 1) downto 0);
      s_axis_tx_tlast                            : in std_logic;
      s_axis_tx_tvalid                           : in std_logic;
      s_axis_tx_tuser                            : in std_logic_vector(3 downto 0);
      tx_cfg_gnt                                 : in std_logic;

      -- RX
      m_axis_rx_tdata                            : out std_logic_vector((C_DATA_WIDTH - 1) downto 0);
      m_axis_rx_tkeep                            : out std_logic_vector((C_DATA_WIDTH / 8 - 1) downto 0);
      m_axis_rx_tlast                            : out std_logic;
      m_axis_rx_tvalid                           : out std_logic;
      m_axis_rx_tready                           : in std_logic;
      m_axis_rx_tuser                            : out std_logic_vector(21 downto 0);
      rx_np_ok                                   : in std_logic;
      rx_np_req                                  : in std_logic;

      -- Flow Control
      fc_cpld                                    : out std_logic_vector(11 downto 0);
      fc_cplh                                    : out std_logic_vector(7 downto 0);
      fc_npd                                     : out std_logic_vector(11 downto 0);
      fc_nph                                     : out std_logic_vector(7 downto 0);
      fc_pd                                      : out std_logic_vector(11 downto 0);
      fc_ph                                      : out std_logic_vector(7 downto 0);
      fc_sel                                     : in std_logic_vector(2 downto 0);

     -------------------------------------------------------------------------------------------------------------------
     -- 4. Configuration (CFG) Interface                                                                              --
     -------------------------------------------------------------------------------------------------------------------
     ---------------------------------------------------------------------
      -- EP and RP                                                      --
     ---------------------------------------------------------------------
      cfg_mgmt_do                                : out std_logic_vector (31 downto 0);
      cfg_mgmt_rd_wr_done                        : out std_logic;

      cfg_status                                 : out std_logic_vector(15 downto 0);
      cfg_command                                : out std_logic_vector(15 downto 0);
      cfg_dstatus                                : out std_logic_vector(15 downto 0)  := (Others =>'0');
      cfg_dcommand                               : out std_logic_vector(15 downto 0);
      cfg_lstatus                                : out std_logic_vector(15 downto 0);
      cfg_lcommand                               : out std_logic_vector(15 downto 0);
      cfg_dcommand2                              : out std_logic_vector(15 downto 0);
      cfg_pcie_link_state                        : out std_logic_vector(2 downto 0);

      cfg_pmcsr_pme_en                           : out std_logic;
      cfg_pmcsr_powerstate                       : out std_logic_vector(1 downto 0);
      cfg_pmcsr_pme_status                       : out std_logic;
      cfg_received_func_lvl_rst                  : out std_logic;

      -- Management Interface
      cfg_mgmt_di                                : in std_logic_vector (31 downto 0);
      cfg_mgmt_byte_en                           : in std_logic_vector (3 downto 0);
      cfg_mgmt_dwaddr                            : in std_logic_vector (9 downto 0);
      cfg_mgmt_wr_en                             : in std_logic;
      cfg_mgmt_rd_en                             : in std_logic;
      cfg_mgmt_wr_readonly                       : in std_logic;

      -- Error Reporting Interface
      cfg_err_ecrc                               : in std_logic;
      cfg_err_ur                                 : in std_logic;
      cfg_err_cpl_timeout                        : in std_logic;
      cfg_err_cpl_unexpect                       : in std_logic;
      cfg_err_cpl_abort                          : in std_logic;
      cfg_err_posted                             : in std_logic;
      cfg_err_cor                                : in std_logic;
      cfg_err_atomic_egress_blocked              : in std_logic;
      cfg_err_internal_cor                       : in std_logic;
      cfg_err_malformed                          : in std_logic;
      cfg_err_mc_blocked                         : in std_logic;
      cfg_err_poisoned                           : in std_logic;
      cfg_err_norecovery                         : in std_logic;
      cfg_err_tlp_cpl_header                     : in std_logic_vector(47 downto 0);
      cfg_err_cpl_rdy                            : out std_logic;
      cfg_err_locked                             : in std_logic;
      cfg_err_acs                                : in std_logic;
      cfg_err_internal_uncor                     : in std_logic;
      cfg_trn_pending                            : in std_logic;
      cfg_pm_halt_aspm_l0s                       : in std_logic;
      cfg_pm_halt_aspm_l1                        : in std_logic;
      cfg_pm_force_state_en                      : in std_logic;
      cfg_pm_force_state                         : std_logic_vector(1 downto 0);
      cfg_dsn                                    : std_logic_vector(63 downto 0);

     ---------------------------------------------------------------------
      -- EP Only                                                        --
     ---------------------------------------------------------------------
      cfg_interrupt                              : in std_logic;
      cfg_interrupt_rdy                          : out std_logic;
      cfg_interrupt_assert                       : in std_logic;
      cfg_interrupt_di                           : in std_logic_vector(7 downto 0);
      cfg_interrupt_do                           : out std_logic_vector(7 downto 0);
      cfg_interrupt_mmenable                     : out std_logic_vector(2 downto 0);
      cfg_interrupt_msienable                    : out std_logic;
      cfg_interrupt_msixenable                   : out std_logic;
      cfg_interrupt_msixfm                       : out std_logic;
      cfg_interrupt_stat                         : in std_logic;
      cfg_pciecap_interrupt_msgnum               : in std_logic_vector(4 downto 0);
      cfg_to_turnoff                             : out std_logic;
      cfg_turnoff_ok                             : in std_logic;
      cfg_bus_number                             : out std_logic_vector(7 downto 0);
      cfg_device_number                          : out std_logic_vector(4 downto 0);
      cfg_function_number                        : out std_logic_vector(2 downto 0);
      cfg_pm_wake                                : in std_logic;

     ---------------------------------------------------------------------
      -- RP Only                                                        --
     ---------------------------------------------------------------------
      cfg_pm_send_pme_to                         : in std_logic;
      cfg_ds_bus_number                          : in std_logic_vector(7 downto 0);
      cfg_ds_device_number                       : in std_logic_vector(4 downto 0);
      cfg_ds_function_number                     : in std_logic_vector(2 downto 0);

      cfg_mgmt_wr_rw1c_as_rw                     : in std_logic;
      cfg_msg_received                           : out std_logic;
      cfg_msg_data                               : out std_logic_vector(15 downto 0);

      cfg_bridge_serr_en                         : out std_logic;
      cfg_slot_control_electromech_il_ctl_pulse  : out std_logic;
      cfg_root_control_syserr_corr_err_en        : out std_logic;
      cfg_root_control_syserr_non_fatal_err_en   : out std_logic;
      cfg_root_control_syserr_fatal_err_en       : out std_logic;
      cfg_root_control_pme_int_en                : out std_logic;
      cfg_aer_rooterr_corr_err_reporting_en      : out std_logic;
      cfg_aer_rooterr_non_fatal_err_reporting_en : out std_logic;
      cfg_aer_rooterr_fatal_err_reporting_en     : out std_logic;
      cfg_aer_rooterr_corr_err_received          : out std_logic;
      cfg_aer_rooterr_non_fatal_err_received     : out std_logic;
      cfg_aer_rooterr_fatal_err_received         : out std_logic;

      cfg_msg_received_err_cor                   : out std_logic;
      cfg_msg_received_err_non_fatal             : out std_logic;
      cfg_msg_received_err_fatal                 : out std_logic;
      cfg_msg_received_pm_as_nak                 : out std_logic;
      cfg_msg_received_pm_pme                    : out std_logic;
      cfg_msg_received_pme_to_ack                : out std_logic;
      cfg_msg_received_assert_int_a              : out std_logic;
      cfg_msg_received_assert_int_b              : out std_logic;
      cfg_msg_received_assert_int_c              : out std_logic;
      cfg_msg_received_assert_int_d              : out std_logic;
      cfg_msg_received_deassert_int_a            : out std_logic;
      cfg_msg_received_deassert_int_b            : out std_logic;
      cfg_msg_received_deassert_int_c            : out std_logic;
      cfg_msg_received_deassert_int_d            : out std_logic;
      cfg_msg_received_setslotpowerlimit         : out std_logic;

     -------------------------------------------------------------------------------------------------------------------
     -- 5. Physical Layer Control and Status (PL) Interface                                                           --
     -------------------------------------------------------------------------------------------------------------------
      pl_directed_link_change                    : in std_logic_vector(1 downto 0);
      pl_directed_link_width                     : in std_logic_vector(1 downto 0);
      pl_directed_link_speed                     : in std_logic;
      pl_directed_link_auton                     : in std_logic;
      pl_upstream_prefer_deemph                  : in std_logic;

      pl_sel_lnk_rate                            : out std_logic;
      pl_sel_lnk_width                           : out std_logic_vector(1 downto 0);
      pl_ltssm_state                             : out std_logic_vector(5 downto 0);
      pl_lane_reversal_mode                      : out std_logic_vector(1 downto 0);

      pl_phy_lnk_up                              : out std_logic;
      pl_tx_pm_state                             : out std_logic_vector(2 downto 0);
      pl_rx_pm_state                             : out std_logic_vector(1 downto 0);

      pl_link_upcfg_cap                          : out std_logic;
      pl_link_gen2_cap                           : out std_logic;
      pl_link_partner_gen2_supported             : out std_logic;
      pl_initial_link_width                      : out std_logic_vector(2 downto 0);

      pl_directed_change_done                    : out std_logic;

     ---------------------------------------------------------------------
      -- EP Only                                                        --
     ---------------------------------------------------------------------
      pl_received_hot_rst                        : out std_logic;
     ---------------------------------------------------------------------
      -- RP Only                                                        --
     ---------------------------------------------------------------------
      pl_transmit_hot_rst                        : in std_logic;
      pl_downstream_deemph_source                : in std_logic;
     -------------------------------------------------------------------------------------------------------------------
     -- 6. AER interface                                                                                              --
     -------------------------------------------------------------------------------------------------------------------
      cfg_err_aer_headerlog                      : in std_logic_vector(127 downto 0);
      cfg_aer_interrupt_msgnum                   : in std_logic_vector(4 downto 0);
      cfg_err_aer_headerlog_set                  : out std_logic;
      cfg_aer_ecrc_check_en                      : out std_logic;
      cfg_aer_ecrc_gen_en                        : out std_logic;
     -------------------------------------------------------------------------------------------------------------------
     -- 7. VC interface                                                                                               --
     -------------------------------------------------------------------------------------------------------------------
      cfg_vc_tcvc_map                            : out std_logic_vector(6 downto 0);

     -------------------------------------------------------------------------------------------------------------------
     -- 8. System(SYS) Interface                                                                                      --
     -------------------------------------------------------------------------------------------------------------------
      PIPE_MMCM_RST_N                            : in std_logic;   --     // Async      | Async
      sys_clk                                    : in std_logic;
      sys_rst_n                                  : in std_logic);
  end component; 
 

 
 component ADC_emul
	port (
			 debug_data				   :in std_logic_vector (15 downto 0);
			debug_data1					:in std_logic_vector (63 downto 0);
			debug_data2 :in std_logic;
			debug_data3 :in std_logic;
--			fifo_re :out std_logic;
			 trn_clk					  : in  std_logic;
			 adc_clk_in_p          : in  std_logic;
			 adc_clk_in_n          : in  std_logic;
			 adc_data_in_p         : in  std_logic_vector(7 downto 0);
			 adc_data_in_n         : in  std_logic_vector(7 downto 0);
			 adc_data_or_p         : in  std_logic;
			 adc_data_or_n         : in  std_logic;
			 delay_clk             : in  std_logic;
			 -- data ADC to BRAM
			 bram_wr_din			  : out std_logic_vector(63 downto 0); -- ADC to BRAM data
			 -- addr for data ADC to BRAM
			 bram_wr_addr			  : out std_logic_vector(11 downto 0); -- for brma
			 -- wr_en ???
			-- bram_wr_en				  : out std_logic_vector(7 downto 0);
			-- User reg write PC to adc logic
			reg01_td: in std_logic_vector(31 downto 0); 
			reg01_tv: in std_logic;
			reg02_td: in std_logic_vector(31 downto 0); 
			reg02_tv: in std_logic; 
			reg03_td: in std_logic_vector(31 downto 0); 
			reg03_tv: in std_logic; 
			reg04_td: in std_logic_vector(31 downto 0); 
			reg04_tv: in std_logic; 
			reg05_td: in std_logic_vector(31 downto 0); 
			reg05_tv: in std_logic; 
			reg06_td: in std_logic_vector(31 downto 0); 
			reg06_tv: in std_logic; 
			reg07_td: in std_logic_vector(31 downto 0); 
			reg07_tv: in std_logic; 
			reg08_td: in std_logic_vector(31 downto 0); 
			reg08_tv: in std_logic; 
			reg09_td: in std_logic_vector(31 downto 0); 
			reg09_tv: in std_logic; 
			reg10_td: in std_logic_vector(31 downto 0); 
			reg10_tv: in std_logic; 
			reg11_td: in std_logic_vector(31 downto 0); 
			reg11_tv: in std_logic; 
			reg12_td: in std_logic_vector(31 downto 0); 
			reg12_tv: in std_logic; 
			reg13_td: in std_logic_vector(31 downto 0); 
			reg13_tv: in std_logic; 
			reg14_td: in std_logic_vector(31 downto 0); 
			reg14_tv: in std_logic;
			
			-- User reg read from PC
			
			reg01_rd: out std_logic_vector(31 downto 0); 
			reg01_rv: out std_logic;
			reg02_rd: out std_logic_vector(31 downto 0); 
			reg02_rv: out std_logic; 
			reg03_rd: out std_logic_vector(31 downto 0); 
			reg03_rv: out std_logic; 
			reg04_rd: out std_logic_vector(31 downto 0); 
			reg04_rv: out std_logic; 
			reg05_rd: out std_logic_vector(31 downto 0); 
			reg05_rv: out std_logic; 
			reg06_rd: out std_logic_vector(31 downto 0); 
			reg06_rv: out std_logic; 
			reg07_rd: out std_logic_vector(31 downto 0); 
			reg07_rv: out std_logic; 
			reg08_rd: out std_logic_vector(31 downto 0); 
			reg08_rv: out std_logic; 
			reg09_rd: out std_logic_vector(31 downto 0); 
			reg09_rv: out std_logic; 
			reg10_rd: out std_logic_vector(31 downto 0); 
			reg10_rv: out std_logic; 
			reg11_rd: out std_logic_vector(31 downto 0); 
			reg11_rv: out std_logic; 
			reg12_rd: out std_logic_vector(31 downto 0); 
			reg12_rv: out std_logic; 
			reg13_rd: out std_logic_vector(31 downto 0); 
			reg13_rv: out std_logic; 
			reg14_rd: out std_logic_vector(31 downto 0); 
			reg14_rv: out std_logic; 
			
			reset	  : in std_logic;
			strobe_adc : out std_logic;
			--;
			-- IRQ
	 		user_int_1o: out std_logic; 
			user_int_2o: out std_logic;
			user_int_3o: out std_logic;
			adcclock: 	 out std_logic;
			fifowr_clk   : OUT  std_logic;
			fifowr_en    : OUT  std_logic;
			fifodin      : OUT  std_logic_VECTOR(72-1 downto 0);
			fifofull     : IN std_logic;
			fifoprog_full:IN std_logic;			
			 real_strobe_signal : out std_logic;
			 real_soa_signal : out std_logic;
			 resetfifo : out std_logic	 
  );
end component;


-- END PART ADC

 component PCIe_UserLogic_00
  port (
    bram_rd_dout: in std_logic_vector(63 downto 0); 
    debug_in_1i: in std_logic_vector(31 downto 0); 
    debug_in_2i: in std_logic_vector(31 downto 0); 
    debug_in_3i: in std_logic_vector(31 downto 0); 
    debug_in_4i: in std_logic_vector(31 downto 0); 
    dma_host2board_busy: in std_logic; 
    dma_host2board_done: in std_logic; 
    fifo_rd_count: in std_logic_vector(14 downto 0); 
    fifo_wr_count: in std_logic_vector(14 downto 0); 
    fifo_rd_dout: in std_logic_vector(71 downto 0); 
    fifo_rd_empty: in std_logic; 
    fifo_rd_pempty: in std_logic; 
    fifo_wr_full: in std_logic; 
    fifo_wr_pfull: in std_logic; 
    fifo_rd_valid: in std_logic; 
    inout_logic_cw_ce: in std_logic := '1'; 
    inout_logic_cw_clk: in std_logic; 
    user_logic_cw_ce: in std_logic := '1'; 
    user_logic_cw_clk: in std_logic; 
    bram_rd_addr: out std_logic_vector(11 downto 0); 
    bram_wr_en: out std_logic_vector(7 downto 0); 
    fifo_rd_en: out std_logic; 
    fifo_wr_din: out std_logic_vector(71 downto 0); 
    fifo_wr_en: out std_logic; 
    rst_o: out std_logic --;
  );
end component;


-- -----------------------------------------------------------------------
--- COMPONENT Declaration: v6_pcie_v1_6 x4 									  ---
--- OSS: Ricordarsi di matchare POWER_SAVE - VENDOR_ID e DEVICE_ID     ---
--- OSS: For POWER_SAVE error correct bit[4] and install ISE12 Patch!! ---
-- -----------------------------------------------------------------------


	
	
   COMPONENT adctofifo
   GENERIC (
             C_ASYNFIFO_WIDTH  :  integer ;
             P_SIMULATION      :  boolean
            );
   PORT (

		--USER Logic Interface
		user_wr_weA              : IN    std_logic_vector(7 downto 0);
		user_wr_addrA            : IN    std_logic_vector(C_PRAM_AWIDTH-1 downto 0);
		user_wr_dinA             : IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);
		user_rd_addrB            : IN    std_logic_vector(C_PRAM_AWIDTH-1 downto 0);
		user_rd_doutB            : OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);
		user_rd_clk              : IN    std_logic;
		user_wr_clk              : IN    std_logic;
		
		-- PART ADC
--		strobe_adc						 : IN		std_logic;
		
		
		-- END PART ADC

      -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
      DDR_wr_sof               : IN    std_logic;
      DDR_wr_eof               : IN    std_logic;
      DDR_wr_v                 : IN    std_logic;
      DDR_wr_FA                : IN    std_logic;
      DDR_wr_Shift             : IN    std_logic;
      DDR_wr_Mask              : IN    std_logic_vector(2-1 downto 0);
      DDR_wr_din               : IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);
      DDR_wr_full              : OUT   std_logic;

      DDR_rdc_sof              : IN    std_logic;
      DDR_rdc_eof              : IN    std_logic;
      DDR_rdc_v                : IN    std_logic;
      DDR_rdc_FA               : IN    std_logic;
      DDR_rdc_Shift            : IN    std_logic;
      DDR_rdc_din              : IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);
      DDR_rdc_full             : OUT   std_logic;

      -- DDR payload FIFO Read Port
      DDR_FIFO_RdEn            : IN    std_logic;
      DDR_FIFO_Empty           : OUT   std_logic;
      DDR_FIFO_RdQout          : OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);

      -- Common interface
      DDR_Ready                : OUT   std_logic;
      DDR_Blinker              : OUT   std_logic;
      mem_clk                  : IN    std_logic;
      trn_clk                  : IN    std_logic;
		Sim_Zeichen              : OUT   std_logic;  
      trn_reset_n              : IN    std_logic;
		strobe_adc				    : IN    std_logic;
		adcclock						:	in 	std_logic ;
			fifowr_clk   : IN std_logic;
			fifowr_en    : IN  std_logic;
			fifodin      : IN  std_logic_VECTOR(72-1 downto 0);
			fifofull     : OUT std_logic;
			fifoprog_full:OUT std_logic
    );
   END COMPONENT;
	
	
	signal	fifowr_clk   :    std_logic;
	signal		fifowr_en    :   std_logic;
	signal		fifodin      :    std_logic_VECTOR(72-1 downto 0);
	signal		fifofull     :   std_logic;
	signal		fifoprog_full:  std_logic;
			
	
	
	signal	  adcclock					:	std_logic;
   signal    DDR_wr_sof               :  std_logic;
   signal    DDR_wr_eof               :  std_logic;
   signal    DDR_wr_v                 :  std_logic;
   signal    DDR_wr_FA                :  std_logic;
   signal    DDR_wr_Shift             :  std_logic;
   signal    DDR_wr_Mask              :  std_logic_vector(2-1 downto 0);
   signal    DDR_wr_din               :  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
   signal    DDR_wr_full              :  std_logic;

   signal    DDR_rdc_sof              :  std_logic;
   signal    DDR_rdc_eof              :  std_logic;
   signal    DDR_rdc_v                :  std_logic;
   signal    DDR_rdc_FA               :  std_logic;
   signal    DDR_rdc_Shift            :  std_logic;
   signal    DDR_rdc_din              :  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
   signal    DDR_rdc_full             :  std_logic;

   signal    DDR_FIFO_RdEn            :  std_logic; 
   signal    DDR_FIFO_Empty           :  std_logic;
   signal    DDR_FIFO_RdQout          :  std_logic_vector(C_DBUS_WIDTH-1 downto 0);

   signal    DDR_Ready                :  std_logic;
   signal    DDR_Blinker              :  std_logic;

	signal	user_wr_weA              : std_logic_vector(7 downto 0) := (Others =>'0');
	signal	user_wr_addrA            : std_logic_vector(C_PRAM_AWIDTH-1 downto 0) := (Others =>'0');
	signal	user_wr_dinA             : std_logic_vector(C_DBUS_WIDTH-1 downto 0)  := (Others =>'0');
	signal	user_rd_addrB            : std_logic_vector(C_PRAM_AWIDTH-1 downto 0) := (Others =>'0');
	signal	user_rd_doutB            : std_logic_vector(C_DBUS_WIDTH-1 downto 0);

-- PART ADC
	signal   strobe_adc						 : std_logic;


	
	signal resetfifo : std_logic;
			 

--END PART ADC


   -- -----------------------------------------------------------------------
   -- FIFO module
   -- -----------------------------------------------------------------------


   component eb_wrapper_loopback
     port (
           wr_clk      : IN  std_logic;
           wr_en       : IN  std_logic;
           din         : IN  std_logic_VECTOR(72-1 downto 0);
           pfull       : OUT std_logic;
           full        : OUT std_logic;

           rd_clk      : IN  std_logic;
           rd_en       : IN  std_logic;
           dout        : OUT std_logic_VECTOR(72-1 downto 0);
           pempty      : OUT std_logic;
           empty       : OUT std_logic;

           data_count  : OUT std_logic_VECTOR(C_EMU_FIFO_DC_WIDTH-1 downto 0);
           rst         : IN  std_logic 
			 
           );
   end component;


   component eb_wrapper
     port (
			 --FIFO PCIe-->USER
			 H2B_wr_clk        : IN  std_logic;
          H2B_wr_en         : IN  std_logic;
          H2B_wr_din        : IN  std_logic_VECTOR(72-1 downto 0);
          H2B_wr_pfull      : OUT std_logic;
          H2B_wr_full       : OUT std_logic;
          H2B_wr_data_count : OUT std_logic_VECTOR(C_EMU_FIFO_DC_WIDTH-1 downto 0); 
          H2B_rd_clk        : IN  std_logic;
          H2B_rd_en         : IN  std_logic;
          H2B_rd_dout       : OUT std_logic_VECTOR(72-1 downto 0);
          H2B_rd_pempty     : OUT std_logic;
          H2B_rd_empty      : OUT std_logic;
          H2B_rd_data_count : OUT std_logic_VECTOR(C_EMU_FIFO_DC_WIDTH-1 downto 0); 
			 H2B_rd_valid      : OUT std_logic;
			 --FIFO USER-->PCIe
          B2H_wr_clk        : IN  std_logic;
          B2H_wr_en         : IN  std_logic;
          B2H_wr_din        : IN  std_logic_VECTOR(64-1 downto 0);
          B2H_wr_pfull      : OUT std_logic;
          B2H_wr_full       : OUT std_logic;
          B2H_wr_data_count : OUT std_logic_VECTOR(C_EMU_FIFO_DC_WIDTH-1 downto 0); 
          B2H_rd_clk        : IN  std_logic;
          B2H_rd_en         : IN  std_logic;
          B2H_rd_dout       : OUT std_logic_VECTOR(72-1 downto 0);
          B2H_rd_pempty     : OUT std_logic;
          B2H_rd_empty      : OUT std_logic;
          B2H_rd_data_count : OUT std_logic_VECTOR(C_EMU_FIFO_DC_WIDTH-1 downto 0);
			 B2H_rd_valid		 : OUT std_logic;	
          --RESET from PCIe
			 rst               : IN  std_logic;
			  resetfifo	: in std_logic
          );
   end component;


   signal  eb_wclk            :  std_logic;
   signal  eb_we              :  std_logic;
   signal  eb_wsof            :  std_logic;
   signal  eb_weof            :  std_logic;
   signal  eb_din             :  std_logic_VECTOR(72-1 downto 0);
   signal  eb_pfull           :  std_logic;
   signal  eb_full            :  std_logic;
   signal  eb_rclk            :  std_logic;
   signal  eb_re              :  std_logic;
	signal  my_eb_re				:  std_logic;
   signal  eb_dout            :  std_logic_VECTOR(72-1 downto 0);
   signal  eb_pempty          :  std_logic;
   signal  eb_empty           :  std_logic;
   signal  eb_valid           :  std_logic;
   signal  eb_rst             :  std_logic;

   signal  eb_data_count      :  std_logic_vector(C_FIFO_DC_WIDTH downto 0);
   signal  H2B_wr_data_count  :  std_logic_vector(C_FIFO_DC_WIDTH downto 0);
   signal  B2H_rd_data_count  :  std_logic_vector(C_FIFO_DC_WIDTH downto 0);


   signal  pio_read_status    :  std_logic;
   signal  eb_FIFO_ow         :  std_logic;

   signal  eb_FIFO_Status     :  std_logic_VECTOR(C_DBUS_WIDTH-1 downto 0);
   signal  H2B_FIFO_Status    :  std_logic_VECTOR(C_DBUS_WIDTH-1 downto 0);
   signal  B2H_FIFO_Status    :  std_logic_VECTOR(C_DBUS_WIDTH-1 downto 0);

   signal  eb_we_up           :  std_logic;
   signal  eb_din_up          :  std_logic_VECTOR(72-1 downto 0);

   signal  tab_sel            : STD_LOGIC;
	
	signal   user_rd_en         : std_logic := '0';
	signal   user_rd_dout       : std_logic_VECTOR(72-1 downto 0);
	signal   user_rd_pempty     : std_logic;
	signal   user_rd_empty      : std_logic;
	signal   user_rd_data_count : std_logic_VECTOR(C_EMU_FIFO_DC_WIDTH-1 downto 0);
	signal   user_wr_data_count : std_logic_VECTOR(C_EMU_FIFO_DC_WIDTH-1 downto 0);
	signal   user_wr_en         : std_logic := '0';
	signal   user_wr_din        : std_logic_VECTOR(72-1 downto 0) := (Others =>'0');
	signal   user_wr_pfull      : std_logic;
	signal   user_wr_full       : std_logic;
	signal   user_rd_valid      : std_logic;



------------- COMPONENT Declaration: tlpControl   ------
-- 
 component tlpControl 
   port (
        --  Test pin, emulating DDR data flow discontinuity
        mbuf_UserFull                : IN  std_logic;
        trn_Blinker                  : OUT std_logic;



--S	SIMONE: Wanxau UserLogic Signals, not Used
        -- DCB protocol interface
        protocol_link_act            : IN  std_logic_vector(2-1 downto 0);
        protocol_rst                 : OUT std_logic;
        -- Fabric side: CTL Rx
        ctl_rv                       : OUT std_logic;
        ctl_rd                       : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        -- Fabric side: CTL Tx
        ctl_ttake                    : OUT std_logic;
        ctl_tv                       : IN  std_logic;
        ctl_td                       : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        ctl_tstop                    : OUT std_logic;
        ctl_reset                    : OUT std_logic;
        ctl_status                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        -- Fabric side: DLM Rx
        dlm_rv                       : OUT std_logic;
        dlm_rd                       : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        -- Fabric side: DLM Tx
        dlm_tv                       : IN  std_logic;
        dlm_td                       : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        Link_Buf_full                : IN  std_logic;
        -- Data generator table write
        tab_we                       : OUT std_logic_vector(2-1 downto 0);
        tab_wa                       : OUT std_logic_vector(12-1 downto 0);
        tab_wd                       : OUT std_logic_vector(C_DBUS_WIDTH-1 downto 0);
        -- Data generator control
        DG_is_Running                : IN  std_logic;
        DG_Reset                     : OUT std_logic;
        DG_Mask                      : OUT std_logic;
--S	SIMONE: Wanxau UserLogic Signals, not Used


        -- Interrupter triggers
        DAQ_irq                      : IN  std_logic;
        CTL_irq                      : IN  std_logic;
        DLM_irq                      : IN  std_logic;


        -- SIMONE Register: PC-->FPGA
        reg01_tv                   : OUT std_logic;
        reg01_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg02_tv                   : OUT std_logic;
        reg02_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg03_tv                   : OUT std_logic;
        reg03_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg04_tv                   : OUT std_logic;
        reg04_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg05_tv                   : OUT std_logic;
        reg05_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg06_tv                   : OUT std_logic;
        reg06_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg07_tv                   : OUT std_logic;
        reg07_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg08_tv                   : OUT std_logic;
        reg08_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg09_tv                   : OUT std_logic;
        reg09_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg10_tv                   : OUT std_logic;
        reg10_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg11_tv                   : OUT std_logic;
        reg11_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg12_tv                   : OUT std_logic;
        reg12_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg13_tv                   : OUT std_logic;
        reg13_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg14_tv                   : OUT std_logic;
        reg14_td                   : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

        -- SIMONE Register: FPGA-->PC
        reg01_rv                   : IN  std_logic;
        reg01_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg02_rv                   : IN  std_logic;
        reg02_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg03_rv                   : IN  std_logic;
        reg03_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg04_rv                   : IN  std_logic;
        reg04_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg05_rv                   : IN  std_logic;
        reg05_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg06_rv                   : IN  std_logic;
        reg06_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg07_rv                   : IN  std_logic;
        reg07_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg08_rv                   : IN  std_logic;
        reg08_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg09_rv                   : IN  std_logic;
        reg09_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg10_rv                   : IN  std_logic;
        reg10_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg11_rv                   : IN  std_logic;
        reg11_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg12_rv                   : IN  std_logic;
        reg12_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg13_rv                   : IN  std_logic;
        reg13_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        reg14_rv                   : IN  std_logic;
        reg14_rd                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

		  --SIMONE debug signals
		 debug_in_1i					  : OUT std_logic_vector(31 downto 0); 
		 debug_in_2i					  : OUT std_logic_vector(31 downto 0); 
		 debug_in_3i					  : OUT std_logic_vector(31 downto 0); 		  
		 debug_in_4i					  : OUT std_logic_vector(31 downto 0); 		  
			

        -- Event Buffer FIFO interface
        eb_FIFO_we                   : OUT std_logic; 
        eb_FIFO_wsof                 : OUT std_logic; 
        eb_FIFO_weof                 : OUT std_logic; 
        eb_FIFO_din                  : OUT std_logic_vector(C_DBUS_WIDTH-1 downto 0);

        eb_FIFO_re                   : OUT std_logic; 
        eb_FIFO_empty                : IN  std_logic; 
        eb_FIFO_qout                 : IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
        eb_FIFO_data_count           : IN  std_logic_vector(C_FIFO_DC_WIDTH downto 0);

        eb_FIFO_ow                   : IN  std_logic;

        pio_reading_status           : OUT std_logic; 
        eb_FIFO_Status               : IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
        eb_FIFO_Rst                  : OUT std_logic;

		  H2B_FIFO_Status    			 : IN std_logic_VECTOR(C_DBUS_WIDTH-1 downto 0);
		  B2H_FIFO_Status    			 : IN std_logic_VECTOR(C_DBUS_WIDTH-1 downto 0);

        -- Debugging signals
        DMA_us_Done                  : OUT std_logic;
        DMA_us_Busy                  : OUT std_logic;
        DMA_us_Busy_LED              : OUT std_logic;
        DMA_ds_Done                  : OUT std_logic;
        DMA_ds_Busy                  : OUT std_logic;
        DMA_ds_Busy_LED              : OUT std_logic;

        -- DDR control interface
        DDR_Ready                    : IN    std_logic;

        DDR_wr_sof                   : OUT   std_logic;
        DDR_wr_eof                   : OUT   std_logic;
        DDR_wr_v                     : OUT   std_logic;
        DDR_wr_FA                    : OUT   std_logic;
        DDR_wr_Shift                 : OUT   std_logic;
        DDR_wr_Mask                  : OUT   std_logic_vector(2-1 downto 0);
        DDR_wr_din                   : OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);
        DDR_wr_full                  : IN    std_logic;

        DDR_rdc_sof                  : OUT   std_logic;
        DDR_rdc_eof                  : OUT   std_logic;
        DDR_rdc_v                    : OUT   std_logic;
        DDR_rdc_FA                   : OUT   std_logic;
        DDR_rdc_Shift                : OUT   std_logic;
        DDR_rdc_din                  : OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);
        DDR_rdc_full                 : IN    std_logic;

        -- DDR payload FIFO Read Port
        DDR_FIFO_RdEn                : OUT std_logic; 
        DDR_FIFO_Empty               : IN  std_logic;
        DDR_FIFO_RdQout              : IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);

        -- Transaction layer interface
        trn_lnk_up_n                 : IN  std_logic;
        trn_rsrc_dsc_n               : IN  std_logic;
        trn_rnp_ok_n                 : OUT std_logic;
        trn_tsrc_dsc_n               : OUT std_logic;
        trn_tdst_dsc_n               : IN  std_logic;
        trn_tbuf_av                  : IN  std_logic_vector(C_TBUF_AWIDTH-1 downto 0);
        trn_terrfwd_n                : OUT std_logic;

        trn_clk                      : IN  std_logic;
        trn_reset_n                  : IN  std_logic;
        trn_rsrc_rdy_n               : IN  std_logic;
        trn_tdst_rdy_n               : IN  std_logic;
        trn_rsof_n                   : IN  std_logic;
        trn_reof_n                   : IN  std_logic;
        trn_rerrfwd_n                : IN  std_logic;
        trn_rrem_n                   : IN  std_logic_vector(C_DBUS_WIDTH/8-1 downto 0);
        trn_rd                       : IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);

        cfg_dcommand                 : IN  std_logic_vector(15 downto 0);
        pcie_link_width              : IN  std_logic_vector( 5 downto 0);
        localId                      : IN  std_logic_vector(15 downto 0);

        cfg_interrupt_n              : OUT std_logic;
        cfg_interrupt_rdy_n          : IN  std_logic;
        cfg_interrupt_mmenable       : IN  std_logic_vector(2 downto 0);
        cfg_interrupt_msienable      : IN  std_logic;
        cfg_interrupt_di             : OUT std_logic_vector(7 downto 0);
        cfg_interrupt_do             : IN  std_logic_vector(7 downto 0);
        cfg_interrupt_assert_n       : OUT std_logic;

        Format_Shower                : OUT   std_logic;

        trn_rbar_hit_n               : IN  std_logic_vector(6 downto 0);
        trn_tsrc_rdy_n               : OUT std_logic;
        trn_rdst_rdy_n               : OUT std_logic;
        trn_tsof_n                   : OUT std_logic;
        trn_teof_n                   : OUT std_logic;
        trn_trem_n                   : OUT std_logic_vector(C_DBUS_WIDTH/8-1 downto 0);
        trn_td                       : OUT std_logic_vector(C_DBUS_WIDTH-1 downto 0)
        );
 end component;

 signal   Format_Shower              : std_logic;




  -- TRN Layer signals

  signal trn_terr_drop_n                 : std_logic;
  signal trn_tcfg_gnt_n                  : std_logic;
  signal trn_tstr_n                      : std_logic;
  signal trn_fc_cpld                     : STD_LOGIC_vector (12-1 downto 0); 
  signal trn_fc_cplh                     : STD_LOGIC_vector (8-1 downto 0); 
  signal trn_fc_npd                      : STD_LOGIC_vector (12-1 downto 0); 
  signal trn_fc_nph                      : STD_LOGIC_vector (8-1 downto 0); 
  signal trn_fc_pd                       : STD_LOGIC_vector (12-1 downto 0); 
  signal trn_fc_ph                       : STD_LOGIC_vector (8-1 downto 0); 
  signal trn_fc_sel                      : STD_LOGIC_vector (3-1 downto 0); 
                                    
  signal cfg_interrupt_msixenable        : std_logic;
  signal cfg_interrupt_msixfm            : std_logic;
  signal cfg_dcommand2                   : std_logic_vector (16-1 downto 0);
  signal trn_tcfg_req_n                  : std_logic;
 
  signal  pl_initial_link_width          : STD_LOGIC_vector (3-1 downto 0);
  signal  pl_lane_reversal_mode          : STD_LOGIC_vector (2-1 downto 0);
  signal  pl_link_gen2_capable           : STD_LOGIC;
  signal  pl_link_partner_gen2_supported : STD_LOGIC;
  signal  pl_link_upcfg_capable          : STD_LOGIC;
  signal  pl_ltssm_state                 : STD_LOGIC_vector (6-1 downto 0);
  signal  pl_received_hot_rst            : STD_LOGIC;
  signal  pl_sel_link_rate               : STD_LOGIC;
  signal  pl_sel_link_width              : STD_LOGIC_vector (2-1 downto 0);
  signal  pl_directed_link_auton         : STD_LOGIC;
  signal  pl_directed_link_change        : STD_LOGIC_vector (2-1 downto 0);
  signal  pl_directed_link_speed         : STD_LOGIC;
  signal  pl_directed_link_width         : STD_LOGIC_vector (2-1 downto 0);
  signal  pl_upstream_prefer_deemph      : STD_LOGIC;

  signal  trn_reset_n_int1       : STD_LOGIC;
  signal  trn_lnk_up_n_int1      : STD_LOGIC;

  signal trn_clk                     : std_logic;
  signal trn_reset_n                 : std_logic;
    signal my_reset_n						 : std_logic;
  signal trn_lnk_up_n                : std_logic;
    signal my_lnk_up_n                : std_logic;
  signal trn_td                      : std_logic_vector(63 downto 0);
  signal trn_trem_n                  : std_logic_vector(7 downto 0);
  signal trn_tsof_n                  : std_logic;
  signal trn_teof_n                  : std_logic;
  signal trn_tsrc_rdy_n              : std_logic;
  signal trn_tdst_rdy_n              : std_logic;
  signal trn_tdst_dsc_n              : std_logic;
  signal trn_tsrc_dsc_n              : std_logic;
  signal trn_terrfwd_n               : std_logic;
  signal trn_tbuf_av                 : std_logic_vector(5 downto 0);
  signal trn_rd                      : std_logic_vector(63 downto 0);
  signal trn_rrem_n                  : std_logic_vector(7 downto 0);
  signal trn_rsof_n                  : std_logic;
  signal trn_reof_n                  : std_logic;
  signal trn_rsrc_rdy_n              : std_logic;
  signal trn_rsrc_dsc_n              : std_logic;
  signal trn_rdst_rdy_n              : std_logic;
  signal trn_rerrfwd_n               : std_logic;
  signal trn_rnp_ok_n                : std_logic;
--  signal trn_rbar_hit_n              : std_logic_vector(7 downto 0); -- изменил на 6 7
  signal trn_rbar_hit_n              : std_logic_vector(6 downto 0);
  signal trn_rfc_nph_av              : std_logic_vector(7 downto 0);
  signal trn_rfc_npd_av              : std_logic_vector(11 downto 0);
  signal trn_rfc_ph_av               : std_logic_vector(7 downto 0);
  signal trn_rfc_pd_av               : std_logic_vector(11 downto 0);
  signal trn_rfc_cplh_av             : std_logic_vector(7 downto 0);
  signal trn_rfc_cpld_av             : std_logic_vector(11 downto 0);
  signal trn_rcpl_streaming_n        : std_logic;
  signal cfg_do                      : std_logic_vector(31 downto 0);
  signal cfg_rd_wr_done_n            : std_logic;
  signal cfg_di                      : std_logic_vector(31 downto 0);
  signal cfg_byte_en_n               : std_logic_vector(3 downto 0);
  signal cfg_dwaddr                  : std_logic_vector(9 downto 0);
  signal cfg_wr_en_n                 : std_logic;
  signal cfg_rd_en_n                 : std_logic;
  signal cfg_err_cor_n               : std_logic;
  signal cfg_err_ur_n                : std_logic;
  signal cfg_err_cpl_rdy_n           : std_logic;
  signal cfg_err_ecrc_n              : std_logic;
  signal cfg_err_cpl_timeout_n       : std_logic;
  signal cfg_err_cpl_abort_n         : std_logic;
  signal cfg_err_cpl_unexpect_n      : std_logic;
  signal cfg_err_posted_n            : std_logic;
  signal cfg_err_locked_n            : std_logic;
  signal cfg_err_tlp_cpl_header      : std_logic_vector(47 downto 0);
  signal cfg_interrupt_n             : std_logic;
  signal cfg_interrupt_rdy_n         : std_logic;
  signal cfg_interrupt_mmenable      : std_logic_vector(2 downto 0);
  signal cfg_interrupt_msienable     : std_logic;
  signal cfg_interrupt_di            : std_logic_vector(7 downto 0);
  signal cfg_interrupt_do            : std_logic_vector(7 downto 0);
  signal cfg_interrupt_assert_n      : std_logic;
  signal cfg_turnoff_ok_n            : std_logic;
  signal cfg_to_turnoff_n            : std_logic;
  signal cfg_pm_wake_n               : std_logic;
  signal cfg_pcie_link_state_n       : std_logic_vector(2 downto 0);
  signal cfg_trn_pending_n           : std_logic;
  signal cfg_bus_number              : std_logic_vector(7 downto 0);
  signal cfg_device_number           : std_logic_vector(4 downto 0);
  signal cfg_function_number         : std_logic_vector(2 downto 0);
  signal cfg_dsn                     : std_logic_vector(63 downto 0);
  signal cfg_status                  : std_logic_vector(15 downto 0);
  signal cfg_command                 : std_logic_vector(15 downto 0);
  signal cfg_dstatus                 : std_logic_vector(15 downto 0);
  signal cfg_dcommand                : std_logic_vector(15 downto 0);
  signal cfg_lstatus                 : std_logic_vector(15 downto 0);
  signal cfg_lcommand                : std_logic_vector(15 downto 0);
  signal fast_train_simulation_only  : std_logic;
  signal two_plm_auto_config         : std_logic_vector(1 downto 0);
  signal sys_clk_c                   : std_logic;
  signal sys_reset_n_c               : std_logic;
  signal reset_n                     : std_logic;

  signal localId                     : std_logic_vector(15 downto 0);
  signal pcie_link_width             : std_logic_vector( 5 downto 0);

  signal synclk2out                  : std_logic;

  signal Sim_Zeichen                 : std_logic;
  --
  signal   trn_Blinker               : std_logic;



	signal   DAQ_irq            : std_logic := '0';
	signal   CTL_irq            : std_logic := '0';
	signal   DLM_irq            : std_logic := '0';



--S	SIMONE: Wanxau UserLogic Signals, not Used
	signal   protocol_link_act  : std_logic_vector(2-1 downto 0) := (OTHERS=>'0');
	signal   protocol_rst       : std_logic;
	signal   daq_rstop          : std_logic;
	signal   ctl_rv             : std_logic;
	signal   ctl_rd             : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
	signal   ctl_ttake          : std_logic;
	signal   ctl_tv             : std_logic := '0';
	signal   ctl_td             : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
	signal   ctl_tstop          : std_logic;
	signal   ctl_reset          : std_logic;
	signal   ctl_status         : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
	signal   dlm_tv             : std_logic;
	signal   dlm_td             : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
	signal   dlm_rv             : std_logic := '0';
	signal   dlm_rd             : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal   tab_we             : std_logic_vector(2-1 downto 0);
   signal   tab_wa             : std_logic_vector(12-1 downto 0);
   signal   tab_wd             : std_logic_vector(C_DBUS_WIDTH-1 downto 0);
   signal   dg_running         : std_logic := '0';
   signal   dg_rst             : STD_LOGIC;
   signal   DG_Mask            : STD_LOGIC;
--S	SIMONE: Wanxau UserLogic Signals, not Used



        -- SIMONE Register: PC-->FPGA
   signal  reg01_tv            : std_logic;
   signal  reg01_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg02_tv            : std_logic;
   signal  reg02_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg03_tv            : std_logic;
   signal  reg03_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg04_tv            : std_logic;
   signal  reg04_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg05_tv            : std_logic;
   signal  reg05_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg06_tv            : std_logic;
   signal  reg06_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg07_tv            : std_logic;
   signal  reg07_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg08_tv            : std_logic;
   signal  reg08_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg09_tv            : std_logic;
   signal  reg09_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg10_tv            : std_logic;
   signal  reg10_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg11_tv            : std_logic;
   signal  reg11_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg12_tv            : std_logic;
   signal  reg12_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg13_tv            : std_logic;
   signal  reg13_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  reg14_tv            : std_logic;
   signal  reg14_td            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

        -- SIMONE Register: FPGA-->PC
   signal  reg01_rv            : std_logic := '0';
   signal  reg01_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg02_rv            : std_logic := '0';
   signal  reg02_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg03_rv            : std_logic := '0';
   signal  reg03_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg04_rv            : std_logic := '0';
   signal  reg04_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg05_rv            : std_logic := '0';
   signal  reg05_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg06_rv            : std_logic := '0';
   signal  reg06_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg07_rv            : std_logic := '0';
   signal  reg07_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg08_rv            : std_logic := '0';
   signal  reg08_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg09_rv            : std_logic := '0';
   signal  reg09_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg10_rv            : std_logic := '0';
   signal  reg10_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg11_rv            : std_logic := '0';
   signal  reg11_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg12_rv            : std_logic := '0';
   signal  reg12_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg13_rv            : std_logic := '0';
   signal  reg13_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');
   signal  reg14_rv            : std_logic := '0';
   signal  reg14_rd            : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0) := (OTHERS=>'0');

   signal  debug_in_1i			 : std_logic_vector(31 downto 0); 
   signal  debug_in_2i			 : std_logic_vector(31 downto 0); 
   signal  debug_in_3i			 : std_logic_vector(31 downto 0); 
   signal  debug_in_4i			 : std_logic_vector(31 downto 0); 

	signal  user_rst_o          : std_logic;

	signal  clk_200MHz          : std_logic;

	signal  DMA_Host2Board_Busy : std_logic;
	signal  DMA_Host2Board_Done : std_logic;

	signal  DMA_us_Busy         : std_logic;
	signal  DMA_us_Done         : std_logic;
	signal  DMA_ds_Done         : std_logic; 
	signal  DMA_ds_Busy         : std_logic; 
	

--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
 -- Common
  signal user_lnk_up            : std_logic;
  signal user_lnk_up_q          : std_logic;
  signal user_clk               : std_logic;
  signal user_reset             : std_logic;
  signal user_reset_i           : std_logic;
  signal user_reset_q           : std_logic;

  -- Tx
  signal tx_buf_av              : std_logic_vector(5 downto 0);
  signal tx_cfg_req             : std_logic;
  signal tx_err_drop            : std_logic;
  signal tx_cfg_gnt             : std_logic;
  signal s_axis_tx_tready       : std_logic;
  signal s_axis_tx_tuser        : std_logic_vector (3 downto 0);
  signal s_axis_tx_tdata        : std_logic_vector((C_DATA_WIDTH - 1) downto 0);
  signal s_axis_tx_tkeep        : std_logic_vector((C_DATA_WIDTH/8 - 1) downto 0);
  signal s_axis_tx_tlast        : std_logic;
  signal s_axis_tx_tvalid       : std_logic;

  -- Rx
  signal m_axis_rx_tdata        : std_logic_vector((C_DATA_WIDTH - 1) downto 0);
  signal m_axis_rx_tkeep        : std_logic_vector((C_DATA_WIDTH/8- 1) downto 0);
  signal m_axis_rx_tlast        : std_logic;
  signal m_axis_rx_tvalid       : std_logic;
  signal m_axis_rx_tready       : std_logic;
  signal m_axis_rx_tuser        : std_logic_vector (21 downto 0);
  signal rx_np_ok               : std_logic;
  signal rx_np_req              : std_logic;

  -- Flow Control
  signal fc_cpld                : std_logic_vector(11 downto 0);
  signal fc_cplh                : std_logic_vector(7 downto 0);
  signal fc_npd                 : std_logic_vector(11 downto 0);
  signal fc_nph                 : std_logic_vector(7 downto 0);
  signal fc_pd                  : std_logic_vector(11 downto 0);
  signal fc_ph                  : std_logic_vector(7 downto 0);
  signal fc_sel                 : std_logic_vector(2 downto 0);

  ---------------------------------------------------------
  -- 3. Configuration (CFG) Interface
  ---------------------------------------------------------
  signal cfg_err_cor                   : std_logic;
  signal cfg_err_ur                    : std_logic;
  signal cfg_err_ecrc                  : std_logic;
  signal cfg_err_cpl_timeout           : std_logic;
  signal cfg_err_cpl_abort             : std_logic;
  signal cfg_err_cpl_unexpect          : std_logic;
  signal cfg_err_posted                : std_logic;
  signal cfg_err_locked                : std_logic;
  signal cfg_err_cpl_rdy               : std_logic;
  signal cfg_err_atomic_egress_blocked : std_logic;
  signal cfg_err_internal_cor          : std_logic;
  signal cfg_err_malformed             : std_logic;
  signal cfg_err_mc_blocked            : std_logic;
  signal cfg_err_poisoned              : std_logic;
  signal cfg_err_norecovery            : std_logic;
  signal cfg_err_acs                   : std_logic;
  signal cfg_err_internal_uncor        : std_logic;
  signal cfg_interrupt                 : std_logic;
  signal cfg_interrupt_rdy             : std_logic;
  signal cfg_interrupt_assert          : std_logic;
  signal cfg_interrupt_stat            : std_logic;
  signal cfg_pciecap_interrupt_msgnum  : std_logic_vector(4 downto 0);
  signal cfg_turnoff_ok                : std_logic;
  signal cfg_to_turnoff                : std_logic;
  signal cfg_trn_pending               : std_logic;
  signal cfg_pm_halt_aspm_l0s          : std_logic;
  signal cfg_pm_halt_aspm_l1           : std_logic;
  signal cfg_pm_force_state_en         : std_logic;
  signal cfg_pm_force_state            : std_logic_vector(1 downto 0);
  signal cfg_pm_wake                   : std_logic;
  signal cfg_pcie_link_state           : std_logic_vector(2 downto 0);
  signal cfg_err_aer_headerlog         : std_logic_vector(127 downto 0);
  signal cfg_aer_interrupt_msgnum      : std_logic_vector(4 downto 0);
  signal cfg_err_aer_headerlog_set     : std_logic;
  signal cfg_aer_ecrc_check_en         : std_logic;
  signal cfg_aer_ecrc_gen_en           : std_logic;

  signal cfg_mgmt_di                   : std_logic_vector(31 downto 0);
  signal cfg_mgmt_byte_en              : std_logic_vector(3 downto 0);
  signal cfg_mgmt_dwaddr               : std_logic_vector(9 downto 0);
  signal cfg_mgmt_wr_en                : std_logic;
  signal cfg_mgmt_rd_en                : std_logic;
  signal cfg_mgmt_wr_readonly          : std_logic;

  ---------------------------------------------------------
  -- 4. Physical Layer Control and Status (PL) Interface
  ---------------------------------------------------------
  signal pl_link_gen2_cap               : std_logic;
  signal pl_link_upcfg_cap              : std_logic;
  signal pl_sel_lnk_rate                : std_logic;
  signal pl_sel_lnk_width               : std_logic_vector(1 downto 0);
  signal sys_clk                        : std_logic;
  --signal sys_rst_n_c                    : std_logic; --Вместо sys_reset_n_c 
  -- signal sys_reset_c                    : std_logic;
  signal sys_rst                        : std_logic;
  -- Wires used for external clocking connectivity
  signal PIPE_PCLK_IN                   : std_logic;
  signal PIPE_RXUSRCLK_IN               : std_logic;
  signal PIPE_RXOUTCLK_IN               : std_logic_vector(3 downto 0);
  signal PIPE_DCLK_IN                   : std_logic;
  signal PIPE_USERCLK1_IN               : std_logic;
  signal PIPE_USERCLK2_IN               : std_logic;
  signal PIPE_OOBCLK_IN                 : std_logic;
  signal PIPE_MMCM_LOCK_IN              : std_logic;

  signal PIPE_TXOUTCLK_OUT              : std_logic;
  signal PIPE_RXOUTCLK_OUT              : std_logic_vector(3 downto 0);
  signal PIPE_PCLK_SEL_OUT              : std_logic_vector(3 downto 0);
  signal PIPE_GEN3_OUT                  : std_logic;
  signal PIPE_MMCM_RST_N                : std_logic := '1';
  signal  trn_tdst_rdy                       : std_logic;
  signal  trn_tdst_dsc                       : std_logic;
  signal  trn_rrem                           : std_logic_vector(0 downto 0);
  signal  trn_rsof                           : std_logic;
  signal  trn_reof                           : std_logic;
  signal  trn_rsrc_rdy                       : std_logic;
  signal  trn_rsrc_dsc                       : std_logic;
  signal  trn_rerrfwd                        : std_logic;
 -- signal  trn_rbar_hit                       : std_logic_vector(7 downto 0);
 signal trn_rbar_hit              : std_logic_vector(6 downto 0);
  signal  cfg_rd_wr_done                     : std_logic;
  signal  cfg_rdy_n                          : std_logic;
  signal  speed_change_done_n                : std_logic;
  signal  trn_tstr                           : std_logic;
  signal  trn_tecrc_gen                      : std_logic;
  signal  trn_trem                           : std_logic_vector(0 downto 0);
  signal  trn_tsof                           : std_logic;
  signal  trn_teof                           : std_logic;
  signal  trn_tsrc_rdy                       : std_logic;
  signal  trn_tsrc_dsc                       : std_logic;
  signal  trn_terrfwd                        : std_logic;
  signal  trn_rnp_ok                         : std_logic;
  signal  trn_rdst_rdy                       : std_logic;
  signal  rx_tx_read_data                    : std_logic_vector(31 downto 0);
  signal  rx_tx_read_data_valid              : std_logic;
  signal  tx_rx_read_data_valid              : std_logic;
  signal  trn_trem_n_out                     : std_logic_vector( 7 downto 0);
  signal  trn_rrem_n_in                      : std_logic_vector(7 downto 0);
  signal trn_rrem_n_my : std_logic_vector (0 downto 0);
       signal fifo_reset_done              : std_logic;
         signal pio_reading_status           : std_logic;
signal s_axis_tx_tready_i     : std_logic;
  signal sys_reset_c                         : std_logic;
  constant TCQ                  : time           := 1 ps;
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------



begin
-- PART ADC

   ad9467_1: ADC_emul
	  port map (
		   debug_data(15 downto 0)   => cfg_dstatus(15 downto 0), -- 51
			debug_data1(63 downto 0)  => eb_dout(63 downto 0), --52
			debug_data2 => eb_re, --53
			debug_data3 => eb_rst, --54
	--		fifo_re => my_eb_re,
	      trn_clk		=> trn_clk,
			adc_clk_in_p => adc_clk_in_p,          
			adc_clk_in_n => adc_clk_in_n,          
			adc_data_in_p => adc_data_in_p,        
			adc_data_in_n => adc_data_in_n,         
			adc_data_or_p => adc_data_or_p,         
			adc_data_or_n => adc_data_or_n,        
			delay_clk => delay_clk,            
		
			bram_wr_din =>  user_wr_dinA,
		   bram_wr_addr =>  user_wr_addrA,
			reg01_td 		=> reg01_td,					        
         reg01_tv 		=> reg01_tv,
			reg02_td 		=> reg02_td,					        
         reg02_tv 		=> reg02_tv,
			reg03_td 		=> reg03_td,					        
         reg03_tv 		=> reg03_tv,			
			reg04_td 		=> reg04_td,					        
         reg04_tv 		=> reg04_tv,			
			reg05_td 		=> reg05_td,					        
         reg05_tv 		=> reg05_tv,			
			reg06_td 		=> reg06_td,                      
         reg06_tv 		=> reg06_tv ,
			reg07_td 		=> reg07_td,					        
         reg07_tv 		=> reg07_tv,			
			reg08_td 		=> reg08_td,					        
         reg08_tv 		=> reg08_tv,
         reg09_tv 		=> reg09_tv,			
			reg09_td 		=> reg09_td,                      
         reg10_tv 		=> reg10_tv ,
			reg10_td 		=> reg10_td,					        
         reg11_tv 		=> reg11_tv,			
			reg11_td 		=> reg11_td,					        
         reg12_tv 		=> reg12_tv,
         reg12_td 		=> reg12_td,
         reg13_tv 		=> reg13_tv,
         reg13_td 		=> reg13_td,
         reg14_tv 		=> reg14_tv,
         reg14_td 		=> reg14_td,

			reg01_rd 		=> reg01_rd,					        
         reg01_rv 		=> reg01_rv,
			reg02_rd 		=> reg02_rd,					        
         reg02_rv 		=> reg02_rv,
			reg03_rd 		=> reg03_rd,					        
         reg03_rv 		=> reg03_rv,			
			reg04_rd 		=> reg04_rd,					        
         reg04_rv 		=> reg04_rv,			
			reg05_rd 		=> reg05_rd,					        
         reg05_rv 		=> reg05_rv,			
			reg06_rd 		=> reg06_rd,                      
         reg06_rv 		=> reg06_rv ,
			reg07_rd 		=> reg07_rd,					        
         reg07_rv 		=> reg07_rv,			
			reg08_rd 		=> reg08_rd,					        
         reg08_rv 		=> reg08_rv,
         reg09_rv 		=> reg09_rv,			
			reg09_rd 		=> reg09_rd,                      
         reg10_rv 		=> reg10_rv ,
			reg10_rd 		=> reg10_rd,					        
         reg11_rv 		=> reg11_rv,			
			reg11_rd 		=> reg11_rd,					        
         reg12_rv 		=> reg12_rv,
         reg12_rd 		=> reg12_rd,
         reg13_rv 		=> reg13_rv,
         reg13_rd 		=> reg13_rd,
         reg14_rv 		=> reg14_rv,
         reg14_rd 		=> reg14_rd,			
			
			
			reset => sys_reset_n_c,
			strobe_adc => strobe_adc,--,
			--bram_wr_en 		=> user_wr_weA,
			user_int_1o    => CTL_irq,
			user_int_2o    => DAQ_irq,
			user_int_3o    => DLM_irq,
			adcclock			=> adcclock,
			
			fifowr_clk =>fifowr_clk   ,
			fifowr_en     =>fifowr_en,
			fifodin       =>fifodin,
			fifofull      => fifofull,
			fifoprog_full => fifoprog_full,
			
			 real_strobe_signal => real_strobe_signal,
			 real_soa_signal => real_soa_signal,
			resetfifo => resetfifo
			);


	DMA_Host2Board_Busy <= '0'; --DMA_ds_Busy;
	DMA_Host2Board_Done <= DMA_ds_Done;

  process (trn_clk)
  begin
   if (user_reset = '1') then
       s_axis_tx_tready_i <= '0' after TCQ;
   elsif (trn_clk'event and trn_clk = '1') then
       s_axis_tx_tready_i <= s_axis_tx_tready after TCQ;
   end if;
  end process;

  process(trn_clk)
  begin
    if (trn_clk'event and trn_clk='1') then
     if (user_reset = '1') then
       user_reset_q  <= '1' after TCQ;
       user_lnk_up_q <= '0' after TCQ;
     else
       user_reset_q  <= user_reset after TCQ;
       user_lnk_up_q <= user_lnk_up after TCQ;
     end if;
    end if;
  end process;

  refclk_ibuf : IBUFDS_GTE2
     port map(
       O       => sys_clk_c,
       ODIV2   => open,
       I       => sys_clk_p,
       IB      => sys_clk_n,
       CEB     => '0');

  sys_reset_n_ibuf : IBUF
     port map(
       O       => sys_reset_n_c,
       I       => sys_reset_n);
		 

  userclk_ibuf : IBUFDS 
      port map (
                 O  => clk_200MHz,
                 I  => userclk_200MHz_p,
                 IB => userclk_200MHz_n
                );

    PIPE_PCLK_IN        <= '0';
    PIPE_RXUSRCLK_IN    <= '0';
    PIPE_RXOUTCLK_IN    <= (others => '0');
    PIPE_DCLK_IN        <= '0';
    PIPE_USERCLK1_IN    <= '0';
    PIPE_USERCLK2_IN    <= '0';
    PIPE_OOBCLK_IN      <= '0';
    PIPE_MMCM_LOCK_IN   <= '0';
	 
  trn_reset_n_int1 <= not user_reset;
  trn_lnk_up_n_int1 <= not user_lnk_up;
  
  trn_trem(0)					<= not trn_trem_n(0);
  trn_rrem_n(0)					<= not trn_rrem(0);
  
  trn_tsof              <= not trn_tsof_n;
  trn_teof              <= not trn_teof_n;
  trn_rsof_n            <= not trn_rsof;
  trn_reof_n            <= not trn_reof;
  
  trn_tsrc_rdy          <= not trn_tsrc_rdy_n; -- in <= out
  trn_rsrc_rdy_n        <= not trn_rsrc_rdy;


  trn_tsrc_dsc          <= not trn_tsrc_dsc_n; -- in bridge <= out tlp
  trn_rsrc_dsc_n        <= not trn_rsrc_dsc;


  trn_terrfwd           <= not trn_terrfwd_n;
  trn_rerrfwd_n         <= not trn_rerrfwd;


  trn_rdst_rdy          <= not trn_rdst_rdy_n;
  trn_tdst_rdy_n        <= not trn_tdst_rdy; -- c моста in tlp <= out bridge


  trn_rnp_ok            <= not trn_rnp_ok_n;
  rx_np_ok					<= trn_rnp_ok;

   trn_rbar_hit_n        <=  not trn_rbar_hit(6) &
                             not trn_rbar_hit(5) & not trn_rbar_hit(4) &
                             not trn_rbar_hit(3) & not trn_rbar_hit(2) &
                             not trn_rbar_hit(1) & not trn_rbar_hit(0);


   cfg_pcie_link_state_n <= not cfg_pcie_link_state(2) & not cfg_pcie_link_state(1) & not cfg_pcie_link_state(0);


   cfg_mgmt_byte_en      <= not cfg_byte_en_n(3) & not cfg_byte_en_n(2) & not cfg_byte_en_n(1) & not cfg_byte_en_n(0);
   cfg_mgmt_wr_en        <= not cfg_wr_en_n;
   cfg_mgmt_rd_en        <= not cfg_rd_en_n;



	--My



   
	
	cfg_interrupt         <= not cfg_interrupt_n;
   cfg_turnoff_ok        <= not cfg_turnoff_ok_n;
   
	



   
	
              	

   cfg_interrupt_rdy_n   <= not cfg_interrupt_rdy;
  

   cfg_interrupt_assert <= not cfg_interrupt_assert_n;


	 
	
	


   cfg_err_ecrc          <= not cfg_err_ecrc_n; -- in <= out
   cfg_err_ur            <= not cfg_err_ur_n;
   cfg_err_cpl_timeout   <= not cfg_err_cpl_timeout_n;
   cfg_err_cpl_unexpect  <= not cfg_err_cpl_unexpect_n;
   cfg_err_cpl_abort     <= not cfg_err_cpl_abort_n;
   cfg_err_posted        <= not cfg_err_posted_n;
   cfg_err_cor           <= not cfg_err_cor_n;
	cfg_err_locked			 <= not cfg_err_locked_n;
	cfg_trn_pending       <= not cfg_trn_pending_n;
	cfg_pm_wake           <= not cfg_pm_wake_n;
	
   tx_cfg_gnt 				 <= not trn_tcfg_gnt_n;
	trn_tstr					<= not trn_tstr_n;

   trn_tbuf_av				<= tx_buf_av;

   cfg_err_cor_n              <= '1';
   cfg_err_ur_n               <= '1';
   cfg_err_ecrc_n             <= '1';
   cfg_err_cpl_timeout_n      <= '1';
   cfg_err_cpl_abort_n        <= '1';
   cfg_err_cpl_unexpect_n     <= '1';
   cfg_err_posted_n           <= '0';
   cfg_err_locked_n           <= '0';
   cfg_err_tlp_cpl_header     <= (OTHERS=>'0');
   cfg_trn_pending_n          <= '1';
   cfg_pm_wake_n              <= '1';
                           

-- 
   trn_fc_sel                 <= (OTHERS=>'0');

   pl_directed_link_auton     <= '0';
   pl_directed_link_change    <= (OTHERS=>'0');
   pl_directed_link_speed     <= '0';
   pl_directed_link_width     <= (OTHERS=>'0');
   pl_upstream_prefer_deemph  <= '0';

   trn_tcfg_gnt_n             <= '0';
   trn_tstr_n                 <= '0';  -- '1';
                       
-- 

   trn_tdst_dsc_n             <= '1';

--
   cfg_di                     <= (OTHERS=>'0');
   cfg_dwaddr                 <= (OTHERS=>'1');
   cfg_byte_en_n              <= (OTHERS=>'1');
   cfg_wr_en_n                <= '1';
   cfg_rd_en_n                <= '1';
   cfg_dsn      <= X"00000001" &  X"01" & X"000A35";   -- //this is taken from GUI -

   cfg_turnoff_ok_n           <= '0';


   localId                    <= cfg_bus_number & cfg_device_number & cfg_function_number;

   pcie_link_width            <= cfg_lstatus(9 downto 4);



   trn_lnk_up_n_int_i: FDCP
     generic map (
                 INIT  => '1'
             )
     port map (
               Q     =>  trn_lnk_up_n,
               D     =>  trn_lnk_up_n_int1,
               C     =>  trn_clk,
               CLR   =>  '0',
               PRE   =>  '0'
              );


   trn_reset_n_i: FDCP
     generic map (
                 INIT  => '1'
              )
     port map (
               Q     =>  trn_reset_n,
               D     =>  trn_reset_n_int1,
               C     =>  trn_clk,
               CLR   =>  '0',
               PRE   =>  '0'
              );


-- --------------------------------------------------------------
-- --------------------------------------------------------------



-- ---------------------------------------------------------------
-- tlp control module
-- ---------------------------------------------------------------

  trn_rrem_n(7 downto 1) <= X"0" & trn_rrem_n(0) & trn_rrem_n(0) & trn_rrem_n(0); 
   theTlpControl:
   tlpControl 
   port map (

           mbuf_UserFull               => '0'                 ,
           trn_Blinker                 => trn_Blinker         ,

           -- Interrupter triggers
           DAQ_irq                     =>  DAQ_irq            ,  -- IN  std_logic;
           CTL_irq                     =>  CTL_irq            ,  -- IN  std_logic;
           DLM_irq                     =>  DLM_irq            ,  -- IN  std_logic;


--S	SIMONE: Wanxau UserLogic Signals, not Used
           -- DCB protocol interface
           protocol_link_act           =>  protocol_link_act  ,  -- IN  std_logic_vector(2-1 downto 0);
           protocol_rst                =>  protocol_rst       ,  -- OUT std_logic;
           Link_Buf_Full               =>  daq_rstop          ,  -- IN  std_logic;
           -- Fabric side: CTL Rx
           ctl_rv                      =>  ctl_rv             ,  -- OUT std_logic;
           ctl_rd                      =>  ctl_rd             ,  -- OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
           -- Fabric side: CTL Tx
           ctl_ttake                   =>  ctl_ttake          ,  -- OUT std_logic;
           ctl_tv                      =>  ctl_tv             ,  -- IN  std_logic;
           ctl_td                      =>  ctl_td             ,  -- IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
           ctl_tstop                   =>  ctl_tstop          ,  -- OUT std_logic;
           ctl_reset                   =>  ctl_reset          ,  -- OUT std_logic;
           ctl_status                  =>  ctl_status         ,  -- IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
           -- Fabric side: DLM Rx
           dlm_rv                      =>  dlm_rv             ,  -- OUT std_logic;
           dlm_rd                      =>  dlm_rd             ,  -- OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
           -- Fabric side: DLM Tx
           dlm_tv                      =>  dlm_tv             ,  -- IN  std_logic;
           dlm_td                      =>  dlm_td             ,  -- IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
           tab_we                      =>  tab_we             ,  -- OUT std_logic_vector(2-1 downto 0);
           tab_wa                      =>  tab_wa             ,  -- OUT std_logic_vector(12-1 downto 0);
           tab_wd                      =>  tab_wd             ,  -- OUT std_logic_vector(C_DBUS_WIDTH-1 downto 0);
           DG_is_Running               =>  dg_running         ,  -- IN  std_logic;
           DG_Reset                    =>  dg_rst             ,  -- OUT   STD_LOGIC;
           DG_Mask                     =>  dg_mask            ,  -- OUT   STD_LOGIC
--S	SIMONE: Wanxau UserLogic Signals, not Used


           -- SIMONE Register: PC-->FPGA
           reg01_tv                     => reg01_tv, 
           reg01_td                     => reg01_td,            
           reg02_tv                     => reg02_tv,            
           reg02_td                     => reg02_td,            
           reg03_tv                     => reg03_tv,            
           reg03_td                     => reg03_td,            
           reg04_tv                     => reg04_tv,            
           reg04_td                     => reg04_td,            
           reg05_tv                     => reg05_tv,            
           reg05_td                     => reg05_td,            
           reg06_tv                     => reg06_tv,            
           reg06_td                     => reg06_td,            
           reg07_tv                     => reg07_tv,            
           reg07_td                     => reg07_td,            
           reg08_tv                     => reg08_tv,            
           reg08_td                     => reg08_td,            
           reg09_tv                     => reg09_tv,            
           reg09_td                     => reg09_td,            
           reg10_tv                     => reg10_tv,            
           reg10_td                     => reg10_td,            
           reg11_tv                     => reg11_tv,            
           reg11_td                     => reg11_td,            
           reg12_tv                     => reg12_tv,            
           reg12_td                     => reg12_td,            
           reg13_tv                     => reg13_tv,            
           reg13_td                     => reg13_td,            
           reg14_tv                     => reg14_tv,            
           reg14_td                     => reg14_td,            

           -- SIMONE Register: FPGA-->PC
           reg01_rv                     => reg01_rv,            
           reg01_rd                     => reg01_rd,            
           reg02_rv                     => reg02_rv,            
           reg02_rd                     => reg02_rd,            
           reg03_rv                     => reg03_rv,            
           reg03_rd                     => reg03_rd,            
           reg04_rv                     => reg04_rv,            
           reg04_rd                     => reg04_rd,            
           reg05_rv                     => reg05_rv,            
           reg05_rd                     => reg05_rd,            
           reg06_rv                     => reg06_rv,            
           reg06_rd                     => reg06_rd,            
           reg07_rv                     => reg07_rv,            
           reg07_rd                     => reg07_rd,            
           reg08_rv                     => reg08_rv,            
           reg08_rd                     => reg08_rd,            
           reg09_rv                     => reg09_rv,            
           reg09_rd                     => reg09_rd,            
           reg10_rv                     => reg10_rv,            
           reg10_rd                     => reg10_rd,            
           reg11_rv                     => reg11_rv,            
           reg11_rd                     => reg11_rd,            
           reg12_rv                     => reg12_rv,            
           reg12_rd                     => reg12_rd,            
           reg13_rv                     => reg13_rv,            
           reg13_rd                     => reg13_rd,            
           reg14_rv                     => reg14_rv,            
           reg14_rd                     => reg14_rd,            

			  -- SIMONE debug signals	
			  debug_in_1i                  => debug_in_1i,	
			  debug_in_2i                  => debug_in_2i,	
			  debug_in_3i                  => debug_in_3i,	
			  debug_in_4i                  => debug_in_4i,	

           -- Event Buffer FIFO interface
           eb_FIFO_we                  => eb_we               , --  OUT std_logic; 
           eb_FIFO_wsof                => eb_wsof             , --  OUT std_logic; 
           eb_FIFO_weof                => eb_weof             , --  OUT std_logic; 
           eb_FIFO_din                 => eb_din(C_DBUS_WIDTH-1 downto 0) , --  OUT std_logic_vector(C_DBUS_WIDTH-1 downto 0);

           eb_FIFO_re                  => eb_re               , --  OUT std_logic; 
           eb_FIFO_empty               => eb_empty            , --  IN  std_logic; 
           eb_FIFO_qout                => eb_dout(C_DBUS_WIDTH-1 downto 0) , --  IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
           eb_FIFO_data_count          => eb_data_count       , --  IN  std_logic_vector(C_FIFO_DC_WIDTH downto 0);

           eb_FIFO_ow                  => eb_FIFO_ow          , --  IN  std_logic;

           pio_reading_status          => pio_reading_status  , --  OUT std_logic; 

           eb_FIFO_Status              => eb_FIFO_Status      , --  IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
           eb_FIFO_Rst                 => eb_rst              , --  OUT std_logic;
			  H2B_FIFO_Status					=> H2B_FIFO_Status     ,  						
			  B2H_FIFO_Status					=> B2H_FIFO_Status     ,  						

           -- Debugging signals
           DMA_us_Done                 => DMA_us_Done         , -- OUT std_logic;
           DMA_us_Busy                 => DMA_us_Busy         , -- OUT std_logic;
           DMA_us_Busy_LED             => LEDs_IO_pin(6)      , -- OUT std_logic;
           DMA_ds_Done                 => DMA_ds_Done         , -- OUT std_logic;
           DMA_ds_Busy                 => DMA_ds_Busy         , -- OUT std_logic;
           DMA_ds_Busy_LED             => LEDs_IO_pin(4)      , -- OUT std_logic;
                                                        
           -------------------
           -- DDR Interface
           DDR_Ready                   => DDR_Ready           , --  IN    std_logic;

           DDR_wr_sof                  => DDR_wr_sof          , --  OUT   std_logic;
           DDR_wr_eof                  => DDR_wr_eof          , --  OUT   std_logic;
           DDR_wr_v                    => DDR_wr_v            , --  OUT   std_logic;
           DDR_wr_FA                   => DDR_wr_FA           , --  OUT   std_logic;
           DDR_wr_Shift                => DDR_wr_Shift        , --  OUT   std_logic;
           DDR_wr_Mask                 => DDR_wr_Mask         , --  OUT   std_logic_vector(2-1 downto 0);
           DDR_wr_din                  => DDR_wr_din          , --  OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);
           DDR_wr_full                 => DDR_wr_full         , --  IN    std_logic;

           DDR_rdc_sof                 => DDR_rdc_sof         , --  OUT   std_logic;
           DDR_rdc_eof                 => DDR_rdc_eof         , --  OUT   std_logic;
           DDR_rdc_v                   => DDR_rdc_v           , --  OUT   std_logic;
           DDR_rdc_FA                  => DDR_rdc_FA          , --  OUT   std_logic;
           DDR_rdc_Shift               => DDR_rdc_Shift       , --  OUT   std_logic;
           DDR_rdc_din                 => DDR_rdc_din         , --  OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);
           DDR_rdc_full                => DDR_rdc_full        , --  IN    std_logic;

           -- DDR payload FIFO Read Port
           DDR_FIFO_RdEn               => DDR_FIFO_RdEn      ,  -- OUT std_logic; 
           DDR_FIFO_Empty              => DDR_FIFO_Empty     ,  -- IN  std_logic;
           DDR_FIFO_RdQout             => DDR_FIFO_RdQout    ,  -- IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
                                                      
           -------------------
           -- Transaction Interface
           trn_lnk_up_n                => trn_lnk_up_n            ,--my_lnk_up_n,--trn_lnk_up_n            ,
           trn_rsrc_dsc_n              => trn_rsrc_dsc_n          ,
           trn_rnp_ok_n                => trn_rnp_ok_n            ,
           trn_tsrc_dsc_n              => trn_tsrc_dsc_n          ,
           trn_tdst_dsc_n              => trn_tdst_dsc_n          ,
           trn_tbuf_av                 => trn_tbuf_av             ,
           trn_terrfwd_n               => trn_terrfwd_n           ,

           trn_clk                     => trn_clk                 ,
           trn_reset_n                 => trn_reset_n             ,--my_reset_n,--trn_reset_n             ,
           trn_rsrc_rdy_n              => trn_rsrc_rdy_n          ,
           trn_tdst_rdy_n              => trn_tdst_rdy_n          ,
           trn_rsof_n                  => trn_rsof_n              ,
           trn_reof_n                  => trn_reof_n              ,
           trn_rerrfwd_n               => trn_rerrfwd_n           ,
           trn_rrem_n                  => trn_rrem_n,--trn_rrem_n              ,
           trn_rd                      => trn_rd                  ,
                                                        
           cfg_interrupt_n             => cfg_interrupt_n         ,
           cfg_interrupt_rdy_n         => cfg_interrupt_rdy_n     ,
           cfg_interrupt_mmenable      => cfg_interrupt_mmenable  ,
           cfg_interrupt_msienable     => cfg_interrupt_msienable ,
           cfg_interrupt_di            => cfg_interrupt_di        ,
           cfg_interrupt_do            => cfg_interrupt_do        ,
           cfg_interrupt_assert_n      => cfg_interrupt_assert_n  ,

           trn_rbar_hit_n              => trn_rbar_hit_n          ,
           trn_tsrc_rdy_n              => trn_tsrc_rdy_n          ,
           trn_rdst_rdy_n              => trn_rdst_rdy_n          ,
           trn_tsof_n                  => trn_tsof_n              ,
           trn_teof_n                  => trn_teof_n              ,
           trn_trem_n                  => trn_trem_n,--trn_trem_n              ,
           trn_td                      => trn_td                  ,

           Format_Shower               => Format_Shower           ,

           cfg_dcommand                => cfg_dcommand            ,
           pcie_link_width             => pcie_link_width         ,
           localId                     => localId
           );
	

  -- -----------------------------------------------------------------------
  --  DDR SDRAM: control module USER LOGIC (2 BRAM Module: 
  -- -----------------------------------------------------------------------


  -- LoopBack_BRAM_Off:  if not USE_LOOPBACK_TEST generate

   DDRs_ctrl_module:
   adctofifo
   GENERIC MAP (
                C_ASYNFIFO_WIDTH    => 72 ,
                P_SIMULATION        => FALSE
               )
   PORT MAP(

      user_wr_weA             =>  user_wr_weA   ,
      user_wr_addrA           =>  user_wr_addrA ,
      user_wr_dinA            =>  user_wr_dinA  ,
      user_rd_addrB           =>  user_rd_addrB ,
      user_rd_doutB           =>  user_rd_doutB ,
      user_rd_clk             =>  clk_200MHz    ,
      user_wr_clk             =>  clk_200MHz    ,
		-- PART ADC
--		strobe_adc						=>  strobe_adc,
		-- PART ADC
		
      -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
      DDR_wr_sof               => DDR_wr_sof          , --  IN    std_logic;
      DDR_wr_eof               => DDR_wr_eof          , --  IN    std_logic;
      DDR_wr_v                 => DDR_wr_v            , --  IN    std_logic;
      DDR_wr_FA                => DDR_wr_FA           , --  IN    std_logic;
      DDR_wr_Shift             => DDR_wr_Shift        , --  IN    std_logic;
      DDR_wr_Mask              => DDR_wr_Mask         , --  IN    std_logic_vector(2-1 downto 0);
      DDR_wr_din               => DDR_wr_din          , --  IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);
      DDR_wr_full              => DDR_wr_full         , --  OUT   std_logic;

      DDR_rdc_sof              => DDR_rdc_sof         , --  IN    std_logic;
      DDR_rdc_eof              => DDR_rdc_eof         , --  IN    std_logic;
      DDR_rdc_v                => DDR_rdc_v           , --  IN    std_logic;
      DDR_rdc_FA               => DDR_rdc_FA          , --  IN    std_logic;
      DDR_rdc_Shift            => DDR_rdc_Shift       , --  IN    std_logic;
      DDR_rdc_din              => DDR_rdc_din         , --  IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);
      DDR_rdc_full             => DDR_rdc_full        , --  OUT   std_logic;

      -- DDR payload FIFO Read Port
      DDR_FIFO_RdEn            => DDR_FIFO_RdEn       ,  -- IN    std_logic; 
      DDR_FIFO_Empty           => DDR_FIFO_Empty      ,  -- OUT   std_logic;
      DDR_FIFO_RdQout          => DDR_FIFO_RdQout     ,  -- OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);

      -- Common interface
      DDR_Ready                => DDR_Ready           , --  OUT   std_logic;
      DDR_Blinker              => DDR_Blinker         , --  OUT   std_logic;
      mem_clk                  => trn_clk             , --  IN
      trn_clk                  => trn_clk             , --  IN    std_logic;
		Sim_Zeichen              => Sim_Zeichen         , --  OUT   std_logic;  
      trn_reset_n              => trn_reset_n,           --  IN    std_logic
		strobe_adc					 => strobe_adc	,				--	IN    std_logic
		adcclock => adcclock,
			fifowr_clk =>fifowr_clk   ,
			fifowr_en     =>fifowr_en,
			fifodin       =>fifodin,
			fifofull      => open,
			fifoprog_full => open
    );
   
--	end generate;

   


    LEDs_IO_pin(0)    <= trn_reset_n xor Format_Shower;
    LEDs_IO_pin(1)    <= trn_lnk_up_n  ;
    LEDs_IO_pin(2)    <= Format_Shower ;
    LEDs_IO_pin(3)    <= trn_Blinker   ;



    ------------------------ -----------------------
    -- Event Buffer wrapper (FIFO Module: H2B & B2H)
    ------------------------ -----------------------

   LoopBack_FIFO_Off:  if not USE_LOOPBACK_TEST generate

    queue_buffer0:
    eb_wrapper
      port map (  

         H2B_wr_clk     		=> trn_clk   				,  
         H2B_wr_en      		=> eb_we  					,
         H2B_wr_din       		=> eb_din 					,
         H2B_wr_pfull     		=> eb_pfull  				,
         H2B_wr_full      		=> eb_full   				,
         H2B_wr_data_count    => H2B_wr_data_count(C_EMU_FIFO_DC_WIDTH-1+1 downto 1) ,

         H2B_rd_clk           => clk_200MHz       		,
			H2B_rd_en            => user_rd_en        	,
         H2B_rd_dout          => user_rd_dout      	,
         H2B_rd_pempty        => user_rd_pempty    	,
         H2B_rd_empty         => user_rd_empty     	,
         H2B_rd_valid         => user_rd_valid     	,
         H2B_rd_data_count    => user_rd_data_count	,
         
			B2H_wr_clk           => fifowr_clk       		,
         B2H_wr_en            => fifowr_en        		,
         B2H_wr_din           => user_wr_dinA       	,
         B2H_wr_pfull         => fifoprog_full     	,
         B2H_wr_full          => fifofull       		,
         B2H_wr_data_count    => user_wr_data_count	,


         B2H_rd_clk        	=> trn_clk   				,  
         B2H_rd_en         	=> eb_re,--eb_re     				,
         B2H_rd_dout       	=> eb_dout   				,
         B2H_rd_pempty     	=> eb_pempty 				,
         B2H_rd_empty      	=> eb_empty  				,
         B2H_rd_valid      	=> eb_valid  				,
         B2H_rd_data_count 	=> B2H_rd_data_count(C_EMU_FIFO_DC_WIDTH-1+1 downto 1) ,

         rst        				=> eb_rst    ,
			resetfifo => resetfifo
         );



		--- 64 bits to 32 bits transformation ( --> Count * 2)--- 
      B2H_rd_data_count(C_FIFO_DC_WIDTH downto C_EMU_FIFO_DC_WIDTH+1)
                        <= C_ALL_ZEROS(C_FIFO_DC_WIDTH downto C_EMU_FIFO_DC_WIDTH+1);
      B2H_rd_data_count(0) <= '0';       
                      
      H2B_wr_data_count(C_FIFO_DC_WIDTH downto C_EMU_FIFO_DC_WIDTH+1)
                        <= C_ALL_ZEROS(C_FIFO_DC_WIDTH downto C_EMU_FIFO_DC_WIDTH+1);
      H2B_wr_data_count(0) <= '0';       
							 

		--- Hybrid FIFO Signal used by PCIe interface and Linux Driver
      eb_FIFO_ow      <= eb_we_up and eb_full;
      fifo_reset_done <= not eb_rst;
      eb_din(72-1 downto C_DBUS_WIDTH) <= (OTHERS=>'0');
		eb_data_count   <= B2H_rd_data_count;

		--- Hybrid FIFO Status used by PCIe interface and Linux Driver ---
		--- read: status ; write: reset H2B and B2H FIFO
      eb_FIFO_Status(C_DBUS_WIDTH-1 downto C_FIFO_DC_WIDTH+3)
                           <= (OTHERS=>'0');
      eb_FIFO_Status(C_FIFO_DC_WIDTH+2 downto 3)
                           <= B2H_rd_data_count(C_FIFO_DC_WIDTH downto 1);
      eb_FIFO_Status(2)    <= '0';      
      eb_FIFO_Status(1)    <= eb_pfull;
      eb_FIFO_Status(0)    <= eb_empty and fifo_reset_done;


		--- Host2Board FIFO status used by user ---
		--- read: H2B status ; write: nothing 
      H2B_FIFO_Status(C_DBUS_WIDTH-1 downto C_FIFO_DC_WIDTH+3)
                           <= (OTHERS=>'0');
      H2B_FIFO_Status(C_FIFO_DC_WIDTH+2 downto 3)
                           <= H2B_wr_data_count(C_FIFO_DC_WIDTH downto 1);
      H2B_FIFO_Status(2)    <= '0';
      H2B_FIFO_Status(1)    <= eb_pfull;
      H2B_FIFO_Status(0)    <= eb_full and fifo_reset_done;


		--- Board2Host FIFO status used by user ---
		--- read: B2H status ; write: nothing 
      B2H_FIFO_Status(C_DBUS_WIDTH-1 downto C_FIFO_DC_WIDTH+3)
                           <= (OTHERS=>'0');
      B2H_FIFO_Status(C_FIFO_DC_WIDTH+2 downto 3)
                           <= B2H_rd_data_count(C_FIFO_DC_WIDTH downto 1);
      B2H_FIFO_Status(2)    <= eb_valid;
      B2H_FIFO_Status(1)    <= eb_pempty;
      B2H_FIFO_Status(0)    <= eb_empty and fifo_reset_done;


   end generate;



  v7_pcie_i : v7_pcie  generic map(
          PL_FAST_TRAIN                         => PL_FAST_TRAIN,
      PCIE_EXT_CLK                          => PCIE_EXT_CLK,
		UPSTREAM_FACING => UPSTREAM_FACING
		
      )
  port map(
  -------------------------------------------------------------------------------------------------------------------
  -- 1. PCI Express (pci_exp) Interface                                                                            --
  -------------------------------------------------------------------------------------------------------------------
  -- TX
  pci_exp_txp                               => pci_exp_txp,
  pci_exp_txn                               => pci_exp_txn,
  -- RX
  pci_exp_rxp                               => pci_exp_rxp,
  pci_exp_rxn                               => pci_exp_rxn,

  -------------------------------------------------------------------------------------------------------------------
  -- 2. Clocking Interface - For Partial Reconfig Support                                                          --
  -------------------------------------------------------------------------------------------------------------------
  PIPE_PCLK_IN                               => PIPE_PCLK_IN,
  PIPE_RXUSRCLK_IN                           => PIPE_RXUSRCLK_IN,
  PIPE_RXOUTCLK_IN                           => PIPE_RXOUTCLK_IN,
  PIPE_DCLK_IN                               => PIPE_DCLK_IN,
  PIPE_USERCLK1_IN                           => PIPE_USERCLK1_IN,
  PIPE_USERCLK2_IN                           => PIPE_USERCLK2_IN,
  PIPE_OOBCLK_IN                             => PIPE_OOBCLK_IN,
  PIPE_MMCM_LOCK_IN                          => PIPE_MMCM_LOCK_IN,
  PIPE_TXOUTCLK_OUT                          => PIPE_TXOUTCLK_OUT,
  PIPE_RXOUTCLK_OUT                          => PIPE_RXOUTCLK_OUT,
  PIPE_PCLK_SEL_OUT                          => PIPE_PCLK_SEL_OUT,
  PIPE_GEN3_OUT                              => PIPE_GEN3_OUT,

  -------------------------------------------------------------------------------------------------------------------
  -- 3. AXI-S Interface                                                                                            --
  -------------------------------------------------------------------------------------------------------------------
  -- Common
  user_clk_out                               => trn_clk ,
  user_reset_out                             => user_reset,
  user_lnk_up                                => user_lnk_up,

  -- TX
  tx_buf_av                                  => tx_buf_av ,
  tx_cfg_req                                 => tx_cfg_req ,
  tx_err_drop                                => tx_err_drop ,
  s_axis_tx_tready                           => s_axis_tx_tready ,
  s_axis_tx_tdata                            => s_axis_tx_tdata ,
  s_axis_tx_tkeep                            => s_axis_tx_tkeep ,
  s_axis_tx_tlast                            => s_axis_tx_tlast ,
  s_axis_tx_tvalid                           => s_axis_tx_tvalid ,
  s_axis_tx_tuser                            => s_axis_tx_tuser,
  tx_cfg_gnt                                 => tx_cfg_gnt,--'1',--tx_cfg_gnt ,

  -- RX
  m_axis_rx_tdata                            => m_axis_rx_tdata ,
  m_axis_rx_tkeep                            => m_axis_rx_tkeep ,
  m_axis_rx_tlast                            => m_axis_rx_tlast ,
  m_axis_rx_tvalid                           => m_axis_rx_tvalid ,
  m_axis_rx_tready                           => m_axis_rx_tready ,
  m_axis_rx_tuser                            => m_axis_rx_tuser,
  rx_np_ok                                   => rx_np_ok ,--trn_rnp_ok,--rx_np_ok ,
  rx_np_req                                  => rx_np_req ,

  -- Flow Control
  fc_cpld                                    => fc_cpld ,
  fc_cplh                                    => fc_cplh ,
  fc_npd                                     => fc_npd ,
  fc_nph                                     => fc_nph ,
  fc_pd                                      => fc_pd ,
  fc_ph                                      => fc_ph ,
  fc_sel                                     => fc_sel ,

  -------------------------------------------------------------------------------------------------------------------
  -- 4. Configuration (CFG) Interface                                                                              --
  -------------------------------------------------------------------------------------------------------------------
  ---------------------------------------------------------------------
   -- EP and RP                                                      --
  ---------------------------------------------------------------------

  cfg_mgmt_do                                => open ,
  cfg_mgmt_rd_wr_done                        => open ,

  cfg_status                                 => cfg_status ,
  cfg_command                                => cfg_command ,
  cfg_dstatus                                => cfg_dstatus ,
  cfg_dcommand                               => cfg_dcommand ,
  cfg_lstatus                                => cfg_lstatus ,
  cfg_lcommand                               => cfg_lcommand ,
  cfg_dcommand2                              => cfg_dcommand2 ,
  cfg_pcie_link_state                        => cfg_pcie_link_state ,

  cfg_pmcsr_pme_en                           => open ,
  cfg_pmcsr_pme_status                       => open ,
  cfg_pmcsr_powerstate                       => open ,
  cfg_received_func_lvl_rst                  => open ,

  cfg_mgmt_di                                => cfg_di,----cfg_mgmt_di ,
  cfg_mgmt_byte_en                           => cfg_mgmt_byte_en ,
  cfg_mgmt_dwaddr                            => cfg_dwaddr,----cfg_mgmt_dwaddr ,
  cfg_mgmt_wr_en                             => cfg_mgmt_wr_en ,
  cfg_mgmt_rd_en                             => cfg_mgmt_rd_en ,
  cfg_mgmt_wr_readonly                       => cfg_mgmt_wr_readonly ,

  cfg_err_ecrc                               => cfg_err_ecrc ,
  cfg_err_ur                                 => cfg_err_ur ,
  cfg_err_cpl_timeout                        => cfg_err_cpl_timeout ,
  cfg_err_cpl_unexpect                       => cfg_err_cpl_unexpect ,
  cfg_err_cpl_abort                          => cfg_err_cpl_abort ,
  cfg_err_posted                             => cfg_err_posted ,
  cfg_err_cor                                => cfg_err_cor ,
  cfg_err_atomic_egress_blocked              => cfg_err_atomic_egress_blocked ,
  cfg_err_internal_cor                       => cfg_err_internal_cor ,
  cfg_err_malformed                          => cfg_err_malformed ,
  cfg_err_mc_blocked                         => cfg_err_mc_blocked ,
  cfg_err_poisoned                           => cfg_err_poisoned ,
  cfg_err_norecovery                         => cfg_err_norecovery ,
  cfg_err_tlp_cpl_header                     => cfg_err_tlp_cpl_header,--cfg_err_tlp_cpl_header,
  cfg_err_cpl_rdy                            => cfg_err_cpl_rdy ,
  cfg_err_locked                             => cfg_err_locked ,
  cfg_err_acs                                => cfg_err_acs ,
  cfg_err_internal_uncor                     => cfg_err_internal_uncor ,

  cfg_trn_pending                            => cfg_trn_pending ,
  cfg_pm_halt_aspm_l0s                       => cfg_pm_halt_aspm_l0s ,
  cfg_pm_halt_aspm_l1                        => cfg_pm_halt_aspm_l1 ,
  cfg_pm_force_state_en                      => cfg_pm_force_state_en ,
  cfg_pm_force_state                         => cfg_pm_force_state ,

  ---------------------------------------------------------------------
   -- EP Only                                                        --
  ---------------------------------------------------------------------

  cfg_interrupt                              => cfg_interrupt ,
  cfg_interrupt_rdy                          => cfg_interrupt_rdy ,
  cfg_interrupt_assert                       => cfg_interrupt_assert,
  cfg_interrupt_di                           => cfg_interrupt_di ,
  cfg_interrupt_do                           => cfg_interrupt_do ,
  cfg_interrupt_mmenable                     => cfg_interrupt_mmenable ,
  cfg_interrupt_msienable                    => cfg_interrupt_msienable ,
  cfg_interrupt_msixenable                   => cfg_interrupt_msixenable ,
  cfg_interrupt_msixfm                       => cfg_interrupt_msixfm ,
  cfg_interrupt_stat                         => cfg_interrupt_stat ,
  cfg_pciecap_interrupt_msgnum               => cfg_pciecap_interrupt_msgnum ,
  cfg_to_turnoff                             => cfg_to_turnoff ,
  cfg_turnoff_ok                             => cfg_turnoff_ok ,
  cfg_bus_number                             => cfg_bus_number ,
  cfg_device_number                          => cfg_device_number ,
  cfg_function_number                        => cfg_function_number ,
  cfg_pm_wake                                => cfg_pm_wake ,

  ---------------------------------------------------------------------
   -- RP Only                                                        --
  ---------------------------------------------------------------------
  cfg_pm_send_pme_to                         => '0' ,
  cfg_ds_bus_number                          => cfg_bus_number,---x"00" ,
  cfg_ds_device_number                       => cfg_device_number,---"00000" ,
  cfg_ds_function_number                     => cfg_function_number,---"000" ,
  cfg_mgmt_wr_rw1c_as_rw                     => '0' ,
  cfg_msg_received                           => open ,
  cfg_msg_data                               => open ,

  cfg_bridge_serr_en                         => open ,
  cfg_slot_control_electromech_il_ctl_pulse  => open ,
  cfg_root_control_syserr_corr_err_en        => open ,
  cfg_root_control_syserr_non_fatal_err_en   => open ,
  cfg_root_control_syserr_fatal_err_en       => open ,
  cfg_root_control_pme_int_en                => open ,
  cfg_aer_rooterr_corr_err_reporting_en      => open ,
  cfg_aer_rooterr_non_fatal_err_reporting_en => open ,
  cfg_aer_rooterr_fatal_err_reporting_en     => open ,
  cfg_aer_rooterr_corr_err_received          => open ,
  cfg_aer_rooterr_non_fatal_err_received     => open ,
  cfg_aer_rooterr_fatal_err_received         => open ,

  cfg_msg_received_err_cor                   => open ,
  cfg_msg_received_err_non_fatal             => open ,
  cfg_msg_received_err_fatal                 => open ,
  cfg_msg_received_pm_as_nak                 => open ,
  cfg_msg_received_pm_pme                    => open ,
  cfg_msg_received_pme_to_ack                => open ,
  cfg_msg_received_assert_int_a              => open ,
  cfg_msg_received_assert_int_b              => open ,
  cfg_msg_received_assert_int_c              => open ,
  cfg_msg_received_assert_int_d              => open ,
  cfg_msg_received_deassert_int_a            => open ,
  cfg_msg_received_deassert_int_b            => open ,
  cfg_msg_received_deassert_int_c            => open ,
  cfg_msg_received_deassert_int_d            => open ,

  -------------------------------------------------------------------------------------------------------------------
  -- 5. Physical Layer Control and Status (PL) Interface                                                           --
  -------------------------------------------------------------------------------------------------------------------
  pl_directed_link_auton                     => pl_directed_link_auton ,
  pl_directed_link_change                    => pl_directed_link_change ,
  pl_directed_link_speed                     => pl_directed_link_speed ,
  pl_directed_link_width                     => pl_directed_link_width ,
  pl_upstream_prefer_deemph                  => pl_upstream_prefer_deemph ,

  pl_sel_lnk_rate                            => pl_sel_lnk_rate ,
  pl_sel_lnk_width                           => pl_sel_lnk_width ,
  pl_ltssm_state                             => pl_ltssm_state ,
  pl_lane_reversal_mode                      => pl_lane_reversal_mode ,

  pl_phy_lnk_up                              => open ,
  pl_tx_pm_state                             => open ,
  pl_rx_pm_state                             => open ,

  cfg_dsn                                    => cfg_dsn ,

  pl_link_upcfg_cap                          => pl_link_upcfg_cap ,
  pl_link_gen2_cap                           => pl_link_gen2_cap ,
  pl_link_partner_gen2_supported             => pl_link_partner_gen2_supported ,
  pl_initial_link_width                      => pl_initial_link_width ,

  pl_directed_change_done                    => open ,

  ---------------------------------------------------------------------
   -- EP Only                                                        --
  ---------------------------------------------------------------------
  pl_received_hot_rst                        => pl_received_hot_rst ,

  ---------------------------------------------------------------------
   -- RP Only                                                        --
  ---------------------------------------------------------------------
  pl_transmit_hot_rst                        => '0' ,
  pl_downstream_deemph_source                => '0' ,

  -------------------------------------------------------------------------------------------------------------------
  -- 6. AER interface                                                                                              --
  -------------------------------------------------------------------------------------------------------------------
  cfg_err_aer_headerlog                      => cfg_err_aer_headerlog ,
  cfg_aer_interrupt_msgnum                   => cfg_aer_interrupt_msgnum ,
  cfg_err_aer_headerlog_set                  => cfg_err_aer_headerlog_set ,
  cfg_aer_ecrc_check_en                      => cfg_aer_ecrc_check_en ,
  cfg_aer_ecrc_gen_en                        => cfg_aer_ecrc_gen_en ,

  -------------------------------------------------------------------------------------------------------------------
  -- 7. VC interface                                                                                               --
  -------------------------------------------------------------------------------------------------------------------
  cfg_vc_tcvc_map                            => open ,


  -------------------------------------------------------------------------------------------------------------------
  -- 8. System(SYS) Interface                                                                                      --
  -------------------------------------------------------------------------------------------------------------------
  PIPE_MMCM_RST_N                            =>  PIPE_MMCM_RST_N ,        -- Async      | Async
 sys_clk                                      => sys_clk_c,--sys_clk ,
  sys_rst_n                                  => sys_reset_n_c

);


	
  pcie_axi_trn_bridge_i : pcie_axi_trn_bridge
  generic map (
    C_DATA_WIDTH              => C_DATA_WIDTH,
 --   RBAR_WIDTH                => 8,
    RBAR_WIDTH 					=> 7,
    REM_WIDTH                 => 1
  )
  port map (
  
	-- trn_tcfg_gnt_n		   => trn_tcfg_gnt_n,
	-- tx_cfg_gnt					=> tx_cfg_gnt,
	 
    user_clk               => trn_clk,
    user_reset             => user_reset,
    user_lnk_up            => user_lnk_up,



    s_axis_tx_tdata        => s_axis_tx_tdata,
    s_axis_tx_tvalid       => s_axis_tx_tvalid,
	 s_axis_tx_tready       => s_axis_tx_tready_i,
--	 s_axis_tx_tready 		=> s_axis_tx_tready,
	 s_axis_tx_tkeep        => s_axis_tx_tkeep,
    s_axis_tx_tlast        => s_axis_tx_tlast,
    s_axis_tx_tuser        => s_axis_tx_tuser,

    m_axis_rx_tdata        => m_axis_rx_tdata,
    m_axis_rx_tvalid       => m_axis_rx_tvalid,
    m_axis_rx_tready       => m_axis_rx_tready,
    m_axis_rx_tkeep        => m_axis_rx_tkeep,
    m_axis_rx_tlast        => m_axis_rx_tlast,
    m_axis_rx_tuser        => m_axis_rx_tuser,

    trn_td                 => trn_td,
    trn_tsof               => trn_tsof,
    trn_teof               => trn_teof,
    trn_tsrc_rdy           => trn_tsrc_rdy,
    trn_tdst_rdy           => trn_tdst_rdy,
    trn_tsrc_dsc           => trn_tsrc_dsc,
    trn_trem(0)            	=> trn_trem(0),
    trn_terrfwd            => trn_terrfwd,
    trn_tstr               => '0',
    trn_tecrc_gen          => '0',

    trn_rd                 => trn_rd,
    trn_rsof               => trn_rsof,
    trn_reof               => trn_reof,
    trn_rsrc_rdy           => trn_rsrc_rdy,
    trn_rdst_rdy           => trn_rdst_rdy,
    trn_rsrc_dsc           => trn_rsrc_dsc,
    trn_rrem(0)            	=> trn_rrem(0),
    trn_rerrfwd            => trn_rerrfwd,
    trn_rbar_hit				=> trn_rbar_hit
);    


end Behavioral;
