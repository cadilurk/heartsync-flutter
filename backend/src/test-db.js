import 'dotenv/config';
import { MongoClient } from 'mongodb';

const mongoUri = process.env.MONGO_URI;

if (!mongoUri) {
  console.error('❌ Lỗi: MONGO_URI chưa được cấu hình trong file backend/.env');
  process.exit(1);
}

console.log('🔌 Đang thử kết nối tới MongoDB...');
// Ẩn mật khẩu trong log để bảo mật
const maskedUri = mongoUri.replace(/:([^@/]+)@/, ':******@');
console.log(`🔗 Connection String: ${maskedUri}`);

const client = new MongoClient(mongoUri);

try {
  await client.connect();
  console.log('✅ Kết nối thành công tới MongoDB!');
  
  const db = client.db('heartsync');
  console.log(`📂 Đã kết nối vào database: "${db.databaseName}"`);
  
  // Kiểm tra thử xem có truy vấn được danh sách collections không
  const collections = await db.listCollections().toArray();
  console.log(`📦 Các collections hiện có trong database (${collections.length}):`);
  if (collections.length === 0) {
    console.log('   (Database trống hoặc chưa có collections nào)');
  } else {
    collections.forEach(col => console.log(`   - ${col.name}`));
  }
} catch (error) {
  console.error('❌ Kết nối tới MongoDB THẤT BẠI!');
  console.error('🔴 Chi tiết lỗi:', error.message);
  console.log('\n💡 Gợi ý khắc phục lỗi kết nối:');
  console.log('1. [QUAN TRỌNG] Kiểm tra Network Access trên MongoDB Atlas: Hãy chắc chắn rằng bạn đã mở khóa IP hiện tại của mình (hoặc thêm 0.0.0.0/0 để cho phép tất cả các IP kết nối tạm thời).');
  console.log('2. Đảm bảo máy tính của bạn có kết nối mạng ổn định.');
  console.log('3. Nếu mật khẩu có chứa các ký tự đặc biệt (như @, /, :, +), hãy đảm bảo chúng đã được URL-encode (ví dụ: @ thành %40).');
} finally {
  await client.close();
  console.log('🔌 Đã đóng kết nối test.');
}
