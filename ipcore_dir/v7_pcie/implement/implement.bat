rem Clean up the results directory
rmdir /S /Q results
mkdir results

echo 'Synthesizing HDL example design with XST';
xst -ifn xilinx_pcie_2_1_ep_7x.xst -ofn xilinx_pcie_2_1_ep_7x.log
rem xst -ifn xst.scr

copy *.ngc .\results\

copy xilinx_pcie_2_1_ep_7x.log xst.srp

cd results

echo 'Running ngdbuild'
ngdbuild -verbose -uc ../../example_design/xilinx_pcie_2_1_ep_7x_04_lane_gen1_xc7a200t-fbg676-2_AC701.ucf xilinx_pcie_2_1_ep_7x.ngc -sd .

echo 'Running map'
map -w -o mapped.ncd xilinx_pcie_2_1_ep_7x.ngd mapped.pcf

echo 'Running par'
par -w mapped.ncd routed.ncd mapped.pcf

echo 'Running trce'
trce -u -e 100 routed.ncd mapped.pcf

echo 'Running design through netgen'
netgen -sim -ofmt vhdl -w -tm xilinx_pcie_2_1_ep_7x routed.ncd

echo 'Running design through bitgen'

echo 'Generating PROM file for programming'
 
