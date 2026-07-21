import nodemailer from 'nodemailer';

const gmailUser = process.env.GMAIL_USER;
const gmailAppPassword = process.env.GMAIL_APP_PASSWORD;
const mailFrom = process.env.MAIL_FROM || gmailUser;

const transporter = gmailUser && gmailAppPassword
  ? nodemailer.createTransport({
      service: 'gmail',
      auth: { user: gmailUser, pass: gmailAppPassword }
    })
  : null;

if (!transporter) {
  console.warn('Warning: GMAIL_USER/GMAIL_APP_PASSWORD not set. Verification/reset emails will be skipped.');
}

async function sendMail({ to, subject, html }) {
  if (!transporter) {
    console.warn(`[mailer] Gmail SMTP not configured — skipped "${subject}" to ${to}`);
    return { skipped: true };
  }
  return transporter.sendMail({ from: mailFrom, to, subject, html });
}

export function sendVerificationCodeEmail(to, code) {
  return sendMail({
    to,
    subject: 'Mã xác thực HeartSync của bạn',
    html: `<div style="font-family:sans-serif"><p>Mã xác thực email của bạn là:</p>
           <p style="font-size:28px;font-weight:bold;letter-spacing:4px">${code}</p>
           <p>Mã có hiệu lực trong 10 phút. Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email.</p></div>`
  });
}

export function sendPasswordResetCodeEmail(to, code) {
  return sendMail({
    to,
    subject: 'Đặt lại mật khẩu HeartSync',
    html: `<div style="font-family:sans-serif"><p>Mã đặt lại mật khẩu của bạn là:</p>
           <p style="font-size:28px;font-weight:bold;letter-spacing:4px">${code}</p>
           <p>Mã có hiệu lực trong 10 phút. Nếu bạn không yêu cầu, vui lòng bỏ qua email này.</p></div>`
  });
}
