set(fortran_src
    move_DA_update_data.F90)

if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -g -traceback -fp-model precise -xAVX")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fdefault-real-8 -fconvert=big-endian -fno-range-check")
endif()

set(exe_name move_DA_update_data)
add_executable(${exe_name} ${fortran_src})
target_link_libraries(
  ${exe_name}
  NetCDF::NetCDF_Fortran)

install(TARGETS ${exe_name} RUNTIME DESTINATION ${exec_dir})
