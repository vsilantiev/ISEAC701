-------------------------------------------------------------------------------
--
-- (c) Copyright 2010-2011 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
-------------------------------------------------------------------------------
-- Project    : Series-7 Integrated Block for PCI Express
-- File       : pcie_axi_trn_bridge.vhd
-- Version    : 1.11
--
--     Description : AXI - TRN Bridge for Root Port Model. 
--                   Root Port Usrapp's require TRN interface.
--
--  This file is to be used for simulation purposes only
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.abb64Package.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;
entity pcie_axi_trn_bridge is
  generic(
    C_DATA_WIDTH           : integer range 32 to 128 := 64;
    RBAR_WIDTH             : integer := 7;
    REM_WIDTH              : integer range 1 to 2 :=1;
	 PL_FAST_TRAIN          : string := "FALSE";
    PCIE_EXT_CLK           : string := "FALSE";
    UPSTREAM_FACING        : string := "TRUE"
);
  port
  (
  
     ---------------------------------------------------------
    -- 1. PCI Express (pci_exp) Interface
    ---------------------------------------------------------

    -- Tx
    pci_exp_txn                    : out STD_LOGIC_VECTOR ( 3 downto 0 ); 
    pci_exp_txp                    : out STD_LOGIC_VECTOR ( 3 downto 0 ); 
                  
    -- Rx
    pci_exp_rxn                    : in  STD_LOGIC_VECTOR ( 3 downto 0 ); 
    pci_exp_rxp                    : in  STD_LOGIC_VECTOR ( 3 downto 0 ); 
                  
    ---------------------------------------------------------
    -- 2. Transaction (TRN) Interface
    ---------------------------------------------------------

    -- Common
    trn_clk                        : inout STD_LOGIC; 
    trn_reset_n                    : out STD_LOGIC; 
    trn_lnk_up_n                   : out STD_LOGIC; 

    -- Tx                      
    trn_tsof_n                     : in  STD_LOGIC; 
    trn_teof_n                     : in  STD_LOGIC; 
    trn_td                         : in  STD_LOGIC_vector (64-1 downto 0); 
    trn_trem_n                     : in  std_logic_vector(0 downto 0); 
    trn_tsrc_rdy_n                 : in  STD_LOGIC; 
    trn_tsrc_dsc_n                 : in  STD_LOGIC; 
    trn_tbuf_av                    : out STD_LOGIC_vector (6-1 downto 0); 
    trn_terrfwd_n                  : in  STD_LOGIC; 

    trn_tcfg_req_n                 : out STD_LOGIC;
    trn_terr_drop_n                : out STD_LOGIC; 
    trn_tdst_rdy_n                 : out STD_LOGIC; 
    trn_tcfg_gnt_n                 : in  STD_LOGIC; 
    trn_tstr_n                     : in  STD_LOGIC; 

    -- Rx                      
    trn_rd                         : out STD_LOGIC_vector (64-1 downto 0); 
    trn_rrem_n                     : out  std_logic_vector(0 downto 0); 
    trn_rsof_n                     : out STD_LOGIC; 
    trn_reof_n                     : out STD_LOGIC; 
    trn_rsrc_rdy_n                 : out STD_LOGIC; 
    trn_rsrc_dsc_n                 : out STD_LOGIC; 
    trn_rerrfwd_n                  : out STD_LOGIC; 
    trn_rbar_hit_n                 : out STD_LOGIC_vector (7-1 downto 0); 
    trn_rdst_rdy_n                 : in  STD_LOGIC; 
    trn_rnp_ok_n                   : in  STD_LOGIC; 

    -- Flow Control            
    trn_fc_cpld                    : out STD_LOGIC_vector (12-1 downto 0); 
    trn_fc_cplh                    : out STD_LOGIC_vector (8-1 downto 0); 
    trn_fc_npd                     : out STD_LOGIC_vector (12-1 downto 0); 
    trn_fc_nph                     : out STD_LOGIC_vector (8-1 downto 0); 
    trn_fc_pd                      : out STD_LOGIC_vector (12-1 downto 0); 
    trn_fc_ph                      : out STD_LOGIC_vector (8-1 downto 0); 
    trn_fc_sel                     : in  STD_LOGIC_vector (3-1 downto 0); 
                               

    ---------------------------------------------------------
    -- 3. Configuration (CFG) Interface
    ---------------------------------------------------------

    cfg_do                         : out STD_LOGIC_vector (32-1 downto 0); 
    cfg_rd_wr_done_n               : out STD_LOGIC; 
    cfg_di                         : in  STD_LOGIC_vector (32-1 downto 0); 
    cfg_byte_en_n                  : in  STD_LOGIC_vector (4-1 downto 0); 
    cfg_dwaddr                     : in  STD_LOGIC_vector (10-1 downto 0); 
    cfg_wr_en_n                    : in  STD_LOGIC; 
    cfg_rd_en_n                    : in  STD_LOGIC; 

    cfg_err_cor_n                  : in  STD_LOGIC; 
    cfg_err_ur_n                   : in  STD_LOGIC; 
    cfg_err_ecrc_n                 : in  STD_LOGIC; 
    cfg_err_cpl_timeout_n          : in  STD_LOGIC; 
    cfg_err_cpl_abort_n            : in  STD_LOGIC; 
    cfg_err_cpl_unexpect_n         : in  STD_LOGIC; 
    cfg_err_posted_n               : in  STD_LOGIC; 
    cfg_err_locked_n               : in  STD_LOGIC; 
    cfg_err_tlp_cpl_header         : in  STD_LOGIC_vector (48-1 downto 0); 
    cfg_err_cpl_rdy_n              : out STD_LOGIC; 
    cfg_interrupt_n                : in  STD_LOGIC; 
    cfg_interrupt_rdy_n            : out STD_LOGIC; 
    cfg_interrupt_assert_n         : in  STD_LOGIC; 
    cfg_interrupt_di               : in  STD_LOGIC_vector (8-1 downto 0); 
    cfg_interrupt_do               : out STD_LOGIC_vector (8-1 downto 0); 
    cfg_interrupt_mmenable         : out STD_LOGIC_vector (3-1 downto 0); 
    cfg_interrupt_msienable        : out STD_LOGIC; 
    cfg_interrupt_msixenable       : out STD_LOGIC; 
    cfg_interrupt_msixfm           : out STD_LOGIC; 
    cfg_turnoff_ok_n               : in  STD_LOGIC; 
    cfg_to_turnoff_n               : out STD_LOGIC; 
    cfg_trn_pending_n              : in  STD_LOGIC; 
    cfg_pm_wake_n                  : in  STD_LOGIC; 
    cfg_bus_number                 : out STD_LOGIC_vector (8-1 downto 0); 
    cfg_device_number              : out STD_LOGIC_vector (5-1 downto 0); 
    cfg_function_number            : out STD_LOGIC_vector (3-1 downto 0); 
    cfg_status                     : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_command                    : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_dstatus                    : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_dcommand                   : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_lstatus                    : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_lcommand                   : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_dcommand2                  : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_pcie_link_state_n          : out STD_LOGIC_vector (3-1 downto 0); 
    cfg_dsn                        : in  STD_LOGIC_vector (64-1 downto 0); 
    cfg_pmcsr_pme_en               : out STD_LOGIC; 
    cfg_pmcsr_pme_status           : out STD_LOGIC; 
    cfg_pmcsr_powerstate           : out STD_LOGIC_vector (2-1 downto 0); 
--S v1.3 --> 1.6    lnk_clk_en     : out STD_LOGIC; 
--	 lnk_clk_en     					  : out STD_LOGIC; 

    ---------------------------------------------------------
    -- 4. Physical Layer Control and Status (PL) Interface
    ---------------------------------------------------------

    pl_initial_link_width          : out STD_LOGIC_vector (3-1 downto 0);
    pl_lane_reversal_mode          : out STD_LOGIC_vector (2-1 downto 0);
    pl_link_gen2_capable           : out STD_LOGIC;
    pl_link_partner_gen2_supported : out STD_LOGIC;
    pl_link_upcfg_capable          : out STD_LOGIC;
    pl_ltssm_state                 : out STD_LOGIC_vector (6-1 downto 0);
    pl_received_hot_rst            : out STD_LOGIC;
    pl_sel_link_rate               : out STD_LOGIC;
    pl_sel_link_width              : out STD_LOGIC_vector (2-1 downto 0);
    pl_directed_link_auton         : in  STD_LOGIC;
    pl_directed_link_change        : in  STD_LOGIC_vector (2-1 downto 0);
    pl_directed_link_speed         : in  STD_LOGIC;
    pl_directed_link_width         : in  STD_LOGIC_vector (2-1 downto 0);
    pl_upstream_prefer_deemph      : in  STD_LOGIC;


    ---------------------------------------------------------
    -- 5. System  (SYS) Interface
    ---------------------------------------------------------

    sys_clk                        : in  STD_LOGIC;
    sys_rst_n                    : in  STD_LOGIC

 );

end pcie_axi_trn_bridge; 

architecture Behavioral of pcie_axi_trn_bridge is 
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
  

  
  
  
  
  
-- signal tx_cfg_gnt : std_logic; -- ON OUT IN V6PCIE
--  signal trn_clk : std_logic; -- ON OUT IN V6PCIE
 -- signal trn_reset_n : std_logic; -- ON OUT IN V6PCIE
 -- signal trn_lnk_up_n : std_logic; -- ON OUT IN V6PCIE
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
  
  signal s_axis_tx_tready_i       : std_logic;
  
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


  signal sys_rst                        : std_logic;
  -- Wires used for external clocking connectivity

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






  signal is_sof : std_logic_vector(4 downto 0);
  signal is_eof : std_logic_vector(4 downto 0);
  
  signal trn_tdst_rdy_int     : std_logic;
  signal trn_tsrc_rdy_derived : std_logic := '0';
  signal in_packet_reg        : std_logic;
  signal m_axis_rx_tready_int : std_logic;
  constant TCQ                  : time           := 1 ps;
begin



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

  PIPE_PCLK_IN        							=> '0',
  PIPE_RXUSRCLK_IN    							=> '0',
  PIPE_RXOUTCLK_IN    							=> (others => '0'),
  PIPE_DCLK_IN        							=> '0',
  PIPE_USERCLK1_IN    							=> '0',
  PIPE_USERCLK2_IN    							=> '0',
  PIPE_OOBCLK_IN      							=> '0',
  PIPE_MMCM_LOCK_IN  							=> '0',
  PIPE_TXOUTCLK_OUT                       => open,
  PIPE_RXOUTCLK_OUT                       => open,
  PIPE_PCLK_SEL_OUT                       => open,
  PIPE_GEN3_OUT                           => open,

  -------------------------------------------------------------------------------------------------------------------
  -- 3. AXI-S Interface                                                                                            --
  -------------------------------------------------------------------------------------------------------------------
  -- Common
  user_clk_out                               => user_clk ,
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
  tx_cfg_gnt                                 => tx_cfg_gnt,

  -- RX
  m_axis_rx_tdata                            => m_axis_rx_tdata ,
  m_axis_rx_tkeep                            => m_axis_rx_tkeep ,
  m_axis_rx_tlast                            => m_axis_rx_tlast ,
  m_axis_rx_tvalid                           => m_axis_rx_tvalid ,
  m_axis_rx_tready                           => m_axis_rx_tready ,
  m_axis_rx_tuser                            => m_axis_rx_tuser,
  rx_np_ok                                   => rx_np_ok ,
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

  cfg_mgmt_di                                => cfg_mgmt_di ,
  cfg_mgmt_byte_en                           => cfg_mgmt_byte_en ,
  cfg_mgmt_dwaddr                            => cfg_mgmt_dwaddr ,
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
  cfg_err_tlp_cpl_header                     => cfg_err_tlp_cpl_header,
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
  cfg_ds_bus_number                          => x"00" ,
  cfg_ds_device_number                       => "00000" ,
  cfg_ds_function_number                     => "000" ,
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
  PIPE_MMCM_RST_N                            => '1',        -- Async      | Async
  sys_clk                                    => sys_clk,--sys_clk ,
  sys_rst_n                                  => sys_rst_n

);


--  process (trn_clk)
--  begin
--   if (user_reset = '1') then
--       s_axis_tx_tready_i <= '0' after TCQ;
--   elsif (trn_clk'event and trn_clk = '1') then
--       s_axis_tx_tready_i <= s_axis_tx_tready after TCQ;
--   end if;
--  end process;

--  process(trn_clk)
--  begin
--    if (trn_clk'event and trn_clk='1') then
--     if (user_reset = '1') then
--       user_reset_q  <= '1' after TCQ;
--       user_lnk_up_q <= '0' after TCQ;
--     else
--       user_reset_q  <= user_reset after TCQ;
--       user_lnk_up_q <= user_lnk_up after TCQ;
--     end if;
--    end if;
--  end process;



  tx_cfg_gnt <= not trn_tcfg_gnt_n;	-- IN NOT SIGNAL

  trn_clk		<= user_clk;
  trn_reset_n <= not user_reset;
  trn_lnk_up_n <= not user_lnk_up;

  trn_trem(0)					<= not trn_trem_n(0);
  trn_rrem_n(0)				<= not trn_rrem(0);
  
  trn_tsof              <= not trn_tsof_n; --   trn_tsof(SIGNAL EST ISPOLZET MODUL)  <= trn_sof_n(SIGNAL NENUGEN) IN BRIDGE
  trn_teof              <= not trn_teof_n; --	trn_teof(ZADAET TKEEP)					<=	 trn_teof_n(SIGNAL NENUGEN) IN BRIDGE
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
	cfg_mgmt_di				 <= cfg_di;
	cfg_mgmt_dwaddr		 <= cfg_dwaddr;


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
	trn_tstr					<= not trn_tstr_n;
   trn_tbuf_av				<= tx_buf_av; -- trn_tbuf_av(FOR TLP OUT SIGNAL NENUGEN) <= tx_buf_av(EST SIGNAL PRIHODIT IZ PCI)






--DWORD Reordering between AXI and TRN interface--

  gen_axis_txdata_64 : if (C_DATA_WIDTH = 64) generate
  begin 
      s_axis_tx_tdata <= trn_td(31 downto 0) & trn_td(63 downto 32);
  end generate;
  
  gen_axis_txdata_128 : if (C_DATA_WIDTH = 128) generate
  begin 
      s_axis_tx_tdata <= trn_td(31 downto  0) & trn_td( 63 downto 32) &
                         trn_td(95 downto 64) & trn_td(127 downto 96);
  end generate;
  
  
  --Coversion from trn_rem to s_axis_tkeep[7:0]--
  
  
  gen_axis_tx_tkeep_64 : if (C_DATA_WIDTH = 64) generate
  begin
  
    CMB_STRB_MUX : process(trn_teof,trn_trem)
    begin
      if (trn_teof = '1' and trn_trem(0) = '0') then
        s_axis_tx_tkeep <= X"0F";
      else
        s_axis_tx_tkeep <= X"FF";
      end if;
    end process;
                       
  end generate;
  
  
  gen_axis_tx_tkeep_128 : if (C_DATA_WIDTH = 128) generate
  begin
   
    CMB_STRB_MUX : process(trn_teof,trn_trem)
    begin
      if trn_teof = '1' then
        if trn_trem = "11" then
          s_axis_tx_tkeep <= X"FFFF";
        elsif trn_trem = "10" then
          s_axis_tx_tkeep <= X"0FFF";
        elsif trn_trem = "01" then
          s_axis_tx_tkeep <= X"00FF";
        else
          s_axis_tx_tkeep <= X"000F";
        end if;  
      else
        s_axis_tx_tkeep <= X"FFFF";
      end if;
    end process;
    
  end generate;
  
  
  
  --Connection of s_axis_tx_tuser with  trn_tsrc_dsc,trn_tstr,trn_terr_fwd and trn_terr_fwd
  s_axis_tx_tuser(3) <= trn_tsrc_dsc; 
  s_axis_tx_tuser(2) <= trn_tstr;
  s_axis_tx_tuser(1) <= trn_terrfwd;
  s_axis_tx_tuser(0) <= trn_tecrc_gen;
  
  --Constraint trn_tsrc_rdy. If constrained, testbench keep trn_tsrc_rdy constantly asserted. This makes axi bridge to generate trn_tsof immeditely after trn_teof of previous packet.--
  
   TRN_TSRC_RDY_DRVD : process(trn_tsof,trn_tsrc_rdy,trn_tdst_rdy_int,trn_teof,trn_tsrc_rdy_derived)
   begin
     
       if (trn_tsof  = '1' and trn_tsrc_rdy = '1' and trn_tdst_rdy_int = '1' and trn_teof = '0') then
         trn_tsrc_rdy_derived <= '1';
       elsif (trn_tsrc_rdy_derived = '1' and trn_teof = '1' and trn_tsrc_rdy = '1' and trn_tdst_rdy_int = '1') then 
         trn_tsrc_rdy_derived <= '0';
       end if;
   end process;
  
  s_axis_tx_tvalid <= trn_tsrc_rdy_derived or trn_tsof or trn_teof;
  
  trn_tdst_rdy         <= s_axis_tx_tready; -- add _i
  trn_tdst_rdy_int     <= s_axis_tx_tready; -- add _i
                       
  s_axis_tx_tlast      <= trn_teof;
  
  m_axis_rx_tready     <= trn_rdst_rdy;--POHOGE ZADERGKA
  m_axis_rx_tready_int <= trn_rdst_rdy;
  
    
  
  gen_trn_rd_64 : if (C_DATA_WIDTH = 64) generate
  begin 
    trn_rd <= m_axis_rx_tdata( 31 downto  0) & m_axis_rx_tdata( 63 downto 32);
  end generate;
    
  gen_trn_rd_128 : if (C_DATA_WIDTH = 128) generate
  begin
    trn_rd <= m_axis_rx_tdata( 31 downto  0) & m_axis_rx_tdata( 63 downto 32) & 
              m_axis_rx_tdata( 95 downto 64) & m_axis_rx_tdata(127 downto 96);
  end generate;
  
  --Regenerate trn_rsof
  --Used clock. Latency may have been added
  
  
  gen_trn_rsof_64 : if (C_DATA_WIDTH = 64) generate
  begin
  
    in_pckt_register : process(trn_clk)
    begin
      if rising_edge(trn_clk) then
        if user_reset = '1' then -- Add user_reset (_q)
          in_packet_reg <= '0';
        elsif (m_axis_rx_tvalid = '1' and m_axis_rx_tready_int = '1') then
          in_packet_reg <= not(m_axis_rx_tlast);
        end if;
      end if;
    end process;
  
    trn_rsof <= m_axis_rx_tvalid and not(in_packet_reg);
  
  end generate;
  
  gen_trn_rsof_128 : if (C_DATA_WIDTH = 128) generate
  begin
  
    trn_rsof <= m_axis_rx_tuser(14);
  
  end generate;
  
  
  
  
  gen_trn_reof_64 : if (C_DATA_WIDTH = 64) generate
  begin
  
    trn_reof <= m_axis_rx_tlast;
  
  end generate;
  
  gen_trn_reof_128 : if (C_DATA_WIDTH = 128) generate
  begin
  
    trn_reof <= m_axis_rx_tuser(21); --is_eof(4);
  
  end generate;
  
  trn_rsrc_rdy <= m_axis_rx_tvalid;
  
  
  --Regenerate trn_rsrc_dsc
  --Used clock. Latency may have been added
  trn_rsrc_dsc_reg : process(trn_clk)
  begin
  
    if rising_edge(trn_clk) then
      if user_reset = '1' then -- add _q
        trn_rsrc_dsc <= '1';     
      else
        trn_rsrc_dsc <= not(user_lnk_up); -- add _q
      end if;
    end if;
  end process;
    
  
  is_sof <= m_axis_rx_tuser(14 downto 10);
  is_eof <= m_axis_rx_tuser(21 downto 17);
  
  
  gen_trn_rrem_64 : if (C_DATA_WIDTH = 64) generate
  begin
                   
    CMB_TRN_RREM : process(m_axis_rx_tlast,m_axis_rx_tkeep)
    begin
      if (m_axis_rx_tlast = '1') then
        if ( m_axis_rx_tkeep = X"FF") then
          trn_rrem(0) <= '1';
        else
          trn_rrem(0) <= '0';
        end if;
      else
       trn_rrem(0) <= '1';
      end if;
    end process;                
  end generate;
  
  gen_trn_rrem_128 : if (C_DATA_WIDTH = 128) generate
  begin
    
    trn_rrem(0) <= is_eof(2);
    
    CMB_TRN_RREM : process(is_eof,is_sof)
    begin
      if (is_eof(4) = '1'  or is_sof(4) = '1') then
      
        trn_rrem(1) <= ((     is_sof(4 ) and      is_eof(4)  and      is_eof(3) ) or
                        ((not is_sof(4)) and      is_eof(4)  and      is_eof(3) ) or
                        (     is_sof(4)  and (not is_eof(4)) and (not is_sof(3))));
      else
        trn_rrem(1) <= '1';
      end if;  
    end process;      
  end generate;  
  
  trn_rerrfwd <= m_axis_rx_tuser(1);

trn_rbar_hit <= m_axis_rx_tuser(8 downto 2);

end Behavioral; 

