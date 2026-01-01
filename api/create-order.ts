import { createClient } from '@supabase/supabase-js';
import Razorpay from 'razorpay';
import type { VercelRequest, VercelResponse } from '@vercel/node';

// Initialize Razorpay with credentials
const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID!,
  key_secret: process.env.RAZORPAY_KEY_SECRET!,
});

// Initialize Supabase with SERVICE ROLE key for full access
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_KEY! // Service role bypasses RLS
);

// Menu prices - SOURCE OF TRUTH (never trust client prices)
const MENU_PRICES: Record<string, number> = {
  'biryani': 25000, // ₹250.00 in paise
  'butter-chicken': 35000, // ₹350.00
  'paneer-tikka': 28000, // ₹280.00
  'dal-makhani': 18000, // ₹180.00
  'naan': 4000, // ₹40.00
  'gulab-jamun': 8000, // ₹80.00
  'lassi': 6000, // ₹60.00
};

interface OrderItem {
  id: string;
  name: string;
  quantity: number;
  price: number; // This will be IGNORED, we recalculate
}

interface CreateOrderRequest {
  items: OrderItem[];
  customerName: string;
  customerPhone: string;
  customerAddress: string;
}

export default async function handler(
  req: VercelRequest,
  res: VercelResponse
) {
  // Only allow POST requests
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { items, customerName, customerPhone, customerAddress } = req.body as CreateOrderRequest;

    // 🔒 SECURITY: Input Validation
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ error: 'Invalid items' });
    }

    // Validate customer name (2-50 chars, letters and spaces only)
    if (!customerName || customerName.length < 2 || customerName.length > 50) {
      return res.status(400).json({ error: 'Invalid customer name' });
    }
    if (!/^[a-zA-Z\s]+$/.test(customerName)) {
      return res.status(400).json({ error: 'Customer name must contain only letters' });
    }

    // Validate phone (Indian format: 10 digits, starts with 6-9)
    if (!customerPhone || !/^[6-9]\d{9}$/.test(customerPhone)) {
      return res.status(400).json({ error: 'Invalid phone number. Must be 10 digits starting with 6-9' });
    }

    // Validate address (10-200 chars)
    if (!customerAddress || customerAddress.length < 10 || customerAddress.length > 200) {
      return res.status(400).json({ error: 'Invalid address. Must be 10-200 characters' });
    }

    // 🔒 SECURITY: Server-side price verification and calculation
    let totalAmount = 0;
    const validatedItems: OrderItem[] = [];

    for (const item of items) {
      // Validate item exists in menu
      if (!MENU_PRICES[item.id]) {
        return res.status(400).json({ error: `Invalid item: ${item.id}` });
      }

      // Validate quantity (1-10 max per item)
      if (!item.quantity || item.quantity < 1 || item.quantity > 10) {
        return res.status(400).json({ error: `Invalid quantity for ${item.name}` });
      }

      // Get CORRECT price from server (never trust client)
      const correctPrice = MENU_PRICES[item.id];
      const itemTotal = correctPrice * item.quantity;
      totalAmount += itemTotal;

      validatedItems.push({
        id: item.id,
        name: item.name,
        quantity: item.quantity,
        price: correctPrice, // Use server price
      });
    }

    // Validate total amount (min ₹50, max ₹10,000)
    if (totalAmount < 5000 || totalAmount > 1000000) {
      return res.status(400).json({ 
        error: 'Order amount must be between ₹50 and ₹10,000' 
      });
    }

    // Generate unique order number
    const orderNumber = `ORD-${Date.now()}-${Math.random().toString(36).substr(2, 9).toUpperCase()}`;

    // Create Razorpay order
    const razorpayOrder = await razorpay.orders.create({
      amount: totalAmount, // Amount in paise
      currency: 'INR',
      receipt: orderNumber,
      notes: {
        customer_name: customerName,
        customer_phone: customerPhone,
      },
    });

    // Store order in database with pending status
    const { data: order, error: dbError } = await supabase
      .from('orders')
      .insert([
        {
          order_number: orderNumber,
          razorpay_order_id: razorpayOrder.id,
          customer_name: customerName,
          customer_phone: customerPhone,
          customer_address: customerAddress,
          items: validatedItems,
          total_amount: totalAmount / 100, // Convert to rupees for storage
          payment_status: 'pending',
          order_status: 'awaiting_payment',
        },
      ])
      .select()
      .single();

    if (dbError) {
      console.error('Database error:', dbError);
      return res.status(500).json({ error: 'Failed to create order' });
    }

    // Return order details to client
    return res.status(200).json({
      orderId: order.id,
      orderNumber: orderNumber,
      razorpayOrderId: razorpayOrder.id,
      amount: totalAmount,
      currency: 'INR',
    });

  } catch (error) {
    console.error('Create order error:', error);
    // 🔒 SECURITY: Don't expose internal errors to client
    return res.status(500).json({ error: 'Internal server error' });
  }
}