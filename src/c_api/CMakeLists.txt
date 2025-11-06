# CMakeLists.txt for C API wrapper

# Add C API source files
set(C_API_SOURCES
    openpano_c.cc
)

# Create static library for C API
add_library(openpano_c STATIC ${C_API_SOURCES})

# Link against main openpano library
target_link_libraries(openpano_c
    PRIVATE
    openpano_core
)

# Include directories
target_include_directories(openpano_c
    PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/src
)

# Set C++ standard (C++14 for mobile due to Eigen3 requirements)
if(ANDROID OR IOS)
    set_target_properties(openpano_c PROPERTIES
        CXX_STANDARD 14
        CXX_STANDARD_REQUIRED ON
        POSITION_INDEPENDENT_CODE ON  # Required for FFI
    )
else()
    set_target_properties(openpano_c PROPERTIES
        CXX_STANDARD 11
        CXX_STANDARD_REQUIRED ON
        POSITION_INDEPENDENT_CODE ON  # Required for FFI
    )
endif()

# Install library and headers
install(TARGETS openpano_c
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
)

install(FILES openpano_c.h
    DESTINATION include
)

