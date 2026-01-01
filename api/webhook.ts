import { createClient } from '@supabase/supabase-js';
import crypto from 'crypto';
import type { VercelRequest, VercelResponse } from '@vercel/node';

// Initialize Supabase with SERVICE ROLE key
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
);

// Disable body parsing to get raw body for signature verification
export const config = {
  api: {
    bodyParser: false,
  },
};

// Helper to get raw body as string
function getRawBody(req: VercelRequest): Promise<string> {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (chunk) => {
      data += chunk;
    });
    req.on('end', () => {
      resolve(data);
    });
    req.on('error', reject);
  });
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Get raw body for signature verification
    const rawBody = await getRawBody(req);
    const signature = req.headers['x-razorpay-signature'] as string;

    if (!signature) {
      console.error('Missing webhook signature');
      return res.status(400).json({ error: 'Missing signature' });
    }

    // 🔒 SECURITY: Verify webhook signature
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET!)
      .update(rawBody)
      .digest('hex');

    // 🔒 SECURITY: Timing-safe comparison
    const isValid = crypto.timingSafeEqual(
      Buffer.from(expectedSignature),
      Buffer.from(signature)
    );

    if (!isValid) {
      console.error('Invalid webhook signature');
      return res.status(400).json({ error: 'Invalid signature' });
    }

    // Parse the verified webhook payload
    const event = JSON.parse(rawBody);
    const { entity } = event.payload.payment;

    console.log('Webhook event:', event.event, entity.order_id);

    // 🔒 SECURITY: Idempotent processing
    // Handle different webhook events
    switch (event.event) {
      case 'payment.captured':
        await handlePaymentCaptured(entity);
        break;
      
      case 'payment.failed':
        await handlePaymentFailed(entity);
        break;
      
      case 'refund.processed':
        await handleRefundProcessed(entity);
        break;
      
      default:
        console.log('Unhandled webhook event:', event.event);
    }

    // Always return 200 to acknowledge receipt
    return res.status(200).json({ received: true });

  } catch (error) {
    console.error('Webhook error:', error);
    // Still return 200 to prevent retries for malformed requests
    return res.status(200).json({ received: true });
  }
}

async function handlePaymentCaptured(payment: any) {
  const { order_id, id: payment_id, amount, status } = payment;

  // Get order from database
  const { data: order } = await supabase
    .from('orders')
    .select('*')
    .eq('razorpay_order_id', order_id)
    .single();

  if (!order) {
    console.error('Order not found for webhook:', order_id);
    return;
  }

  // Check if already processed (idempotent)
  if (order.payment_status === 'paid') {
    console.log('Payment already processed:', order_id);
    return;
  }

  // Update order status
  await supabase
    .from('orders')
    .update({
      razorpay_payment_id: payment_id,
      payment_status: 'paid',
      order_status: 'paid',
      paid_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('razorpay_order_id', order_id);

  console.log('Payment captured:', order_id, payment_id);

  // TODO: Send confirmation email/SMS to customer
  // TODO: Notify restaurant staff
}

async function handlePaymentFailed(payment: any) {
  const { order_id, id: payment_id, error_code, error_description } = payment;

  await supabase
    .from('orders')
    .update({
      razorpay_payment_id: payment_id,
      payment_status: 'failed',
      order_status: 'awaiting_payment',
      updated_at: new Date().toISOString(),
    })
    .eq('razorpay_order_id', order_id);

  console.log('Payment failed:', order_id, error_code, error_description);
}

async function handleRefundProcessed(refund: any) {
  const { payment_id, amount, status } = refund;

  await supabase
    .from('orders')
    .update({
      payment_status: 'refunded',
      order_status: 'cancelled',
      updated_at: new Date().toISOString(),
    })
    .eq('razorpay_payment_id', payment_id);

  console.log('Refund processed:', payment_id, amount);
}