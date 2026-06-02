import PayOS from '@payos/node';

// =========================================================================
// THÔNG TIN API CREDENTIALS CỦA CỔNG THANH TOÁN PAYOS
// Bạn hãy thay thế các chuỗi "YOUR_..." bên dưới bằng thông tin thật của bạn,
// hoặc tốt nhất là cấu hình chúng trong file backend/.env
// =========================================================================
const PAYOS_CLIENT_ID = process.env.PAYOS_CLIENT_ID;
const PAYOS_API_KEY = process.env.PAYOS_API_KEY;
const PAYOS_CHECKSUM_KEY = process.env.PAYOS_CHECKSUM_KEY;

const payOS = new PayOS(
  PAYOS_CLIENT_ID,
  PAYOS_API_KEY,
  PAYOS_CHECKSUM_KEY
);

export default payOS;
