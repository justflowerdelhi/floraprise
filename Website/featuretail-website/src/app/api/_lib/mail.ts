import nodemailer from "nodemailer";

export const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,
  port: Number(process.env.SMTP_PORT),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

export const sendOrderEmail = async ({
  to,
  name,
  orderNumber,
  total
}: {
  to: string;
  name: string;
  orderNumber: string;
  total: number;
}) => {
  await transporter.sendMail({
    from: `"Featuretail" <${process.env.SMTP_USER}>`,
    to,
    subject: `Order Confirmed #${orderNumber}`,
    html: `
      <h2>Thank you for your order, ${name}!</h2>
      <p>Your order <b>#${orderNumber}</b> has been placed successfully.</p>
      <p><b>Total:</b> ₹${total}</p>
      <p>We will process your order soon.</p>
      <br/>
      <p>– Featuretail Team</p>
    `
  });
};
