!> @file
!
!! @brief Check status of netcdf file

!> This module returns the status of a netcdf file
!! For use in unit tests
!!
!! @authors Tom Black, Eric Rogers NCEP/EMC
!-----------------------------------------------------------------------
!
      module hold_check
!
!-----------------------------------------------------------------------
!
      private
!
      public :: check
!
!-----------------------------------------------------------------------
!
      contains
!
!-----------------------------------------------------------------------
!
!> This routine returns the status of a netcdf file
!!
!! @param[in] status  netcdf file status
!! @authors Tom Black, Eric Rogers NCEP/EMC
      subroutine check(status)
!
      use netcdf
!
      integer,intent(in) :: status
!
      if(status /= nf90_noerr) then
        print *, trim(nf90_strerror(status))
        stop "Stopped"
      end if
!
      end subroutine check
!
!-----------------------------------------------------------------------
!+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
!
      end module hold_check
