# OpenPano Hybrid C++/Rust Architecture

This document explains the hybrid architecture that wraps the original C++ OpenPano implementation with Rust and provides cross-platform bindings.

## 🏗️ Architecture Overview

```
┌───────────────────────────────────────────────────────────┐
│                   Application Layer                        │
│  ┌──────────────┬──────────────┬──────────────────────┐  │
│  │   Python     │   Swift      │       Kotlin         │  │
│  │   (PyO3)     │   (iOS)      │     (Android)        │  │
│  └──────┬───────┴──────┬───────┴──────────┬───────────┘  │
└─────────┼──────────────┼──────────────────┼──────────────┘
          │              │                  │
          └──────────────┴──────────────────┘
                         │
                         │ (UniFFI Generated)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Rust Safe Wrapper (lib.rs)                     │
│  - Memory-safe API                                          │
│  - Idiomatic Rust types (Result, String, Vec)              │
│  - RAII for resource management                             │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ (unsafe FFI)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Rust FFI Bindings (ffi.rs)                     │
│  - Unsafe extern "C" functions                              │
│  - Raw pointers (*mut, *const)                              │
│  - C-compatible types                                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ (C ABI)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│           C API Wrapper (openpano_c.{h,cc})                 │
│  - Stable C ABI                                             │
│  - Error handling via return codes                          │
│  - Opaque pointers for C++ objects                          │
│  - Exception → error code translation                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           │ (C++)
                           ▼
┌─────────────────────────────────────────────────────────────┐
│          C++ Core (Original OpenPano)                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Feature Detection (SIFT, DOG, Gaussian)            │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Feature Matching (FLANN, RANSAC)                   │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Image Stitching (Homography, Bundle Adjustment)    │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Blending (Linear, Multi-band)                      │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │  Libraries (Eigen, FLANN, lodepng)                  │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## 📦 Component Breakdown

### 1. C++ Core (Unchanged)
- **Location**: `src/feature/`, `src/stitch/`, `src/lib/`
- **Language**: C++11
- **Dependencies**: Eigen3, FLANN, libjpeg, lodepng
- **Purpose**: All core panorama stitching algorithms
- **Status**: Preserved as-is, battle-tested code

### 2. C API Layer (New)
- **Location**: `src/c_api/openpano_c.{h,cc}`
- **Language**: C++ with `extern "C"`
- **Purpose**: Provide stable C ABI for FFI
- **Key Features**:
  - Opaque pointer handles (`CStitcher*`, `CImage*`)
  - Error codes instead of exceptions
  - No C++ types in public API
  - Manual memory management (create/destroy functions)

**Example**:
```c
// C API - stable across compiler versions
CStitcher* openpano_stitcher_create(const OpenpanoConfig* config);
OpenpanoError openpano_stitcher_add_image(CStitcher* s, const char* path);
CImage* openpano_stitcher_build(CStitcher* s);
void openpano_image_destroy(CImage* img);
```

### 3. Rust FFI Layer (New)
- **Location**: `rust-wrapper/src/ffi.rs`
- **Language**: Rust (unsafe)
- **Purpose**: Low-level bindings to C API
- **Key Features**:
  - Direct `extern "C"` declarations
  - Unsafe operations isolated here
  - Zero-cost abstraction over C API

**Example**:
```rust
#[link(name = "openpano_c")]
extern "C" {
    pub fn openpano_stitcher_create(
        config: *const OpenpanoConfig
    ) -> *mut CStitcher;
    
    pub fn openpano_stitcher_destroy(stitcher: *mut CStitcher);
}
```

### 4. Rust Safe Wrapper (New)
- **Location**: `rust-wrapper/src/lib.rs`
- **Language**: Rust (safe)
- **Purpose**: Safe, idiomatic Rust API
- **Key Features**:
  - RAII via Drop trait
  - Result<T, E> for errors
  - Lifetime management
  - Type safety
  - Send + Sync traits

**Example**:
```rust
pub struct Stitcher {
    inner: *mut ffi::CStitcher,
}

impl Stitcher {
    pub fn new() -> Result<Self, PanoError> { ... }
    pub fn add_image<P: AsRef<Path>>(&mut self, path: P) -> Result<(), PanoError> { ... }
    pub fn stitch(self) -> Result<Image, PanoError> { ... }
}

impl Drop for Stitcher {
    fn drop(&mut self) {
        unsafe { ffi::openpano_stitcher_destroy(self.inner); }
    }
}
```

### 5. UniFFI Bindings (Generated)
- **Location**: `rust-wrapper/src/openpano.udl`
- **Purpose**: Auto-generate language bindings
- **Generates**:
  - Python module via PyO3
  - Swift code for iOS
  - Kotlin code for Android
- **Benefits**:
  - Single source of truth (.udl file)
  - Type-safe bindings
  - Error propagation
  - Memory safety across FFI boundary

**UDL Example**:
```udl
interface Panorama {
  u32 width();
  u32 height();
  [Throws=PanoError]
  void save(string path);
};

[Throws=PanoError]
Panorama stitch_panorama(sequence<string> paths, PanoConfig? config);
```

## 🔄 Data Flow Example

### Stitching 3 Images

```
1. Python Call
   ────────────────────────────────────────────────
   panorama = stitch_panorama(["1.jpg", "2.jpg", "3.jpg"], None)

2. UniFFI Layer (Generated Python)
   ────────────────────────────────────────────────
   # Convert Python types → Rust types
   paths_vec = Vec<String>
   config_opt = Option<PanoConfig>
   # Call Rust function

3. Rust Safe Layer (lib.rs)
   ────────────────────────────────────────────────
   pub fn stitch_panorama(paths: Vec<String>, config: Option<PanoConfig>) 
       -> Result<Arc<Panorama>, PanoError>
   {
       let mut stitcher = Stitcher::with_config(config)?;
       for path in paths {
           stitcher.add_image(path)?;  // ← Safe Rust
       }
       let image = stitcher.stitch()?;
       Ok(Arc::new(Panorama { image }))
   }

4. Rust FFI Layer (ffi.rs)
   ────────────────────────────────────────────────
   // stitcher.add_image() calls:
   unsafe {
       let c_path = CString::new(path)?;
       ffi::openpano_stitcher_add_image(self.inner, c_path.as_ptr())
   }

5. C API Layer (openpano_c.cc)
   ────────────────────────────────────────────────
   extern "C" OpenpanoError openpano_stitcher_add_image(
       CStitcher* stitcher, const char* path)
   {
       try {
           stitcher->image_paths.emplace_back(path);  // ← C++ std::vector
           return OPENPANO_OK;
       } catch (...) {
           return OPENPANO_ERROR_ADD_IMAGE;
       }
   }

6. C++ Core (stitcher.cc)
   ────────────────────────────────────────────────
   Stitcher s(std::move(paths));
   Mat32f result = s.build();  // ← Original OpenPano code
   // SIFT feature detection
   // RANSAC matching
   // Bundle adjustment
   // Blending

7. Return Path (same layers in reverse)
   ────────────────────────────────────────────────
   C++ Mat32f → CImage* → *mut CImage → Image → Panorama → PyObject
```

## 🔒 Safety Guarantees

### Memory Safety

| Layer | Safety Level | Mechanism |
|-------|-------------|-----------|
| C++ Core | ❌ Unsafe | Manual management |
| C API | ❌ Unsafe | Manual create/destroy |
| Rust FFI | ⚠️ Unsafe (isolated) | Raw pointers |
| Rust Safe | ✅ Safe | RAII, Drop trait |
| UniFFI | ✅ Safe | Arc, automatic refcounting |
| Python/Swift/Kotlin | ✅ Safe | GC/ARC |

### Error Handling

```
┌────────────────────────────────────────────────────────┐
│ C++ Exception                                           │
│   std::exception, std::runtime_error, etc.             │
│                                                         │
│   ↓ catch(...) in C API                                │
│                                                         │
│ C Error Code                                            │
│   OPENPANO_ERROR_STITCH, etc.                          │
│   + last_error string                                  │
│                                                         │
│   ↓ checked in Rust FFI                                │
│                                                         │
│ Rust Result<T, PanoError>                              │
│   PanoError::StitchError(String)                       │
│   ? operator for propagation                           │
│                                                         │
│   ↓ mapped by UniFFI                                   │
│                                                         │
│ Language-Specific Error                                 │
│   Python: PanoError.StitchError                        │
│   Swift: throws PanoError                              │
│   Kotlin: PanoException                                │
└────────────────────────────────────────────────────────┘
```

## 📊 Performance Considerations

### FFI Overhead

1. **Function Call Overhead**: ~10-50ns per call (negligible)
2. **String Conversion**: O(n) for each path (one-time cost)
3. **Data Copy**: None - we pass pointers
4. **Optimization**: LTO can inline across FFI boundary

### Memory Layout

```
┌─────────────────────────────────────────┐
│  Python/Swift/Kotlin                    │
│  Arc<Panorama>                          │  ← Reference counted
│    └─> Arc<Image>                       │
│          └─> *mut CImage                │  ← Pointer to C++
│                └─> Mat32f (C++)         │  ← Actual data
│                      └─> float[]        │
└─────────────────────────────────────────┘

Memory is freed when:
1. Python/Swift/Kotlin: GC/ARC releases Arc
2. Rust: Arc count hits 0, Drop called
3. Drop: calls openpano_image_destroy()
4. C API: delete CImage (C++ destructor runs)
5. C++: Mat32f cleaned up
```

### Build Times

| Component | Time | Can Cache? |
|-----------|------|------------|
| C++ Core | 30-60s | ✅ Yes (CMake) |
| C API | 5-10s | ✅ Yes (CMake) |
| Rust FFI | 5-10s | ✅ Yes (cargo) |
| Rust Wrapper | 10-20s | ✅ Yes (cargo) |
| UniFFI Gen | 1-2s | ⚠️ On .udl change |
| **Total** | **~50-90s** | **Incremental: 2-5s** |

## 🔧 Maintenance

### When to Modify Each Layer

#### C++ Core
- ✅ Adding new stitching algorithm
- ✅ Performance optimization
- ❌ Don't add new public API (use C API instead)

#### C API
- ✅ Exposing new C++ functionality
- ✅ Adding configuration options
- ⚠️ Keep ABI stable!

#### Rust FFI
- ✅ Mirrors C API changes
- ✅ One-to-one mapping with C functions
- ❌ No logic here, just bindings

#### Rust Safe
- ✅ Ergonomic improvements
- ✅ Additional safety checks
- ✅ Convenience functions
- ✅ Documentation

#### UniFFI
- ✅ Cross-platform API changes
- ✅ Adding new types/methods
- ⚠️ Changes affect all 3 platforms

## 🎯 Design Decisions

### Why Not Pure Rust?
- ✅ Faster time to market (1.5-2 months vs 4-5 months)
- ✅ Battle-tested algorithms
- ✅ Can incrementally migrate later
- ❌ Two build systems to maintain

### Why Not Just C++ with Bindings?
- ❌ C++ ABI instability
- ❌ Complex binding code per platform
- ❌ No memory safety
- ❌ Poor package management

### Why Rust Middle Layer?
- ✅ UniFFI for automatic cross-platform
- ✅ Cargo for simple builds
- ✅ Memory safety at boundaries
- ✅ Modern tooling

### Why UniFFI vs PyO3/JNI/etc.?
- ✅ Write once, generate for all platforms
- ✅ Type-safe bindings
- ✅ Mozilla-backed, stable
- ✅ Good documentation
- ⚠️ Slightly less flexible than hand-written bindings

## 📚 Further Reading

- [UniFFI Book](https://mozilla.github.io/uniffi-rs/)
- [Rust FFI Omnibus](http://jakegoulding.com/rust-ffi-omnibus/)
- [Original OpenPano README](../README.md)
- [PyO3 Documentation](https://pyo3.rs/)
- [Swift C++ Interop](https://www.swift.org/documentation/cxx-interop/)

## 🤝 Contributing

When adding new features:
1. Add to C++ core (`src/`)
2. Expose via C API (`src/c_api/`)
3. Add Rust FFI binding (`rust-wrapper/src/ffi.rs`)
4. Add safe Rust wrapper (`rust-wrapper/src/lib.rs`)
5. Update UniFFI if needed (`rust-wrapper/src/openpano.udl`)
6. Test on all 3 platforms
7. Update documentation

---

**Questions?** File an issue or refer to the [QUICKSTART.md](rust-wrapper/QUICKSTART.md)

