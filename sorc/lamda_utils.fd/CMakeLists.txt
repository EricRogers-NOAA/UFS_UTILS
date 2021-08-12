add_subdirectory(create_expanded_restart_files_for_DA.fd)
add_subdirectory(move_DA_update_data.fd)
add_subdirectory(prep_for_regional_DA.fd)

# If doxygen documentation we enabled, build it.
if(ENABLE_DOCS)
  add_subdirectory(docs)
endif()
