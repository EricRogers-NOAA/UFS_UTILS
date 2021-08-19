 program check_grid_sfc

 use netcdf
 use hold_check

 implicit none

! This reads a 20x20 grid_spec.nc and sfc_data.nc file extracted
! from a 3 km RRFS domain run and checks to see if it has the
! the expected number of dimensions and variables 
! Test fails if it doesn't.

 integer,parameter :: double=selected_real_kind(p=13,r=200)
 integer,parameter :: expected_ndims_sfc=5    
 integer,parameter :: expected_nvars_sfc=71   
 integer,parameter :: expected_ndims_grid=5
 integer,parameter :: expected_nvars_grid=10
 integer :: ncid_grid,ncid_sfc,nf_64bit_offset
 integer :: actual_ndims_sfc,actual_ndims_grid
 integer :: actual_nvars_sfc,actual_nvars_grid
 integer :: unlimdimid,ngatts,status

 character(len=20) :: filename_sfc_data='sfc_data.nc'    
 character(len=20) :: filename_grid_spec='grid_spec.nc'

 call check(nf90_open(filename_sfc_data,nf90_nowrite,ncid_sfc))
 status=nf90_inquire(ncid_sfc,actual_ndims_sfc,actual_nvars_sfc,ngatts   &
                    ,unlimdimid)
 print *,actual_ndims_sfc,actual_nvars_sfc,ngatts

 call check(nf90_open(filename_grid_spec,nf90_nowrite,ncid_grid))
 status=nf90_inquire(ncid_grid,actual_ndims_grid,actual_nvars_grid,ngatts   &
                    ,unlimdimid)
 print *,actual_ndims_grid,actual_nvars_grid,ngatts

 if (actual_ndims_sfc /= expected_ndims_sfc) stop 2
 if (actual_ndims_grid /= expected_ndims_grid) stop 3
 if (actual_nvars_sfc /= expected_nvars_sfc) stop 4
 if (actual_nvars_grid /= expected_nvars_grid) stop 5

 print*,'OK'

 print*,'SUCCESS!'

 end program check_grid_sfc
