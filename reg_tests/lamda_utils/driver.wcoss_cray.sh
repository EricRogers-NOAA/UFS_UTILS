#!/bin/bash

#-----------------------------------------------------------------------------
#
# Run lamda_utils consistency test for move_DA_update_data code on WCOSS-Dell.
#
# Set $DATA to your working directory.  Set the project code (BSUB -P)
# and queue (BSUB -q) as appropriate.
#
# Invoke the script as follows:  cat $script | bsub
##
# Log output is placed in consistency.log.  A summary is
# placed in summary.log
#
# The test fails when its output does not match the baseline file
# as determined by the 'cmp' command.  The baseline file is
# stored in HOMEreg.
#
#-----------------------------------------------------------------------------

#BSUB -W 0:02
#BSUB -o consistency.log
#BSUB -e consistency.log
#BSUB -J lamda_utils_regt
#BSUB -q debug
#BSUB -R "rusage[mem=2000]"
#BSUB -P GFS-DEV

set -x

source ../../sorc/machine-setup.sh > /dev/null 2>&1
module use ../../modulefiles
module load build.$target.intel
module list

export DATA="${WORK_DIR:-/gpfs/hps3/stmp/$LOGNAME}"
export DATA="${DATA}/reg-tests/lamda_utils"

#-----------------------------------------------------------------------------
# Should not have to change anything below.
#-----------------------------------------------------------------------------

export UPDATE_BASELINE="FALSE"
#export UPDATE_BASELINE="TRUE"

if [ "$UPDATE_BASELINE" = "TRUE" ]; then
  source ../get_hash.sh
fi

###export HOMEreg=/gpfs/hps3/emc/global/noscrub/George.Gayno/ufs_utils.git/reg_tests/snow2mdl
export HOMEreg=/gpfs/hps3/emc/meso/noscrub/Eric.Rogers/ufs_utils.git/reg_tests/lamda_utils
export HOMEgfs=$PWD/../..

rm -fr $DATA
mkdir -p $DATA

./move_DA_update_data.sh

exit 0
