 program field_table_read

 use hold_read

 implicit none

 character(len=100),dimension(:),allocatable :: field_names_tracers
 integer :: num_fields_tracers=0

 integer ::EXPECTED_NUM_FIELDS_TRACERS=10

 print*,'Starting test of read_field_table routine.'

 call read_field_table(num_fields_tracers, field_names_tracers)

 if (EXPECTED_NUM_FIELDS_TRACERS /= num_fields_tracers) stop 2

 deallocate(field_names_tracers)

 print*,'OK'

 print*,'SUCCESS!'

 end program field_table_read
