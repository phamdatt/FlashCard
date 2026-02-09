#!/bin/bash
# Chạy script này sau khi đổi App Icon để macOS/Xcode bỏ cache cũ
set -e
echo "1. Đang xóa DerivedData của project (Xcode cache build)..."
DERIVED=~/Library/Developer/Xcode/DerivedData
if [ -d "$DERIVED" ]; then
  # Chỉ xóa folder tên chứa flash-card hoặc LearnMacOS
  find "$DERIVED" -maxdepth 1 -type d -name "*flash*" -o -maxdepth 1 -type d -name "*LearnMacOS*" 2>/dev/null | while read d; do
    rm -rf "$d" && echo "   Đã xóa: $d"
  done
fi
echo "2. Restart Dock để refresh icon trên màn hình..."
killall Dock 2>/dev/null || true
echo "3. Touch Assets để Xcode nhận thay đổi..."
touch flash-card/Assets.xcassets/AppIcon.appiconset/*.png 2>/dev/null || true
echo "Xong. Giờ mở Xcode -> Product -> Clean Build Folder (Cmd+Shift+K) -> Build (Cmd+B) -> Run."
