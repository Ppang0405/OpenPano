# Step-by-Step Guide: Running Python Tests

## 🎯 Goal
Run `run_test.py` to verify the Rust binary works with the official test datasets.

## 📋 Prerequisites
- ✅ Rust binary built successfully
- ✅ Crash fixed (DEBUG assertions disabled)
- ✅ Test data will be downloaded automatically

---

## 🚀 Step-by-Step Instructions

### Step 1: Navigate to src Directory

```bash
cd /Users/truong.nguyen3/Documents/_work_samples/OpenPano/src
```

### Step 2: Create Symlink to Rust Binary

```bash
# Remove old symlink/binary if exists
rm -f ./image-stitching

# Create new symlink to Rust binary
ln -sf ../rust-wrapper/target/release/image-stitching ./image-stitching

# Verify symlink was created
ls -lh ./image-stitching
```

**Expected output:**
```
lrwxr-xr-x ... ./image-stitching -> ../rust-wrapper/target/release/image-stitching
```

### Step 3: Verify Rust Binary Works

```bash
# Test the binary directly (should show usage)
./image-stitching
```

**Expected output:**
```
Usage: ./image-stitching <image1> <image2> [image3] ...
Need at least two images to stitch.
```

### Step 4: Verify config.cfg Exists

```bash
# Check config file is present
ls -la config.cfg

# Show first few lines
head -10 config.cfg
```

**Expected output:**
```
-rw-r--r-- ... config.cfg
# [general modes]: if no modes is set, will use naive mode
CYLINDER 0
ESTIMATE_CAMERA 1
...
```

### Step 5: Try Enabling ORDERED_INPUT

The test images are sequential panoramas, so enabling ordered input may help:

```bash
# Backup original config
cp config.cfg config.cfg.backup

# Enable ORDERED_INPUT
sed -i.tmp 's/ORDERED_INPUT 0/ORDERED_INPUT 1/' config.cfg

# Verify the change
grep ORDERED_INPUT config.cfg
```

**Expected output:**
```
ORDERED_INPUT 1
```

### Step 6: Run the Python Test

```bash
python3 run_test.py
```

**What will happen:**

1. **Downloads test data** (first time only - 54MB):
   ```
   Downloading example-data.tgz...
   Extracting...
   ```

2. **Tests zijing dataset** (12 images):
   ```
   Testing with example-data/zijing/*
   OpenPano - Panorama Image Stitching
   Stitching 12 images...
   ...
   ```

3. **Tests CMU1 dataset** (multiple images):
   ```
   Testing with example-data/CMU1/*
   ...
   ```

4. **Success message**:
   ```
   Tests Passed
   ```

---

## ⚠️ If Test Still Fails

### Option A: Try with Only 2-3 Images First

```bash
# Test with just 2 images
./image-stitching example-data/zijing/medium01.jpg \
                  example-data/zijing/medium02.jpg

# Check if output was created
ls -lh out.jpg
```

### Option B: Try Different Configuration

Edit `config.cfg`:

```bash
nano config.cfg
```

Try these settings for sequential images:

```ini
# Simple cylinder mode (good for rotating camera)
CYLINDER 1
ESTIMATE_CAMERA 0
TRANS 0
ORDERED_INPUT 1
CROP 1
```

Or for general panoramas:

```ini
# Camera estimation mode
CYLINDER 0
ESTIMATE_CAMERA 1
TRANS 0
ORDERED_INPUT 1
CROP 1
```

Then run again:
```bash
python3 run_test.py
```

### Option C: Check Image Features Manually

Test feature detection on one image:

```bash
# Download a single test image and check it
file example-data/zijing/medium01.jpg

# Try stitching just the first two
./image-stitching example-data/zijing/medium01.jpg \
                  example-data/zijing/medium02.jpg

# Check output
ls -lh out.jpg
```

### Option D: Adjust SIFT Parameters

Edit `config.cfg` to detect more features:

```ini
SIFT_WORKING_SIZE 800
CONTRAST_THRES 3e-2    # Lower = more features (was 4e-2)
JUDGE_EXTREMA_DIFF_THRES 1e-3  # Lower = more features (was 2e-3)
EDGE_RATIO 8           # Higher = more features (was 6)
```

---

## 📊 Understanding Test Output

### Success Output

```
Testing with example-data/zijing/*
OpenPano - Panorama Image Stitching
Stitching 12 images...
Adding image 1: example-data/zijing/medium01.jpg
...
Building panorama...
Final Image Size (6488, 1100)
Stitching completed in 45.23s
Saving to 'out.jpg'...
Done!

Testing with example-data/CMU1/*
...
Final Image Size (8000, 1449)
...
Tests Passed  ✅
```

### Failure Output

```
ERROR:
error: Cannot find feature in image 0!
```

**This means:** SIFT couldn't detect enough keypoints. Try:
- Enabling ORDERED_INPUT
- Adjusting SIFT parameters
- Using fewer images first

---

## 🔧 Troubleshooting Quick Reference

### "Command not found: python3"
```bash
# Try python instead
python run_test.py
```

### "No such file or directory: ./image-stitching"
```bash
# Recreate symlink
cd /Users/truong.nguyen3/Documents/_work_samples/OpenPano/src
ln -sf ../rust-wrapper/target/release/image-stitching ./image-stitching
```

### "cannot find feature in image"
```bash
# Enable ordered input
sed -i.bak 's/ORDERED_INPUT 0/ORDERED_INPUT 1/' config.cfg
python3 run_test.py
```

### Test hangs/takes too long
```bash
# Press Ctrl+C to stop
# Try with fewer images first
./image-stitching example-data/zijing/medium0{1,2,3}.jpg
```

### Binary crashes with SIGABRT
```bash
# Rebuild without debug assertions
cd ../rust-wrapper
cargo clean
cargo build --release --bin image-stitching
```

---

## 📁 File Locations Reference

```
OpenPano/
├── src/
│   ├── config.cfg              ← Configuration file (needed!)
│   ├── run_test.py             ← Python test script
│   ├── image-stitching         ← Symlink to Rust binary
│   └── example-data/           ← Auto-downloaded test data
│       ├── zijing/            ← 12 panorama images
│       └── CMU1/              ← Multiple test images
├── rust-wrapper/
│   └── target/release/
│       └── image-stitching     ← Actual Rust binary
└── out.jpg                     ← Output panorama
```

---

## ✅ Success Checklist

Before running the test, verify:

- [ ] In `src/` directory
- [ ] `image-stitching` symlink exists
- [ ] `config.cfg` exists
- [ ] Rust binary is recent (rebuilt after crash fix)
- [ ] `ORDERED_INPUT` is set to 1 in config.cfg

Then run:
```bash
python3 run_test.py
```

---

## 🎯 Quick Commands Summary

```bash
# Complete setup and test (copy-paste all):
cd /Users/truong.nguyen3/Documents/_work_samples/OpenPano/src
rm -f ./image-stitching
ln -sf ../rust-wrapper/target/release/image-stitching ./image-stitching
sed -i.bak 's/ORDERED_INPUT 0/ORDERED_INPUT 1/' config.cfg
python3 run_test.py
```

---

**Good luck!** The test should work now with the crash fixed and ordered input enabled. 🚀

