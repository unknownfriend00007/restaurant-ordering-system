import { createClient } from '@supabase/supabase-js';
import crypto from 'crypto';
import type { VercelRequest, VercelResponse } from '@vercel/node';

// Initialize Supabase with SERVICE ROLE key
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY!
);

interface VerifyPaymentRequest {
  razorpay_order_id: string;
  razorpay_payment_id: string;
  razorpay_signature: string;
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { 
      razorpay_order_id, 
      razorpay_payment_id, 
      razorpay_signature 
    } = req.body as VerifyPaymentRequest;

    // Validate required fields
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // 🔒 SECURITY: Cryptographic signature verification
    // Create HMAC SHA256 hash
    const body = razorpay_order_id + '|' + razorpay_payment_id;
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET!)
      .update(body)
      .digest('hex');

    // 🔒 SECURITY: Timing-safe comparison to prevent timing attacks
    const isValidSignature = crypto.timingSafeEqual(
      Buffer.from(expectedSignature),
      Buffer.from(razorpay_signature)
    );

    if (!isValidSignature) {
      // Log failed verification attempt
      console.error('Invalid signature:', {
        order_id: razorpay_order_id,
        payment_id: razorpay_payment_id,
        timestamp: new Date().toISOString(),
      });
      
      return res.status(400).json({ 
        error: 'Invalid payment signature',
        verified: false 
      });
    }

    // Signature verified - Update order in database
    const { data: order, error: fetchError } = await supabase
      .from('orders')
      .select('*')
      .eq('razorpay_order_id', razorpay_order_id)
      .single();

    if (fetchError || !order) {
      console.error('Order not found:', razorpay_order_id);
      return res.status(404).json({ error: 'Order not found' });
    }

    // 🔒 SECURITY: Idempotent processing - check if already processed
    if (order.payment_status === 'paid') {
      console.log('Payment already processed:', razorpay_order_id);
      return res.status(200).json({
        verified: true,
        message: 'Payment already verified',
        orderId: order.id,
        orderNumber: order.order_number,
      });
    }

    // Update order status to paid
    const { error: updateError } = await supabase
      .from('orders')
      .update({
        razorpay_payment_id,
        payment_status: 'paid',
        order_status: 'paid',
        paid_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .eq('razorpay_order_id', razorpay_order_id);

    if (updateError) {
      console.error('Failed to update order:', updateError);
      return res.status(500).json({ error: 'Failed to update order status' });
    }

    // Success response
    return res.status(200).json({
      verified: true,
      message: 'Payment verified successfully',
      orderId: order.id,
      orderNumber: order.order_number,
    });

  } catch (error) {
    console.error('Verify payment error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}