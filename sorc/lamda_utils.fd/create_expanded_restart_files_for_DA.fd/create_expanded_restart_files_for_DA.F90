!> @file
!! @brief The code reads input.nml to get nx,ny,nz and field_table to get
!! number of tracers in the fv_tracer restart file
!! @authors Tom Black, Eric Rogers NCEP/EMC

!> Reads input.nml file to get LAM grid dimensions and field_table
!! to get the number of tracers for this code to create empty fv_core
!! and fv_tracer restart files with larger dimensions (extra boundary
!! rows). This code runs before the LAM model execution in the DA cycle,
!! and is part of the procedure to put the GSI analysis into the
!! the 00-h LAM boundary condition file. These empty fv_tracer, fv_core
!! are copied into the RESTART directory at model run time, and are
!! populated with valid values at the end of the LAM forecast
!! if write_restart_with_bcs = true in the input.nml file.
!!
!! Input : input.nml, field_table
!! Output : fv_core.res.tile1_new.nc, fv_tracer.res.tile1_new.nc
!!          (empty files with larger dimensions, to be copied into
!!           ./RESTART directory before LAM model execution)
!!
!! @return 0 for success, error code otherwise
!! @authors Tom Black, Eric Rogers NCEP/EMC

      program restart_files_for_regional_DA
!
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!***  The regional DA includes boundary rows in the core and tracers
!***  restart files.  Create those enlarged files.  The names of the
!***  core restart fields are hardwired.  The names of the tracers
!***  are read from the field_table file.
!-----------------------------------------------------------------------
!
      use netcdf
      use hold_read,only : read_field_table, extract_from_namelist
!
!-----------------------------------------------------------------------
      implicit none
!-----------------------------------------------------------------------
!
      integer,parameter :: num_dims_core=6                              &  !< # of dimensions in the core restart file
                          ,num_dims_tracers=4                           &  !< # of dimensions in tracer restart file
                          ,num_fields_core=7                               !< # of fields in the core restart file
!
      integer,parameter :: halo=3                                          !< # of halo rows used by the integration
!
      integer :: num_fields_tracers=0                                      !< Initialize tracer counter array 
!
      integer :: i,iend_new,istart_new,j,jend_new,jstart_new,k,kend     &  !< Array start/end indices for i,j,k
                ,kount,npx,npy,npz                                         !! npx=#W-E points, npy=#S-N points, npz=#vertical levels
!
      integer :: dimid,n,na,nd,ndims,nctype,nvars,var_id                   !< dimid: dimensions of original restart files        
                                                                           !! n: do loop counter for num_dims_core                
                                                                           !! var_id: variable counter number for fv_core variables  
!
      integer :: ncid_core_new,ncid_tracer_new                             !< ncid_core_new: counter for variables in new fv_core file
                                                                           !! ncid_tracer_new: counter for variables in new fv_tracers file 
!     integer :: nf90_netcdf4
!
      integer :: ichunk,jchunk,kchunk
!
      integer,dimension(1:num_dims_core) :: dim_lengths_core               !< Hold the dimension lengths for the core restart file
      integer,dimension(1:num_dims_tracers) :: dim_lengths_tracers         !< Hold the dimension lengths for the tracers restart file
!
      integer,dimension(:),allocatable :: dimids                           !< Dimensions of larger restart files                      
!
!     real,dimension(:,:),allocatable :: field 
!
      character(len=50) :: filename_core_restart_new='fv_core.res.tile1_new.nc'    & !< The new core restart file with boundary rows.
                          ,filename_tracer_restart_new='fv_tracer.res.tile1_new.nc'  !< The new tracer restart file with boundary rows.
!
      character(len=9),dimension(num_dims_core) :: dim_names_core=(/           &
                                                                    'xaxis_1'  &  !< npx-1
                                                                   ,'xaxis_2'  &  !< npx
                                                                   ,'yaxis_1'  &  !< npy
                                                                   ,'yaxis_2'  &  !< npy-1
                                                                   ,'zaxis_1'  &  !< npz
                                                                   ,'Time   '  &  !< Time array, always 1
                                                                   /)
!
      character(len=9),dimension(num_dims_tracers) :: dim_names_tracers=(/           &
                                                                          'xaxis_1'  &  !< npx-1
                                                                         ,'yaxis_1'  &  !< npy-1
                                                                         ,'zaxis_1'  &  !< npz
                                                                         ,'Time   '  &  !< Time array, always 1
                                                                         /)
!
      character(len=4),dimension(1:num_fields_core) :: field_names_core=(/        &     !< Names of variables in fv_core file
                                                                          'u   '  &     !! u: u-component of wind
                                                                         ,'v   '  &     !! v: v-component of wind
                                                                         ,'W   '  &     !! W: vertical motion (dz/dt)
                                                                         ,'DZ  '  &     !! DZ: thickness of layers (in meters)
                                                                         ,'T   '  &     !! T: Temperatures
                                                                         ,'delp'  &     !! delp: pressure thickness of layers
                                                                         ,'phis'  &     !! Geopotential of the surface
                                                                         /)
!
      character(len=100),dimension(:),allocatable :: field_names_tracers                !< Array with names of tracers
!
!-----------------------------------------------------------------------
!***********************************************************************
!-----------------------------------------------------------------------
!
!-----------------------------------------------------------------------
!***  Create the enlarged core and tracer restart files that contain
!***  the fields' boundary rows.
!-----------------------------------------------------------------------
!
!-----------------------------------------------------------------------
!***  Begin with the core restart file.  It is assumed that the core
!***  variables will not change therefore they are hardwired.
!-----------------------------------------------------------------------
!
      call check(nf90_create(path =filename_core_restart_new            &  !<-- Create the new core restart file.
       ,cmode=ior(ior(nf90_clobber,nf90_netcdf4),nf90_classic_model)    &
!      ,cmode=ior(nf90_clobber,nf90_netcdf4),                           &
       ,ncid =ncid_core_new))
!
!-----------------------------------------------------------------------
!***  Increase the lateral dimensions' extents to include the 
!***  boundary rows and insert all dimensions into the new core 
!***  restart file.  We extract the value of npx, npy, npz from 
!***  the model's namelist file (input.nml).
!-----------------------------------------------------------------------
!
      call extract_from_namelist('npx',npx)
      call extract_from_namelist('npy',npy)
      call extract_from_namelist('npz',npz)
!
      dim_lengths_core(1)=npx-1+2*halo
      dim_lengths_core(2)=npx+2*halo
      dim_lengths_core(3)=npy+2*halo
      dim_lengths_core(4)=npy-1+2*halo
      dim_lengths_core(5)=npz
      dim_lengths_core(6)=nf90_unlimited                                   !-- Time
      ichunk=dim_lengths_core(1)
      jchunk=dim_lengths_core(4)
      kchunk=npz
      write(0,*)' npx=',npx,' npy=',npy,' npz=',npz
!
      do n=1,num_dims_core
        call check(nf90_def_dim(ncid =ncid_core_new                     &
                               ,name =dim_names_core(n)                 &
                               ,len  =dim_lengths_core(n)               &
                               ,dimid=dimid))
      enddo
!
!-----------------------------------------------------------------------
!***  The new file's variables must be defined while that file
!***  is still in define mode.  Define each of the core restart 
!***  file's variables in the new file.  Start with the dimensions.
!-----------------------------------------------------------------------
!
      allocate(dimids(1:1))
!
      do n=1,num_dims_core
        dimids(1)=n
        call check(nf90_def_var(ncid  =ncid_core_new                    &
                               ,name  =dim_names_core(n)                &
                               ,xtype =NF90_FLOAT                       &
                               ,dimids=dimids                           &
                               ,varid =var_id                           &
                               ))
      enddo
!
      deallocate(dimids)
!
!-----------------------------------------------------------------------
!***  Now do the core restart fields.  Loop through all of them
!***  except phis which is 2-D; handle it in the end.
!-----------------------------------------------------------------------
!
      kount=0
      allocate(dimids(1:4))
      dimids(1)=1
      dimids(2)=4
      dimids(3)=5
      dimids(4)=6
!
      do n=num_dims_core+1,num_dims_core+num_fields_core-1                 !-- Begin after the dimension variables.
        kount=kount+1
        if(field_names_core(kount)=='u')then
          dimids(2)=3
        endif
        if(field_names_core(kount)=='v')then
          dimids(1)=2
        endif
        call check(nf90_def_var(ncid  =ncid_core_new                    &                 
                               ,name  =field_names_core(kount)          &
                               ,xtype =NF90_FLOAT                       &
                               ,dimids=dimids(1:4)                      &
                               ,varid =var_id                           &
                               ,chunksizes=(/ichunk,jchunk,kchunk,1/)   &
                               ))
        dimids(1)=1
        dimids(2)=4
      enddo
!
!     var_id=num_dims_core+num_fields_core                                 !-- ID for phis
      dimids(1)=1
      dimids(2)=4
      dimids(3)=6
!
      call check(nf90_def_var(ncid  =ncid_core_new                      &                 
                             ,name  ='phis'                             &
                             ,xtype =NF90_FLOAT                         &
                             ,dimids=dimids(1:3)                        &
                             ,varid =var_id                             &
                             ,chunksizes=(/ichunk,jchunk,1/)            &
                             ))
!
      call check(nf90_enddef(ncid_core_new))                               !-- Terminate the define mode for the file.
      deallocate(dimids)
!
!-----------------------------------------------------------------------
!***  Next prepare the new tracer restart file with boundary rows.
!-----------------------------------------------------------------------
!
      call check(nf90_create(path =filename_tracer_restart_new          &  !-- Create the new tracer restart file.
       ,cmode=ior(ior(nf90_clobber,nf90_netcdf4),nf90_classic_model)    &
       ,ncid=ncid_tracer_new))
!
!-----------------------------------------------------------------------
!***  Increase the lateral dimensions' extents to include the 
!***  boundary rows and insert all dimensions into the new  
!***  tracer restart file.  All tracers are 3-D and located in
!***  the centers of grid cells.
!-----------------------------------------------------------------------
!
      dim_lengths_tracers(1)=npx-1+2*halo
      dim_lengths_tracers(2)=npy-1+2*halo
      dim_lengths_tracers(3)=npz
      dim_lengths_tracers(4)=nf90_unlimited                                !-- Time
!
      do n=1,num_dims_tracers
        call check(nf90_def_dim(ncid =ncid_tracer_new                   &
                               ,name =dim_names_tracers(n)              &
                               ,len  =dim_lengths_tracers(n)            &
                               ,dimid=dimid))
      enddo
!
!-----------------------------------------------------------------------
!***  The new file's variables must be defined while that file
!***  is still in define mode.  Define each of the tracer restart 
!***  file's variables in the new file.  Start with the dimensions.
!-----------------------------------------------------------------------
!
      allocate(dimids(1:1))
!
      do n=1,num_dims_tracers
        dimids(1)=n
        call check(nf90_def_var(ncid  =ncid_tracer_new                  &
                               ,name  =dim_names_tracers(n)             &
                               ,xtype =NF90_FLOAT                       &
                               ,dimids=dimids                           &
                               ,varid =var_id                           &
                               ))
      enddo
!
      deallocate(dimids)
!
!-----------------------------------------------------------------------
!***  Now do the tracer restart fields.  Collect the names of the
!***  tracer fields.  This is done by reading the field_table.
!-----------------------------------------------------------------------
!
      call read_field_table(num_fields_tracers,field_names_tracers)
!
      kount=0
      allocate(dimids(1:4))
      dimids(1)=1
      dimids(2)=2
      dimids(3)=3
      dimids(4)=4
!
      do n=num_dims_tracers+1,num_dims_tracers+num_fields_tracers          !- Begin after the dimension variables.
        kount=kount+1
        call check(nf90_def_var(ncid  =ncid_tracer_new                  &                 
                               ,name  =field_names_tracers(kount)       &
                               ,xtype =NF90_FLOAT                       &
                               ,dimids=dimids(1:4)                      &
                               ,varid =var_id                           &
                               ,chunksizes=(/ichunk,jchunk,kchunk,1/)   &
                               ))
      enddo
!
      call check(nf90_enddef(ncid_tracer_new))                             !- Terminate the define mode of the file.
      deallocate(dimids)
!
!-----------------------------------------------------------------------
!
      contains
!
!-----------------------------------------------------------------------
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
!-----------------------------------------------------------------------
!
!> This routine returns the status of a netcdf file
!!
!! @param[in] status  netcdf file status
!! @authors Tom Black, Eric Rogers NCEP/EMC

      subroutine check(status)
!
      integer,intent(in) :: status                   !< netcdf file status
!
      if(status /= nf90_noerr) then
        print *, trim(nf90_strerror(status))
        stop "Stop with NetCDF error"
      end if
!
      end subroutine check
!
!-----------------------------------------------------------------------
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
!-----------------------------------------------------------------------
!
      end program restart_files_for_regional_DA
!
!---------------------------------------------------------------------
