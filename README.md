# HeartSync

Ứng dụng kết nối cặp đôi — Flutter + Node.js + MongoDB + Firebase FCM.

## 🚀 Cách chạy project

> ⚠️ KHÔNG dùng `flutter run` trực tiếp. KHÔNG bấm Run ▶ mặc định.
> Script sẽ tự động lấy IP máy bạn trước khi chạy.

### Windows
Double-click `run.bat` hoặc trong terminal:
```
.\run.bat
```

### Mac / Linux
```bash
chmod +x run.sh  # Chỉ làm 1 lần
./run.sh
```

### Tích hợp Android Studio (làm 1 lần)
1. Run → Edit Configurations → bấm dấu **+** → chọn **Flutter**
2. Name: `HeartSync`
3. Dart entrypoint: `lib/main.dart`
4. Cuộn xuống **Before launch** → **+** → Run External Tool → **+**
5. Điền:
   - Name: `Auto IP`
   - Program: `powershell.exe`
   - Arguments: `-ExecutionPolicy Bypass -File "$ProjectFileDir$\update_ip.ps1"`
   - Working directory: `$ProjectFileDir$`
6. OK → Giờ bấm ▶ là tự động lấy IP + chạy app

---

## Backend

```bash
cd backend
npm install
node src/server.js
```

Cần file `backend/firebase-service-account.json` (tải từ Firebase Console → Project Settings → Service Accounts).

---

*A Flutter project.*
