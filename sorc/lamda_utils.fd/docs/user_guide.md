
# lamda_utils

# Introduction

The lamda_utils codes that run during the LAM DA to put the GSI anl into
the 00-h bndy condition file for the LAMDA forecast. They consist of:
* create_expanded_restart_files_for_DA.F90 - runs before LAM forecast;
  make empty "larger" LAM restart files (fv_core and fv_tracer) with 
  extra boundary rows, which filled in during LAM model execution
* prep_for_regional_DA.F90 - runs after LAM forecast; makes larger 
  sfc_data.nc and grid_spec.nc files with extra boundary rows 
* move_DA_update_data.F90 - runs after LAM GSI analysis; creates new 
  boundary file with GSI analysis

This document is part of the <a href="../index.html">UFS_UTILS
documentation</a>.

The lamda_utils programs are part of the [NCEPLIBS
UFS_UTILS](https://github.com/NOAA-EMC/UFS_UTILS) project.



