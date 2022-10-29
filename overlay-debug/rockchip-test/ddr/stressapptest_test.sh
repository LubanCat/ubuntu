#!/bin/bash

DDR_DIR=/rockchip-test/ddr
RESULT_DIR=/rockchip-test/ddr
RESULT_LOG=${RESULT_DIR}/stressapptest.log

#run stressapptest_test
echo "**********************DDR STRESSAPPTEST TEST 48H*************************"
echo "***run: stressapptest -s 172800 -i 4 -C 4 -W --stop_on_errors -M 128*****"
echo "**********************DDR STRESSAPPTEST TEST****************************"
stressapptest -s 172800 -i 4 -C 4 -W --stop_on_errors -M 128 -l $RESULT_LOG &

echo "******DDR STRESSAPPTEST START: you can see the log at $RESULT_LOG********"
