#!/bin/bash
# Lay IP WiFi
if [[ "$OSTYPE" == "darwin"* ]]; then
  IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
else
  IP=$(hostname -I | awk '{print $1}')
fi

# Fallback
if [ -z "$IP" ]; then
  IP="localhost"
fi

echo "✅ IP phát hiện: $IP"

# Cập nhật api_constants.dart
sed -i.bak "s|defaultValue: 'http://[^']*'|defaultValue: 'http://$IP:5291'|g" \
  lib/core/constants/api_constants.dart

echo "✅ Đã cập nhật api_constants.dart → http://$IP:5291"
echo "🚀 Đang chạy Flutter..."

flutter run --dart-define=HEART_SYNC_API_BASE_URL=http://$IP:5291
