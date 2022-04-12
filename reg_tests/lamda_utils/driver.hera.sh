#!/bin/bash

#-----------------------------------------------------------------------------
#
# Run lamda_utils consistency test for move_DA_update_code on Hera.
#
# Set $DATA to your working directory.  Set the project code (SBATCH -A)
# and queue (SBATCH -q) as appropriate.
#
# Invoke the script as follows:  sbatch $script
#
# Log output is placed in consistency.log.  A summary is
# placed in summary.log
#
# The test fails when its output does not match the baseline file
# as determined by the 'cmp' command.  The baseline file is
# stored in HOMEreg.
#
#-----------------------------------------------------------------------------

#SBATCH -J lamda_utils
#SBATCH -A fv3-cpu
#SBATCH --open-mode=truncate
#SBATCH -o consistency.log
#SBATCH -e consistency.log
#SBATCH --ntasks=1
#SBATCH -q debug
#SBATCH -t 00:03:00

set -x

compiler=${compiler:-"intel"}

source ../../sorc/machine-setup.sh > /dev/null 2>&1
module use ../../modulefiles
module load build.$target.$compiler
module list

export DATA="${WORK_DIR:-/scratch2/NCEPDEV/stmp1/$LOGNAME}"
export DATA="${DATA}/reg-tests/lamda_utils"

#-----------------------------------------------------------------------------
# Should not have to change anything below.
#-----------------------------------------------------------------------------

export UPDATE_BASELINE="FALSE"
#export UPDATE_BASELINE="TRUE"

if [ "$UPDATE_BASELINE" = "TRUE" ]; then
  source ../get_hash.sh
fi

rm -fr $DATA
mkdir -p $DATA

###export HOMEreg=/scratch1/NCEPDEV/nems/role.ufsutils/ufs_utils/reg_tests/snow2mdl
export HOMEreg=/scratch2/NCEPDEV/fv3-cam/noscrub/Eric.Rogers/role.ufsutils/ufs_utils/reg_tests/lamda_utils
export HOMEgfs=$PWD/../..

./move_DA_update_data.sh

exit 0
