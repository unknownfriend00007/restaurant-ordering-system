# 🔒 Security Implementation Guide

This document details all security measures implemented in the restaurant ordering system.

## Table of Contents

1. [Payment Security](#payment-security)
2. [Database Security](#database-security)
3. [API Security](#api-security)
4. [Input Validation](#input-validation)
5. [Environment Variables](#environment-variables)
6. [Security Checklist](#security-checklist)

---

## Payment Security

### 1. Server-Side Price Verification

**Problem:** Malicious users can modify client-side prices to pay less.

**Solution:**
```typescript
// Menu prices stored on backend as SOURCE OF TRUTH
const MENU_PRICES: Record<string, number> = {
  'biryani': 25000, // ₹250.00 in paise
  'butter-chicken': 35000,
};

// Backend recalculates total from scratch
let totalAmount = 0;
for (const item of items) {
  const correctPrice = MENU_PRICES[item.id]; // Never trust client price
  totalAmount += correctPrice * item.quantity;
}
```

**Implementation:** `api/create-order.ts`

### 2. Cryptographic Signature Verification

**Problem:** Attackers might forge payment success responses.

**Solution:**
```typescript
// HMAC-SHA256 signature verification
const body = razorpay_order_id + '|' + razorpay_payment_id;
const expectedSignature = crypto
  .createHmac('sha256', RAZORPAY_KEY_SECRET)
  .update(body)
  .digest('hex');

// Timing-safe comparison prevents timing attacks
const isValid = crypto.timingSafeEqual(
  Buffer.from(expectedSignature),
  Buffer.from(razorpay_signature)
);
```

**Why Timing-Safe?** Regular `===` comparison can leak information through timing differences, allowing attackers to guess signatures character by character.

**Implementation:** `api/verify-payment.ts`

### 3. Webhook Signature Verification

**Problem:** Attackers might send fake webhook events.

**Solution:**
```typescript
// Get raw body (not parsed JSON)
const rawBody = await getRawBody(req);
const signature = req.headers['x-razorpay-signature'];

// Verify signature using webhook secret
const expectedSignature = crypto
  .createHmac('sha256', RAZORPAY_WEBHOOK_SECRET)
  .update(rawBody) // Must be raw string, not parsed object
  .digest('hex');
```

**Critical:** Must use raw body before JSON parsing. Vercel automatically parses body, so we disable it:

```typescript
export const config = {
  api: { bodyParser: false }
};
```

**Implementation:** `api/webhook.ts`

### 4. Idempotent Payment Processing

**Problem:** Network issues might cause duplicate webhook delivery.

**Solution:**
```typescript
// Check if already processed
if (order.payment_status === 'paid') {
  console.log('Payment already processed');
  return res.status(200).json({ verified: true });
}

// Process only once
await supabase.from('orders').update({ payment_status: 'paid' });
```

**Implementation:** Both `verify-payment.ts` and `webhook.ts`

---

## Database Security

### 1. Row Level Security (RLS)

**Problem:** Without RLS, anyone with database credentials can access all data.

**Solution:**
```sql
-- Enable RLS on orders table
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Customers can only view their own orders
CREATE POLICY "Customers can view own orders"
  ON orders FOR SELECT
  USING (customer_phone = current_setting('app.user_phone', true));

-- Only backend (service role) can insert/update
CREATE POLICY "Service role can insert orders"
  ON orders FOR INSERT
  WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role can update orders"
  ON orders FOR UPDATE
  USING (auth.role() = 'service_role');

-- No deletion allowed
-- (Use soft delete by updating order_status to 'cancelled')
```

**Implementation:** `database/schema.sql`

### 2. Parameterized Queries

**Problem:** SQL injection attacks.

**Solution:** Supabase JS client automatically uses parameterized queries:

```typescript
// ✅ SAFE - Parameterized
await supabase
  .from('orders')
  .select('*')
  .eq('customer_phone', phone); // Safely escaped

// ❌ DANGEROUS - Never do this
await supabase.rpc('raw_query', {
  query: `SELECT * FROM orders WHERE phone = '${phone}'`
});
```

### 3. Service Role vs Anon Key

**Environment Variables:**

- `SUPABASE_ANON_KEY` - Limited access, respects RLS (frontend)
- `SUPABASE_SERVICE_KEY` - Full access, bypasses RLS (backend only)

**Usage:**

```typescript
// Frontend - Uses anon key (RLS enforced)
const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Backend - Uses service role (full access)
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);
```

---

## API Security

### 1. Input Validation

All API endpoints validate inputs before processing:

```typescript
// Customer name: 2-50 chars, letters only
if (!/^[a-zA-Z\s]+$/.test(customerName)) {
  return res.status(400).json({ error: 'Invalid name' });
}

// Phone: Indian format (10 digits, starts with 6-9)
if (!/^[6-9]\d{9}$/.test(customerPhone)) {
  return res.status(400).json({ error: 'Invalid phone' });
}

// Quantity: 1-10 per item
if (quantity < 1 || quantity > 10) {
  return res.status(400).json({ error: 'Invalid quantity' });
}

// Amount: ₹50 - ₹10,000
if (totalAmount < 5000 || totalAmount > 1000000) {
  return res.status(400).json({ error: 'Invalid amount' });
}
```

### 2. Error Handling

**Never expose internal errors to client:**

```typescript
try {
  // ... operation
} catch (error) {
  // ✅ Log detailed error server-side
  console.error('Detailed error:', error);
  
  // ✅ Return generic message to client
  return res.status(500).json({ error: 'Internal server error' });
  
  // ❌ Never do this:
  // return res.status(500).json({ error: error.message });
}
```

### 3. CORS Configuration

Configure allowed origins in production:

```typescript
// vercel.json
{
  "headers": [
    {
      "source": "/api/(.*)",
      "headers": [
        { "key": "Access-Control-Allow-Origin", "value": "https://yoursite.vercel.app" },
        { "key": "Access-Control-Allow-Methods", "value": "POST, OPTIONS" }
      ]
    }
  ]
}
```

---

## Environment Variables

### Public vs Secret Keys

| Variable | Frontend | Backend | Secret? |
|----------|----------|---------|----------|
| `VITE_RAZORPAY_KEY_ID` | ✅ | ✅ | ❌ Public |
| `RAZORPAY_KEY_SECRET` | ❌ | ✅ | ✅ **SECRET** |
| `RAZORPAY_WEBHOOK_SECRET` | ❌ | ✅ | ✅ **SECRET** |
| `VITE_SUPABASE_URL` | ✅ | ✅ | ❌ Public |
| `VITE_SUPABASE_ANON_KEY` | ✅ | ✅ | ❌ Public (RLS protected) |
| `SUPABASE_SERVICE_KEY` | ❌ | ✅ | ✅ **SECRET** |

### Never Commit Secrets

```bash
# .gitignore
.env
.env.local
.env.*.local
```

### Vercel Environment Variables

1. Go to Project Settings → Environment Variables
2. Add each variable with appropriate scope:
   - Production
   - Preview
   - Development
3. Redeploy after adding variables

---

## Security Checklist

### Before Production

- [ ] All secrets in Vercel environment variables (not in code)
- [ ] `.env` added to `.gitignore`
- [ ] RLS enabled on all database tables
- [ ] RLS policies tested with different user scenarios
- [ ] Payment signature verification tested
- [ ] Webhook signature verification tested
- [ ] Input validation on all API endpoints
- [ ] Error messages don't expose sensitive data
- [ ] CORS configured for production domain only
- [ ] HTTPS enforced (automatic with Vercel)
- [ ] Rate limiting configured (Vercel automatic)

### Testing

- [ ] Test with Razorpay test mode keys
- [ ] Test with invalid signatures (should fail)
- [ ] Test with manipulated prices (should use server prices)
- [ ] Test duplicate webhook delivery (should be idempotent)
- [ ] Test RLS with different phone numbers
- [ ] Test input validation with malicious inputs

### Monitoring

- [ ] Set up error logging (Sentry, LogRocket, etc.)
- [ ] Monitor failed payment attempts
- [ ] Monitor invalid signature attempts
- [ ] Set up alerts for unusual activity

---

## PCI-DSS Compliance

### What We Don't Store (PCI Compliant)

✅ **Never stored on our servers:**
- Credit card numbers
- CVV codes
- Expiry dates
- Card holder names
- Any sensitive card data

### What We Do Store

✅ **Safe to store:**
- Razorpay Order IDs
- Razorpay Payment IDs
- Customer contact information
- Order details and amounts
- Payment status

**Why it's safe:** Razorpay is PCI Level 1 certified. All card data is handled by Razorpay, never touching our servers.

---

## Common Security Mistakes

### ❌ DON'T DO THIS

```typescript
// 1. Trusting client prices
const total = req.body.total; // ❌ Client can modify this

// 2. Exposing secrets in frontend
const secret = process.env.RAZORPAY_KEY_SECRET; // ❌ Leaked to client

// 3. Not verifying signatures
if (req.body.success) { // ❌ Anyone can send this
  markOrderAsPaid();
}

// 4. Using == for signature comparison
if (expectedSig == providedSig) { // ❌ Timing attack vulnerable
  // ...
}
```

### ✅ DO THIS INSTEAD

```typescript
// 1. Calculate prices on server
const total = items.reduce((sum, item) => 
  sum + MENU_PRICES[item.id] * item.quantity, 0
);

// 2. Use separate keys for frontend/backend
const keyId = process.env.VITE_RAZORPAY_KEY_ID; // Public
const secret = process.env.RAZORPAY_KEY_SECRET; // Backend only

// 3. Always verify signatures
const isValid = verifySignature(order_id, payment_id, signature);
if (isValid) { markOrderAsPaid(); }

// 4. Use timing-safe comparison
if (crypto.timingSafeEqual(Buffer.from(expectedSig), Buffer.from(providedSig))) {
  // ...
}
```

---

## Additional Resources

- [Razorpay Security Best Practices](https://razorpay.com/docs/payments/security/)
- [Supabase RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [PCI-DSS Requirements](https://www.pcisecuritystandards.org/)

---

## Support

For security concerns, please report to: your-email@example.com

**Do not** open public GitHub issues for security vulnerabilities.