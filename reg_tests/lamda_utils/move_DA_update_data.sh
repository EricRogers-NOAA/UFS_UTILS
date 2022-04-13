#!/bin/bash

#--------------------------------------------------------------------------
# Run move_DA_update_data with C96 input
#--------------------------------------------------------------------------

set -x

cd $DATA

# Input first guess in orig sized restart file
cp $HOMEreg/input_data/fv_core.res.tile1.nc .
cp $HOMEreg/input_data/fv_tracer.res.tile1.nc .
# Input analysis in larger restart files w/added haloes
cp $HOMEreg/input_data/fv_core.res.tile1_new.nc .
cp $HOMEreg/input_data/fv_tracer.res.tile1_new.nc .
# Input original bndy file
cp $HOMEreg/input_data/gfs_bndy.tile7.000.nc .

NCCMP=${NCCMP:-$(which nccmp)}

#Run the move_DA_create_data code

$HOMEgfs/exec/move_DA_update_data 000

iret=$?
if [ $iret -ne 0 ]; then
  set +x
  echo "<<< MOVE_DA_UPDATE_DATA FAILED. <<<"
  echo "<<< MOVE_DA_UPDATE_DATA TEST FAILED. <<<"  > ./summary.log
  exit $iret
fi

test_bc_failed=0

$NCCMP -dmfqS ${DATA}/gfs_bndy.tile7.000_gsi.nc $HOMEreg/baseline_data/gfs_bndy.tile7.000_gsi.nc
##cmp ${DATA}/gfs_bndy.tile7.000_gsi.nc $HOMEreg/baseline_data/gfs_bndy.tile7.000_gsi.nc
iret_bc=$?
if [ $iret_bc -ne 0 ]; then
  test_bc_failed=1
fi

set +x
if [ $test_bc_failed -ne 0 ]; then
  echo
  echo "*********************************"
  echo "<<< MOVE_DA_UPDATE_DATA TEST FAILED. >>>"
  echo "*********************************"
  echo "<<< MOVE_DA_UPDATE_DATA TEST FAILED. >>>" > ./summary.log
  if [ "$UPDATE_BASELINE" = "TRUE" ]; then
    cd $DATA
    $HOMEgfs/reg_tests/update_baseline.sh $HOMEreg "lamda_utils" $commit_num
  fi
else
  echo
  echo "*********************************"
  echo "<<< MOVE_DA_UPDATE_DATA TEST PASSED. >>>"
  echo "*********************************"
  echo "<<< MOVE_DA_UPDATE_DATA TEST PASSED. >>>" > ./summary.log
fi

exit
