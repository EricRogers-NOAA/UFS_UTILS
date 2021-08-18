!> @file
!
!! @brief The module contains the routines that read input.nml 
!! to get nx,ny,nz and field_table to get
!! number of tracers in the fv_tracer restart file
!! @authors Tom Black, Eric Rogers NCEP/EMC

!> This module reads the input.nml and field_table files to get a list of
!! the number of tracers used and the dimensions of the LAM grid
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
      public :: read_field_table, extract_from_namelist
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
!
      end module hold_read
