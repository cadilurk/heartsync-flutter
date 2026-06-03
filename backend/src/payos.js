import { PayOS } from '@payos/node';

// =========================================================================
// THÔNG TIN API CREDENTIALS CỦA CỔNG THANH TOÁN PAYOS
// @payos/node v2.x tự đọc các biến môi trường:
//   PAYOS_CLIENT_ID, PAYOS_API_KEY, PAYOS_CHECKSUM_KEY
// Đảm bảo các giá trị này đã được đặt trong file backend/.env
// =========================================================================
const payOS = new PayOS();

export default payOS;
