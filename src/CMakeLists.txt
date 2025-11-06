# find all dependency libraries:
find_package(OpenMP)
if (NOT OPENMP_FOUND)
	message(WARNING "OpenMP is not found. Will be slow.")
else()
	set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
endif()


# JPEG is optional and not available on mobile platforms
if(NOT ANDROID AND NOT IOS)
	find_package(JPEG)
	if(JPEG_FOUND)
		include_directories(${JPEG_INCLUDE_DIR})
	endif()
else()
	# Disable JPEG on mobile
	add_definitions(-DDISABLE_JPEG)
endif()

# Disable CImg display and system calls on iOS/Android (not available)
if(IOS OR ANDROID)
	add_definitions(-Dcimg_display=0 -Dcimg_no_system_calls)
endif()

# Try to find Eigen3, use bundled if not found or cross-compiling
find_package(Eigen3 QUIET)
if(NOT EIGEN3_FOUND OR CMAKE_CROSSCOMPILING)
    # Use system Eigen3 for macOS (Homebrew install)
    if(APPLE AND NOT IOS)
        set(EIGEN3_INCLUDE_DIRS "/opt/homebrew/include/eigen3" "/usr/local/include/eigen3")
    else()
        # For iOS/Android, assume Eigen3 is available via Homebrew on build machine
        set(EIGEN3_INCLUDE_DIRS "/opt/homebrew/include/eigen3")
    endif()
    message(STATUS "Using Eigen3 from: ${EIGEN3_INCLUDE_DIRS}")
endif()

include_directories(${CMAKE_CURRENT_SOURCE_DIR})
add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/third-party/)

if(EIGEN3_DEFINITIONS)
    add_definitions(${EIGEN3_DEFINITIONS})
endif()
include_directories(${EIGEN3_INCLUDE_DIRS})

# find sources
file(GLOB SOURCES feature/*.cc stitch/*.cc lib/*.cc)


# Main library
add_library(openpano_core STATIC ${SOURCES})

# Link libraries based on platform
if(JPEG_FOUND)
    target_link_libraries(openpano_core PUBLIC ${JPEG_LIBRARY} lodepng)
else()
    target_link_libraries(openpano_core PUBLIC lodepng)
    target_compile_definitions(openpano_core PUBLIC DISABLE_JPEG)
endif()

target_include_directories(openpano_core PUBLIC 
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${EIGEN3_INCLUDE_DIRS}
)

# Android/iOS specific settings
if(ANDROID OR IOS)
    # Eigen3 requires C++14 features
    set_target_properties(openpano_core PROPERTIES
        POSITION_INDEPENDENT_CODE ON
        CXX_STANDARD 14
        CXX_STANDARD_REQUIRED ON
    )
endif()

# C API wrapper
add_subdirectory(c_api)

# Command-line tool
add_executable(image-stitching main.cc)
target_link_libraries(image-stitching openpano_core)

if (NOT JPEG_FOUND)
	target_compile_definitions(image-stitching PUBLIC DISABLE_JPEG)
endif()

# Python bindings (optional)
find_package(Python3 COMPONENTS Interpreter Development)
find_package(pybind11 CONFIG)
if(Python3_Development_FOUND AND BUILD_SHARED_LIBS AND pybind11_FOUND)
  pybind11_add_module(pyopenpano python/pybind.cc)
  target_link_libraries(pyopenpano PRIVATE openpano_core)
endif()

# Install targets for Rust FFI
install(TARGETS openpano_core openpano_c lodepng
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
)

install(FILES c_api/openpano_c.h
    DESTINATION include
)
