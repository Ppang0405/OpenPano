#!/bin/bash
# Fix SIFT feature detection parameters

cd /Users/truong.nguyen3/Documents/_work_samples/OpenPano/src

echo "Backing up config.cfg..."
cp config.cfg config.cfg.original

echo "Adjusting SIFT parameters for better feature detection..."

# Make SIFT more sensitive to detect more features
sed -i.tmp 's/CONTRAST_THRES 4e-2/CONTRAST_THRES 2e-2/' config.cfg
sed -i.tmp 's/JUDGE_EXTREMA_DIFF_THRES 2e-3/JUDGE_EXTREMA_DIFF_THRES 1e-3/' config.cfg
sed -i.tmp 's/EDGE_RATIO 6/EDGE_RATIO 10/' config.cfg

echo "New SIFT parameters:"
grep -E "CONTRAST_THRES|JUDGE_EXTREMA|EDGE_RATIO" config.cfg

echo ""
echo "Testing with 3 images first..."
./image-stitching example-data/zijing/medium0{1,2,3}.jpg

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Success with 3 images! Output saved to out.jpg"
    echo "Now trying full test..."
    python3 run_test.py
else
    echo ""
    echo "❌ Still failing. The images may not be compatible with SIFT."
    echo "This is a known issue with the original C++ code."
fi

