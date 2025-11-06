use std::env;
use std::path::PathBuf;

fn main() {
    let manifest_dir = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let openpano_root = manifest_dir.parent().unwrap();
    let target = env::var("TARGET").unwrap();
    
    println!("cargo:rerun-if-changed=../src");
    println!("cargo:rerun-if-changed=build.rs");
    
    // Configure CMake for cross-compilation
    let mut cmake_config = cmake::Config::new(openpano_root);
    cmake_config
        .define("BUILD_SHARED_LIBS", "OFF")
        .define("CMAKE_BUILD_TYPE", "Release");
    
    // Use Ninja generator if available (faster), otherwise Unix Makefiles
    if target.contains("android") || target.contains("ios") {
        // For cross-compilation, explicitly set generator
        if let Ok(_) = std::process::Command::new("ninja").arg("--version").output() {
            cmake_config.generator("Ninja");
        }
    }
    
    // Android-specific configuration
    if target.contains("android") {
        if let Ok(ndk_home) = env::var("ANDROID_NDK_HOME") {
            // Set ANDROID_NDK environment variable for CMake
            env::set_var("ANDROID_NDK", &ndk_home);
            
            let toolchain_file = format!("{}/build/cmake/android.toolchain.cmake", ndk_home);
            cmake_config.define("CMAKE_TOOLCHAIN_FILE", &toolchain_file);
            cmake_config.define("ANDROID_NDK", &ndk_home);
            cmake_config.define("CMAKE_ANDROID_NDK", &ndk_home);
            
            // Set Android ABI based on target
            let android_abi = if target.contains("aarch64") {
                "arm64-v8a"
            } else if target.contains("armv7") {
                "armeabi-v7a"
            } else if target.contains("i686") {
                "x86"
            } else if target.contains("x86_64") {
                "x86_64"
            } else {
                panic!("Unsupported Android target: {}", target);
            };
            
            cmake_config.define("ANDROID_ABI", android_abi);
            cmake_config.define("ANDROID_PLATFORM", "android-21");
            cmake_config.define("CMAKE_ANDROID_ARCH_ABI", android_abi);
            cmake_config.define("CMAKE_SYSTEM_VERSION", "21");
            
            println!("cargo:warning=Building for Android: {} ({}) using NDK at {}", android_abi, target, ndk_home);
        } else {
            panic!("ANDROID_NDK_HOME environment variable not set. Please set it to your Android NDK path.");
        }
    }
    
    // iOS-specific configuration
    if target.contains("ios") {
        cmake_config.define("CMAKE_SYSTEM_NAME", "iOS");
        cmake_config.define("CMAKE_OSX_DEPLOYMENT_TARGET", "13.0");
        
        if target.contains("sim") || target.contains("x86_64-apple-ios") {
            cmake_config.define("CMAKE_OSX_SYSROOT", "iphonesimulator");
        } else {
            cmake_config.define("CMAKE_OSX_SYSROOT", "iphoneos");
        }
    }
    
    let dst = cmake_config.build();
    
    // Link search paths
    println!("cargo:rustc-link-search=native={}/lib", dst.display());
    println!("cargo:rustc-link-search=native={}/lib64", dst.display());
    
    // Add homebrew paths for macOS
    if cfg!(target_os = "macos") {
        println!("cargo:rustc-link-search=native=/opt/homebrew/lib");
        println!("cargo:rustc-link-search=native=/usr/local/lib");
    }
    
    // Link the C++ libraries
    println!("cargo:rustc-link-lib=static=openpano_core");
    println!("cargo:rustc-link-lib=static=openpano_c");
    println!("cargo:rustc-link-lib=static=lodepng");
    
    // Link C++ standard library based on platform
    if target.contains("apple") {
        println!("cargo:rustc-link-lib=dylib=c++");

        // Link libjpeg on macOS (not iOS)
        if !target.contains("ios") {
            println!("cargo:rustc-link-lib=dylib=jpeg");
        }
    } else if target.contains("android") {
        // Android uses c++_shared from NDK
        println!("cargo:rustc-link-lib=dylib=c++_shared");
        
        // Link OpenMP for Android
        if let Ok(ndk_home) = env::var("ANDROID_NDK_HOME") {
            // Determine architecture for OpenMP library path
            let arch = if target.contains("aarch64") {
                "aarch64"
            } else if target.contains("armv7") {
                "arm"
            } else if target.contains("i686") {
                "i386"
            } else if target.contains("x86_64") {
                "x86_64"
            } else {
                "aarch64" // default
            };
            
            let omp_lib_path = format!(
                "{}/toolchains/llvm/prebuilt/darwin-x86_64/lib/clang/17/lib/linux/{}",
                ndk_home, arch
            );
            println!("cargo:rustc-link-search=native={}", omp_lib_path);
            println!("cargo:rustc-link-lib=static=omp");
        }
    } else if target.contains("linux") {
        println!("cargo:rustc-link-lib=dylib=stdc++");
        println!("cargo:rustc-link-lib=dylib=jpeg");
    } else if target.contains("windows") {
        // Windows uses static linking by default with MSVC
    }
    
    // Generate UniFFI scaffolding
    uniffi::generate_scaffolding("./src/openpano.udl")
        .expect("Failed to generate UniFFI scaffolding");
    
    println!("cargo:info=OpenPano C++ library built and linked successfully");
}

