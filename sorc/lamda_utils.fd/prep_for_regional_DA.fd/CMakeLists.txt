set(lib_src
    hold_check.F90)

set(exe_src
    prep_for_regional_DA.F90)

if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -g -traceback -fp-model precise -xAVX")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -fdefault-real-8 -fconvert=big-endian -fno-range-check")
endif()

set(exe_name prep_for_regional_DA)

add_library(prep_for_regional_DA_lib STATIC ${lib_src})
add_executable(${exe_name} ${exe_src})

set(mod_dir "${CMAKE_CURRENT_BINARY_DIR}/mod")
set_target_properties(prep_for_regional_DA_lib PROPERTIES Fortran_MODULE_DIRECTORY ${mod_dir})
target_include_directories(prep_for_regional_DA_lib INTERFACE ${mod_dir})

target_link_libraries(
  prep_for_regional_DA_lib
  PUBLIC
  NetCDF::NetCDF_Fortran)

target_link_libraries(${exe_name} PRIVATE prep_for_regional_DA_lib)

install(TARGETS ${exe_name} RUNTIME DESTINATION ${exec_dir})
