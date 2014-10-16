#!/bin/sh

# Clean up the results directory
rm -rf results
mkdir results

#Synthesize the Wrapper Files
echo 'Synthesizing example design with XST';
xst -ifn xilinx_pcie_2_1_ep_7x.xst -ofn xilinx_pcie_2_1_ep_7x.log

cp xilinx_pcie_2_1_ep_7x.ngc ./results/

cp xilinx_pcie_2_1_ep_7x.log xst.srp

rm -rf *.mgo xlnx_auto_0_xdb xlnx_auto_0.ise netlist.lst smart

cd results

echo 'Running ngdbuild'
ngdbuild -verbose -uc ../../example_design/xilinx_pcie_2_1_ep_7x_04_lane_gen1_xc7a200t-fbg676-2_AC701.ucf xilinx_pcie_2_1_ep_7x.ngc -sd .


echo 'Running map'
map -w \
  -o mapped.ncd \
  xilinx_pcie_2_1_ep_7x.ngd \
  mapped.pcf

echo 'Running par'
par \
  -w mapped.ncd \
  routed.ncd \
  mapped.pcf

echo 'Running trce'
trce -u -e 100 \
  routed.ncd \
  mapped.pcf

echo 'Running design through netgen'
netgen -sim -ofmt vhdl -w -tm xilinx_pcie_2_1_ep_7x routed.ncd

echo 'Running design through bitgen'
# Running Bitgen on Standard PCIe Implementation
bitgen -w routed.ncd

 
