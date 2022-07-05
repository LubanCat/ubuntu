#!/bin/bash

DDR_DIR=/rockchip-test/ddr

RESULT_DIR=/rockchip-test/ddr
RESULT_LOG=${RESULT_DIR}/memtester.log

#run memtester test
echo "**********************DDR MEMTESTER TEST****************************"
echo "**********************run: memtester 128M***************************"
echo "**********************DDR MEMTESTER TEST****************************"
memtester 128M 2>&1 | tee $RESULT_LOG &

echo "***DDR MEMTESTER TEST START: you can see the log at $RESULT_LOG*****"
