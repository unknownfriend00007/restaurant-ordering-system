-- Restaurant Ordering System Database Schema
-- PostgreSQL with Row Level Security (RLS)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing table if needed (CAREFUL IN PRODUCTION!)
-- DROP TABLE IF EXISTS orders CASCADE;

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- Order identification
  order_number TEXT UNIQUE NOT NULL,
  razorpay_order_id TEXT UNIQUE NOT NULL,
  razorpay_payment_id TEXT UNIQUE,
  
  -- Customer information
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  customer_address TEXT NOT NULL,
  
  -- Order details (stored as JSONB for flexibility)
  items JSONB NOT NULL,
  total_amount DECIMAL(10, 2) NOT NULL,
  
  -- Status tracking
  payment_status TEXT NOT NULL DEFAULT 'pending',
  -- Values: pending, paid, failed, refunded
  
  order_status TEXT NOT NULL DEFAULT 'awaiting_payment',
  -- Values: awaiting_payment, paid, preparing, ready, delivered, cancelled
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  paid_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_payment_status CHECK (
    payment_status IN ('pending', 'paid', 'failed', 'refunded')
  ),
  CONSTRAINT valid_order_status CHECK (
    order_status IN ('awaiting_payment', 'paid', 'preparing', 'ready', 'delivered', 'cancelled')
  ),
  CONSTRAINT valid_amount CHECK (total_amount >= 0)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_orders_customer_phone ON orders(customer_phone);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status ON orders(payment_status);
CREATE INDEX IF NOT EXISTS idx_orders_order_status ON orders(order_status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_razorpay_order_id ON orders(razorpay_order_id);
CREATE INDEX IF NOT EXISTS idx_orders_razorpay_payment_id ON orders(razorpay_payment_id);

-- 🔒 ENABLE ROW LEVEL SECURITY (RLS)
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Customers can view own orders" ON orders;
DROP POLICY IF EXISTS "Service role can insert orders" ON orders;
DROP POLICY IF EXISTS "Service role can update orders" ON orders;

-- 🔒 RLS POLICY: Customers can only view their own orders
-- This allows customers to query their orders using their phone number
CREATE POLICY "Customers can view own orders"
  ON orders
  FOR SELECT
  USING (
    -- Allow if the customer_phone matches the authenticated user's phone
    -- OR if using service_role (backend)
    customer_phone = current_setting('app.user_phone', true)
    OR auth.role() = 'service_role'
  );

-- 🔒 RLS POLICY: Only backend (service role) can insert orders
CREATE POLICY "Service role can insert orders"
  ON orders
  FOR INSERT
  WITH CHECK (
    auth.role() = 'service_role'
  );

-- 🔒 RLS POLICY: Only backend (service role) can update orders
CREATE POLICY "Service role can update orders"
  ON orders
  FOR UPDATE
  USING (
    auth.role() = 'service_role'
  );

-- 🔒 NO DELETE POLICY
-- Orders should never be deleted. Use soft delete by updating order_status to 'cancelled'

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function
DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Sample query to verify setup
-- SELECT * FROM orders ORDER BY created_at DESC LIMIT 10;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON orders TO service_role;
GRANT SELECT ON orders TO authenticated;

-- Verify RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'orders';

-- View all policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'orders';

COMMENT ON TABLE orders IS 'Restaurant orders with Razorpay payment integration';
COMMENT ON COLUMN orders.items IS 'JSONB array of order items with id, name, quantity, price';
COMMENT ON COLUMN orders.payment_status IS 'Razorpay payment status: pending, paid, failed, refunded';
COMMENT ON COLUMN orders.order_status IS 'Restaurant fulfillment status: awaiting_payment, paid, preparing, ready, delivered, cancelled';