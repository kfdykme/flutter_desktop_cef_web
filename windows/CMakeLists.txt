cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "flutter_desktop_cef_web")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "flutter_desktop_cef_web_plugin")

add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/cef") 

add_library(${PLUGIN_NAME} SHARED
  "flutter_desktop_cef_web_plugin.cpp"
  "core/simple_handler.cc"
  "core/simple_app.cc"
  "core/simple_handler_win.cc"
  "core/client_app.cc"
  "core/renderer/client_app_renderer.cc"
  "core/renderer/client_renderer.cc"
)

 
# Logical target used to link the libcef library.
set(CEF_LIBTYPE STATIC)
set(CEF_BINARY_DIR_DEBUG    "${CMAKE_CURRENT_SOURCE_DIR}/cef/Debug")
set(CEF_BINARY_DIR_RELEASE  "${CMAKE_CURRENT_SOURCE_DIR}/cef/Release")
set(CEF_LIB_DEBUG   "${CEF_BINARY_DIR_DEBUG}/libcef.lib")
set(CEF_LIB_RELEASE "${CEF_BINARY_DIR_RELEASE}/libcef.lib")
ADD_LOGICAL_TARGET("libcef_lib" "${CEF_LIB_DEBUG}" "${CEF_LIB_RELEASE}")

include_directories(${PLUGIN_NAME} "${CMAKE_CURRENT_SOURCE_DIR}/cef")

add_dependencies(${PLUGIN_NAME} libcef_dll_wrapper)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/core"
  "${CMAKE_CURRENT_SOURCE_DIR}/cef")

# include_directories (${PLUGIN_NAME} PUBLIC "${CMAKE_CURRENT_SOURCE_DIR}/../cef/windows") 
target_link_libraries(${PLUGIN_NAME} PRIVATE 
flutter 
flutter_wrapper_plugin
libcef_dll_wrapper
libcef_lib
)

# List of CEF binary files.
set(CEF_BINARY_FILES
  chrome-sandbox
  libcef.so
  libEGL.so
  libGLESv2.so
  libvk_swiftshader.so
  libvulkan.so.1
  snapshot_blob.bin
  v8_context_snapshot.bin
  vk_swiftshader_icd.json
  swiftshader
  )

# List of CEF resource files.
set(CEF_RESOURCE_FILES
  chrome_100_percent.pak
  chrome_200_percent.pak
  resources.pak
  icudtl.dat
  locales
  )

set(CEF_BINARY_INSTALL_FROM "")
set(CEF_RESOURCE_INSTALL_FROM "")

foreach(CEF_BINARY_FILES BIN_FILE)
  list(APPEND CEF_BINARY_INSTALL_FROM
  "${CMAKE_CURRENT_SOURCE_DIR}/cef/Release/${BIN_FILE}"   # Used by apps to test if the sandbox is enabled
  )
endforeach()


foreach(CEF_RESOURCE_FILES BES_FILE)
  list(APPEND CEF_RESOURCE_INSTALL_FROM
  "${CMAKE_CURRENT_SOURCE_DIR}/cef/Resources/${BES_FILE}"   # Used by apps to test if the sandbox is enabled
  )
endforeach()


# add cef directory as subdirectory
# List of absolute paths to libraries that should be bundled with the plugin
set(flutter_desktop_cef_web_bundled_libraries
  "${CEF_BINARY_INSTALL_FROM}"
  "${CEF_RESOURCE_INSTALL_FROM}"
  PARENT_SCOPE
)
