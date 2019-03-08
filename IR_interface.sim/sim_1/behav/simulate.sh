#!/bin/sh -f
xv_path="/opt/Xilinx/Vivado/2015.2"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep $xv_path/bin/xsim Counter_TB_behav -key {Behavioral:sim_1:Functional:Counter_TB} -tclbatch Counter_TB.tcl -view /home/s1545317/DL4/IR_interface/Counter_TB_behav.wcfg -log simulate.log
