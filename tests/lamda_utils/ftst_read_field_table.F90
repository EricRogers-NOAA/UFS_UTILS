 program field_table_read

 use hold_read

 implicit none

! This code reads the RRFS field_table for Thompson MP (10 tracers)
! Read imp_physics from input.nml. If it is not =8 (setting for 
! Thompson MP) the test fails. If imp_physics=8 but the number
! of tracers is not 10, the test fails.

 character(len=100),dimension(:),allocatable :: field_names_tracers
 integer :: num_fields_tracers=0
 integer :: mp_value

 integer ::EXPECTED_NUM_FIELDS_TRACERS=10
 integer ::IMP_PHYSICS_THOMP=8

 print*,'Starting test of read_field_table routine.'

 call extract_from_namelist('imp_physics',mp_value)

 call read_field_table(num_fields_tracers, field_names_tracers)

 print*, mp_value, num_fields_tracers

 if (EXPECTED_NUM_FIELDS_TRACERS /= num_fields_tracers) stop 2
 if (IMP_PHYSICS_THOMP /= mp_value) stop 3
 if (mp_value == 8) then
   if (num_fields_tracers /= EXPECTED_NUM_FIELDS_TRACERS) stop 4
 endif

 deallocate(field_names_tracers)

 print*,'OK'

 print*,'SUCCESS!'

 end program field_table_read
