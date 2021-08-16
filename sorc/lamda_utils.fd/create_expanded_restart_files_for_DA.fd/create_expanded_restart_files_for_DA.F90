!> @file
!
!! @brief The code reads input.nml to get nx,ny,nz and field_table to get
!! number of tracers in the fv_tracer restart file
!! @authors Tom Black, Eric Rogers NCEP/EMC

!> This module reads the field_table to get a list of
!! the number of tracers used.
!!
!! @authors Tom Black, Eric Rogers NCEP/EMC
!-----------------------------------------------------------------------
!
      module hold_read
!
!-----------------------------------------------------------------------
!
      private
!
      public :: read_field_table
!
!-----------------------------------------------------------------------
!
      contains
!
!-----------------------------------------------------------------------
!

!> This routine does simple reads of field_table to get 
!! the number of tracers in the fv_tracer restart file.
!!
!! @param[out] num_fields_tracers  Number of tracer arrays
!! @param[in] field_names_tracers  Names of tracers
!!
!! @authors Tom Black, Eric Rogers NCEP/EMC

      subroutine read_field_table(num_fields_tracers,field_names_tracers)
!
!-----------------------------------------------------------------------
!***  Do simple reads of the field_table to get a list of the 
!***  tracers present in the given forecast.
!-----------------------------------------------------------------------
!
!-----------------------------------------------------------------------
      implicit none
!-----------------------------------------------------------------------
!
!------------------------
!***  Argument variables
!------------------------
!
      character(len=100),dimension(:),allocatable,intent(inout) :: field_names_tracers !< Names of tracers
!
      integer,intent(out) :: num_fields_tracers !< Number of tracer arrays from field_table        
!
!---------------------
!***  Local variables
!---------------------
!
      integer :: ierr,kount,n,n_end,n_start !< ierr : error condition
                                            !! kount : counting variable for # of tracers               
                                            !! n,n_nstart,n_end : Variables for # characters in variable name                 
!
      character(len=100) :: line,line_name !< Parsing variables for reading field_table              
!
!-----------------------------------------------------------------------
!***********************************************************************
!-----------------------------------------------------------------------
!
      open(unit=20,file='field_table',status='OLD')
      kount=0
!
!-----------------------------------------------------------------------
!***  We will read the field_table twice.  The total number of
!***  tracers is not known at first so the first read will
!***  determine the count.  Then the array holding the tracer
!***  names can be allocated.  The file is read a 2nd time to
!***  collect those names.  This is cleaner than doing a single
!***  read and collecting the names in a very large pre-allocated
!***  array and simpler than doing a single read and building a 
!***  linked list to pass back.
!-----------------------------------------------------------------------
!
      do
        read(unit=20,fmt='(A100)',iostat=ierr)line
        if(ierr/=0)then
!         write(0,101)
  101     format(' Reached the end of the field_table.')
          exit
        endif
!
        if(index(line,'TRACER')/=0)then                                    !<-- Find lines with tracer names.
          kount=kount+1                                                    !<-- We found a tracer name; increment the counter.
        endif
      enddo
!
      num_fields_tracers=kount                                             !<-- The total number of tracers.
      write(0,102)num_fields_tracers
  102 format(' There are ',i3,' tracers in the field_table.')
!
      allocate(field_names_tracers(1:num_fields_tracers))
!
      rewind 20
      kount=0
!
      do 
        read(unit=20,fmt='(A100)',iostat=ierr)line
        line=adjustl(line)                            
        if(line(1:1)=='#')then
          cycle                                                            !<-- Skip lines that are commented out.
        endif
        if(index(line,'TRACER')/=0)then                                    !<-- Find lines with tracer names.
          kount=kount+1
          n_start=index(line,',',.true.)                                   !<-- Find the final comma (precedes the name).
          line_name=line(n_start+1:)                                       !<-- Collect everything after that comma.
          n_start=index(line_name,'"')                                     !<-- Double quotes precede the field name.
          line_name=line_name(n_start+1:)                                  !<-- Remove the leading quotes.
          n_end=index(line_name,'"')                                       !<-- Double quotes follow the field name.
          line_name=line_name(1:n_end-1)                                   !<-- Remove the trailing quotes.
          field_names_tracers(kount)=line_name
          write(0,103)kount,trim(line_name)
  103     format(' tracer ',i3,' is ',a)
          if(kount==num_fields_tracers)then
            exit
          endif
        endif
      enddo
!
      close(20)
!
!-----------------------------------------------------------------------
!
      end subroutine read_field_table
!
!-----------------------------------------------------------------------
!
      end module hold_read
!
!-----------------------------------------------------------------------
!-----------------------------------------------------------------------
!
!! @brief Read input.nml to get nx,ny,nz and field_table to get
!! number of tracers in fv_tracer restart file
!! @authors Tom Black, Eric Rogers NCEP/EMC

!> Reads input.nml file to get LAM grid dimensions and field_table
!! to get the number of tracers for this code to create empty fv_core
!! and fv_tracer restart files with larger dimensions (extra boundary
!! rows). This code runs before the LAM model execution in the DA cycle,
!! and is part of the  procedure to put the GSI analysis into the
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
      use hold_read,only : read_field_table
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
                            ,cmode=or(nf90_clobber,nf90_64bit_offset)   &
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
      dim_lengths_core(6)=nf90_unlimited                                   !<-- Time
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
      do n=num_dims_core+1,num_dims_core+num_fields_core-1                 !<-- Begin after the dimension variables.
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
                               ))
        dimids(1)=1
        dimids(2)=4
      enddo
!
!     var_id=num_dims_core+num_fields_core                                 !<-- ID for phis
      dimids(1)=1
      dimids(2)=4
      dimids(3)=6
!
      call check(nf90_def_var(ncid  =ncid_core_new                      &                 
                             ,name  ='phis'                             &
                             ,xtype =NF90_FLOAT                         &
                             ,dimids=dimids(1:3)                        &
                             ,varid =var_id                             &
                             ))
!
      call check(nf90_enddef(ncid_core_new))                               !<-- Terminate the define mode for the file.
      deallocate(dimids)
!
!-----------------------------------------------------------------------
!***  Next prepare the new tracer restart file with boundary rows.
!-----------------------------------------------------------------------
!
      call check(nf90_create(path =filename_tracer_restart_new          &  !<-- Create the new tracer restart file.
                            ,cmode=or(nf90_clobber,nf90_64bit_offset)   &
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
      dim_lengths_tracers(4)=nf90_unlimited                                !<-- Time
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
      do n=num_dims_tracers+1,num_dims_tracers+num_fields_tracers          !<-- Begin after the dimension variables.
        kount=kount+1
        call check(nf90_def_var(ncid  =ncid_tracer_new                  &                 
                               ,name  =field_names_tracers(kount)       &
                               ,xtype =NF90_FLOAT                       &
                               ,dimids=dimids(1:4)                      &
                               ,varid =var_id                           &
                               ))
      enddo
!
      call check(nf90_enddef(ncid_tracer_new))                             !<-- Terminate the define mode of the file.
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
!> This routine extracts the grid dimensions from the model 
!! input.nml namelist
!!
!! @param[in] name  Variable name in input.nml file
!! @param[out] value  Variable name setting in input.nml file
!! @authors Tom Black, Eric Rogers NCEP/EMC

      subroutine extract_from_namelist(name,value)
!
!-----------------------------------------------------------------------
!***  We do not want to chase after the changing namelist file
!***  using a Fortran namelist read so simply find the single
!***  integer value of interest.  Of course this can be generalized
!***  if needed using optional arguments for different TYPEs.
!-----------------------------------------------------------------------
!
!------------------------
!***  Argument variables
!------------------------
!
      character(len=*),intent(in) :: name        !< Variable name in input.nml file
!
      integer,intent(out) :: value               !< Variable name setting in input.nml file
!
!---------------------
!***  Local variables
!---------------------
!
      integer :: ierr, n_start                   !< ierr: error condition reading input.nml
                                                 !! nstart: location of equal sign in input.nml line
!
      character(len=100) :: line,line_int        !< line: Line in input.nml file with desired variable                           
                                                 !! (npx, npy, and npz)
                                                 !! line_int: value of desired variable from input.nml file
!
!-----------------------------------------------------------------------
!***********************************************************************
!-----------------------------------------------------------------------
!
      open(unit=20,file='input.nml',status='OLD')
!
      do
        read(unit=20,fmt='(A100)',iostat=ierr)line
!
        line=adjustl(line)
        if(line(1:1)=='!')then
          cycle                                                            !<-- Skip lines that are commented out.
        endif
! 
!       write(0,*)' n_start=',index(line,trim(name)),' line=',trim(line)
        if(index(line,trim(name))/=0)then                                  !<-- Find the line with the desired variable.
          n_start=index(line,'=')                                          !<-- Find the equal sign.
          line_int=line(n_start+1:)                                        !<-- Collect everything after the equal sign.
          exit
        endif
      enddo
!
      line_int=trim(adjustl(line_int))                                     !<-- Isolate the numeral.
!     write(0,*)line_int
      read(line_int,'(I4)')value                                           !<-- Convert the character numeral to an integer.
!
      close(20)
!
!-----------------------------------------------------------------------
!
      end subroutine extract_from_namelist
!
!-----------------------------------------------------------------------
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
!-----------------------------------------------------------------------
!
      end program restart_files_for_regional_DA
!
!---------------------------------------------------------------------
