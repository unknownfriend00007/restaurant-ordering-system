# Security Implementation Guide

This document explains the security measures implemented in the Restaurant Ordering System.

## 🔐 Architecture Overview

```
Client (Browser)
    |
    | 1. Create order request
    |
    v
Backend API (/api/create-order)
    |
    | 2. Validate & verify prices from DB
    | 3. Create Razorpay order
    |
    v
Client receives order_id
    |
    | 4. Show Razorpay checkout
    |
    v
Razorpay Payment Gateway
    |
    | 5. Payment completed
    |
    v
Backend API (/api/verify-payment)
    |
    | 6. Verify HMAC signature
    | 7. Update database
    |
    v
Razorpay Webhook (/api/webhook)
    |
    | 8. Verify webhook signature
    | 9. Final status update
```

## 1. Server-Side Price Verification

### Problem
Clients can manipulate JavaScript and send fake prices.

### Solution
Never trust client-submitted prices. Always recalculate on server.

```typescript
// ❌ WRONG - Trusting client price
const amount = req.body.total; // Client can send any value!

// ✅ CORRECT - Recalculate from database
const menuItems = await fetchMenuFromDB();
const calculatedTotal = cart.items.reduce((sum, item) => {
  const menuItem = menuItems.find(m => m.id === item.id);
  return sum + (menuItem.price * item.quantity);
}, 0);
```

### Implementation
1. Menu items stored in `menu_items` table with prices
2. Backend fetches current prices from database
3. Backend recalculates total independently
4. Compare calculated vs submitted (reject if mismatch)
5. Use calculated amount for Razorpay order

## 2. Cryptographic Payment Verification

### Problem
Attackers can fake payment success by calling verify endpoint directly.

### Solution
Verify HMAC-SHA256 signature provided by Razorpay.

```typescript
import crypto from 'crypto';

// Construct message exactly as Razorpay does
const message = razorpay_order_id + "|" + razorpay_payment_id;

// Calculate HMAC using your secret key
const expectedSignature = crypto
  .createHmac('sha256', RAZORPAY_KEY_SECRET)
  .update(message)
  .digest('hex');

// ⚠️ Use timing-safe comparison
const isValid = crypto.timingSafeEqual(
  Buffer.from(expectedSignature),
  Buffer.from(razorpay_signature)
);
```

### Why timing-safe comparison?
Prevents timing attacks where attackers measure response time to guess signature.

## 3. Webhook Security

### Problem
Anyone can POST to your webhook endpoint with fake data.

### Solution
Verify webhook signature before processing.

```typescript
// Get raw body (required for signature verification)
const rawBody = await getRawBody(req);

// Get signature from header
const signature = req.headers['x-razorpay-signature'];

// Calculate expected signature
const expectedSignature = crypto
  .createHmac('sha256', RAZORPAY_WEBHOOK_SECRET)
  .update(rawBody)
  .digest('hex');

// Verify
if (!crypto.timingSafeEqual(
  Buffer.from(expectedSignature),
  Buffer.from(signature)
)) {
  throw new Error('Invalid signature');
}
```

### Idempotency
Same payment might trigger webhook multiple times. Use idempotent processing:

```typescript
// Check if payment already processed
const existingOrder = await db.findOne({
  razorpay_payment_id: payment.id
});

if (existingOrder.payment_status === 'paid') {
  return { status: 'already_processed' };
}

// Update only if not already paid
if (event.event === 'payment.captured' && 
    existingOrder.payment_status !== 'paid') {
  await db.update({
    payment_status: 'paid',
    paid_at: new Date()
  });
}
```

## 4. Environment Variables

### Public vs Secret Keys

**Public Keys** (VITE_ prefix):
- Bundled into frontend JavaScript
- Visible to anyone
- Safe: `VITE_RAZORPAY_KEY_ID`, `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`

**Secret Keys** (No prefix):
- Only accessible to backend
- Never sent to client
- Critical: `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`, `SUPABASE_SERVICE_KEY`

### Vercel Configuration
```env
# Frontend + Backend (not sensitive)
VITE_RAZORPAY_KEY_ID=rzp_test_xxx
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...

# Backend ONLY (mark as Secret in Vercel)
RAZORPAY_KEY_SECRET=secret_xxx        # ⚠️ Secret
RAZORPAY_WEBHOOK_SECRET=whsec_xxx     # ⚠️ Secret
SUPABASE_SERVICE_KEY=eyJ...           # ⚠️ Secret
```

## 5. Input Validation

### Never trust user input

```typescript
// Validation functions
function validatePhone(phone: string): boolean {
  // Indian mobile: 10 digits, starts with 6-9
  return /^[6-9][0-9]{9}$/.test(phone);
}

function validateName(name: string): boolean {
  // 2-50 characters, letters and spaces only
  return /^[a-zA-Z\s]{2,50}$/.test(name.trim());
}

function validateAddress(address: string): boolean {
  const trimmed = address.trim();
  return trimmed.length >= 10 && trimmed.length <= 200;
}

function validateQuantity(qty: number): boolean {
  return Number.isInteger(qty) && qty >= 1 && qty <= 10;
}

function validateAmount(amount: number): boolean {
  return amount >= 50 && amount <= 10000;
}

// Apply before processing
if (!validatePhone(customerPhone)) {
  throw new Error('Invalid phone number');
}
```

### SQL Injection Prevention
Use parameterized queries (Supabase client handles this):

```typescript
// ✅ Safe - parameterized
const { data } = await supabase
  .from('orders')
  .select('*')
  .eq('customer_phone', phone);

// ❌ Dangerous - string concatenation
const query = `SELECT * FROM orders WHERE phone='${phone}'`;
```

## 6. Database Security (RLS)

### Row Level Security Policies

```sql
-- Customers can only see their own orders
CREATE POLICY "Customers can view own orders"
    ON orders FOR SELECT
    USING (customer_phone = current_setting('app.customer_phone', true));

-- Only service role can create orders
CREATE POLICY "Service role can insert orders"
    ON orders FOR INSERT
    WITH CHECK (auth.role() = 'service_role');

-- No one can delete orders
CREATE POLICY "No one can delete orders"
    ON orders FOR DELETE
    USING (false);
```

### Using Service Role in Backend

```typescript
// Frontend - uses anon key with RLS
const supabase = createClient(
  process.env.VITE_SUPABASE_URL,
  process.env.VITE_SUPABASE_ANON_KEY
);

// Backend - uses service key (bypasses RLS)
const supabaseAdmin = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY,
  {
    auth: { persistSession: false }
  }
);
```

## 7. Error Handling

### Never expose internal details to client

```typescript
// ❌ Bad - exposes internals
catch (error) {
  res.json({ error: error.message }); // Might reveal DB structure
}

// ✅ Good - generic message + server logging
catch (error) {
  console.error('[CREATE_ORDER_ERROR]', error); // Log server-side
  res.status(500).json({ 
    error: 'Failed to create order. Please try again.' 
  });
}
```

## 8. PCI-DSS Compliance

### What NOT to store:
- ❌ Full credit card numbers
- ❌ CVV/CVC codes
- ❌ PIN numbers
- ❌ Magnetic stripe data

### What you CAN store:
- ✅ Razorpay Order ID
- ✅ Razorpay Payment ID
- ✅ Payment status
- ✅ Last 4 digits (if provided by Razorpay)
- ✅ Card brand (Visa/Mastercard)

### Implementation
All sensitive card data stays with Razorpay (PCI Level 1 certified). We only store payment references.

## 9. HTTPS/TLS

### Production Requirements
- ✅ HTTPS only (automatic with Vercel)
- ✅ TLS 1.2 or higher
- ✅ Valid SSL certificate
- ✅ Redirect HTTP to HTTPS

### Security Headers
```json
// vercel.json
{
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "X-Frame-Options", "value": "DENY" },
        { "key": "X-XSS-Protection", "value": "1; mode=block" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" }
      ]
    }
  ]
}
```

## 10. Rate Limiting (Future)

For production, implement rate limiting:

```typescript
// Limit: 10 order creation attempts per IP per hour
// Limit: 20 payment verifications per IP per hour
// Use Upstash Redis or Vercel Edge Config
```

## Security Checklist

Before production:

- [ ] All secret keys stored in environment variables
- [ ] No secrets in Git history
- [ ] Server-side price verification working
- [ ] Payment signature verification working
- [ ] Webhook signature verification working
- [ ] Input validation on all fields
- [ ] RLS policies enabled and tested
- [ ] HTTPS enforced
- [ ] Security headers configured
- [ ] Error messages don't leak internals
- [ ] No card data stored in database
- [ ] Idempotent webhook processing
- [ ] Timing-safe comparisons for signatures
- [ ] Service role key secured
- [ ] Regular dependency updates
- [ ] Security audit completed

## Testing Security

### Price Manipulation Test
1. Open browser DevTools
2. Modify cart prices in localStorage
3. Try to checkout
4. Backend should reject or recalculate

### Fake Payment Test
1. Try calling `/api/verify-payment` with fake signature
2. Should return 400/401 error
3. Database should not update

### Webhook Forgery Test
1. Try POSTing to `/api/webhook` without signature
2. Should return 401
3. Try with wrong signature
4. Should return 401

## Incident Response

If security breach detected:

1. **Immediate:**
   - Rotate all API keys
   - Disable webhook temporarily
   - Check database for unauthorized changes

2. **Investigation:**
   - Review server logs
   - Check Razorpay dashboard for anomalies
   - Identify breach source

3. **Recovery:**
   - Fix vulnerability
   - Deploy patch
   - Notify affected customers (if applicable)
   - Document incident

## Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Razorpay Security Best Practices](https://razorpay.com/docs/payments/security/)
- [Supabase Security](https://supabase.com/docs/guides/auth/row-level-security)
- [PCI-DSS Compliance](https://www.pcisecuritystandards.org/)

## Regular Security Maintenance

**Weekly:**
- Review error logs
- Check for failed payment attempts
- Monitor webhook failures

**Monthly:**
- Update dependencies (`pnpm update`)
- Review RLS policies
- Audit new orders for anomalies

**Quarterly:**
- Full security audit
- Penetration testing
- Update documentation
- Review and rotate API keys