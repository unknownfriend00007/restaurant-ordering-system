-- Restaurant Ordering System Database Schema
-- PostgreSQL (Supabase)

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Orders table
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_number TEXT UNIQUE NOT NULL,
    razorpay_order_id TEXT UNIQUE NOT NULL,
    razorpay_payment_id TEXT UNIQUE,
    razorpay_signature TEXT,
    
    -- Customer information
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_address TEXT NOT NULL,
    
    -- Order details
    items JSONB NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    
    -- Payment status: pending, paid, failed, refunded
    payment_status TEXT NOT NULL DEFAULT 'pending',
    
    -- Order status: awaiting_payment, paid, preparing, ready, delivered, cancelled
    order_status TEXT NOT NULL DEFAULT 'awaiting_payment',
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    paid_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Constraints
    CONSTRAINT valid_payment_status CHECK (
        payment_status IN ('pending', 'paid', 'failed', 'refunded')
    ),
    CONSTRAINT valid_order_status CHECK (
        order_status IN ('awaiting_payment', 'paid', 'preparing', 'ready', 'delivered', 'cancelled')
    ),
    CONSTRAINT valid_phone CHECK (
        customer_phone ~ '^[6-9][0-9]{9}$'
    ),
    CONSTRAINT valid_amount CHECK (
        total_amount >= 50 AND total_amount <= 10000
    )
);

-- Menu items table (source of truth for prices)
CREATE TABLE IF NOT EXISTS menu_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    image_url TEXT,
    is_available BOOLEAN DEFAULT true,
    is_vegetarian BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT valid_price CHECK (price > 0)
);

-- Indexes for performance
CREATE INDEX idx_orders_phone ON orders(customer_phone);
CREATE INDEX idx_orders_created_at ON orders(created_at DESC);
CREATE INDEX idx_orders_razorpay_order_id ON orders(razorpay_order_id);
CREATE INDEX idx_orders_razorpay_payment_id ON orders(razorpay_payment_id);
CREATE INDEX idx_orders_payment_status ON orders(payment_status);
CREATE INDEX idx_orders_order_status ON orders(order_status);
CREATE INDEX idx_menu_items_category ON menu_items(category);
CREATE INDEX idx_menu_items_available ON menu_items(is_available);

-- Updated timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_menu_items_updated_at
    BEFORE UPDATE ON menu_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Row Level Security (RLS) Policies

-- Enable RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;

-- Orders policies
-- Customers can only view their own orders (by phone number)
CREATE POLICY "Customers can view own orders"
    ON orders FOR SELECT
    USING (customer_phone = current_setting('app.customer_phone', true));

-- Only service role can insert orders
CREATE POLICY "Service role can insert orders"
    ON orders FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

-- Only service role can update orders
CREATE POLICY "Service role can update orders"
    ON orders FOR UPDATE
    USING (auth.role() = 'service_role');

-- No one can delete orders (soft delete via status only)
CREATE POLICY "No one can delete orders"
    ON orders FOR DELETE
    USING (false);

-- Menu items policies
-- Everyone can view available menu items
CREATE POLICY "Anyone can view menu items"
    ON menu_items FOR SELECT
    USING (true);

-- Only service role can modify menu items
CREATE POLICY "Service role can modify menu items"
    ON menu_items FOR ALL
    USING (auth.role() = 'service_role');

-- Grant permissions
GRANT SELECT ON menu_items TO anon;
GRANT SELECT ON menu_items TO authenticated;
GRANT ALL ON menu_items TO service_role;

GRANT SELECT ON orders TO authenticated;
GRANT ALL ON orders TO service_role;

-- Comments for documentation
COMMENT ON TABLE orders IS 'Stores all customer orders with payment and delivery status';
COMMENT ON TABLE menu_items IS 'Source of truth for menu items and prices';
COMMENT ON COLUMN orders.razorpay_order_id IS 'Razorpay order ID created before payment';
COMMENT ON COLUMN orders.razorpay_payment_id IS 'Razorpay payment ID after successful payment';
COMMENT ON COLUMN orders.razorpay_signature IS 'HMAC signature for payment verification';
COMMENT ON COLUMN orders.items IS 'JSON array of ordered items with name, quantity, price';