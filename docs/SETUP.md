# 🚀 Complete Setup Guide

Step-by-step guide to set up and deploy the Restaurant Ordering System.

## Prerequisites

- Node.js 18+ installed
- pnpm installed (`npm install -g pnpm`)
- Git installed
- GitHub account
- Razorpay account
- Supabase account
- Vercel account

---

## Part 1: Local Development Setup

### 1. Clone Repository

```bash
git clone https://github.com/unknownfriend00007/restaurant-ordering-system.git
cd restaurant-ordering-system
```

### 2. Install Dependencies

```bash
pnpm install
```

This installs:
- React 18
- TypeScript
- Vite
- Tailwind CSS
- shadcn/ui components
- Razorpay SDK
- Supabase client
- React Router

### 3. Set Up Environment Variables

Create `.env` file in root directory:

```bash
cp .env.example .env
```

Edit `.env` with your credentials (we'll get these next).

---

## Part 2: Razorpay Setup

### 1. Create Razorpay Account

1. Go to [razorpay.com](https://razorpay.com)
2. Sign up for free account
3. Complete KYC verification (required for production)

### 2. Get API Keys

1. Go to Settings → API Keys
2. Generate Test Mode keys
3. Copy:
   - **Key ID** (starts with `rzp_test_`)
   - **Key Secret** (starts with `secret_`)

### 3. Set Up Webhook

1. Go to Settings → Webhooks
2. Click "Add New Webhook"
3. Enter webhook URL: `https://your-site.vercel.app/api/webhook`
4. Select events:
   - `payment.captured`
   - `payment.failed`
   - `refund.processed`
5. Copy **Webhook Secret** (starts with `whsec_`)

### 4. Update .env

```env
RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxxx
VITE_RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=secret_xxxxxxxxxxxxxx
RAZORPAY_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxxx
```

---

## Part 3: Supabase Setup

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Choose organization and database password
4. Wait for project to initialize (~2 minutes)

### 2. Get API Credentials

1. Go to Project Settings → API
2. Copy:
   - **Project URL**
   - **anon/public key**
   - **service_role key** (click to reveal)

### 3. Update .env

```env
SUPABASE_URL=https://xxxxxxxxxxxxxx.supabase.co
VITE_SUPABASE_URL=https://xxxxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 4. Create Database Schema

1. Go to SQL Editor in Supabase dashboard
2. Copy contents of `database/schema.sql`
3. Paste and click "Run"
4. Verify table created: Table Editor → orders

### 5. Enable Row Level Security

Already included in schema.sql, but verify:

1. Go to Authentication → Policies
2. Select `orders` table
3. Should see 3 policies:
   - Customers can view own orders (SELECT)
   - Service role can insert orders (INSERT)
   - Service role can update orders (UPDATE)

---

## Part 4: Local Development

### 1. Start Development Server

```bash
pnpm dev
```

Server starts at: http://localhost:5173

### 2. Test Payment Flow

**Test Cards (Razorpay Test Mode):**

✅ **Success:**
- Card: `4111 1111 1111 1111`
- CVV: Any 3 digits
- Expiry: Any future date
- Name: Any name

❌ **Failure:**
- Card: `4000 0000 0000 0002`

**Test UPI:**
- UPI ID: `success@razorpay`

### 3. Test Webhook Locally

For local webhook testing:

```bash
# Install ngrok
npm install -g ngrok

# Start ngrok tunnel
ngrok http 5173

# Copy HTTPS URL (e.g., https://xxxx.ngrok.io)
# Update Razorpay webhook URL to: https://xxxx.ngrok.io/api/webhook
```

---

## Part 5: Vercel Deployment

### 1. Connect GitHub to Vercel

1. Go to [vercel.com](https://vercel.com)
2. Sign in with GitHub
3. Click "Add New" → "Project"
4. Import `restaurant-ordering-system` repository

### 2. Configure Build Settings

Vercel auto-detects Vite. Verify:

- **Framework Preset:** Vite
- **Build Command:** `pnpm build`
- **Output Directory:** `dist`
- **Install Command:** `pnpm install`

### 3. Add Environment Variables

**Important:** Add ALL variables from `.env` to Vercel:

1. Go to Project Settings → Environment Variables
2. Add each variable:

```
RAZORPAY_KEY_ID = rzp_test_...
VITE_RAZORPAY_KEY_ID = rzp_test_...
RAZORPAY_KEY_SECRET = secret_...
RAZORPAY_WEBHOOK_SECRET = whsec_...
SUPABASE_URL = https://...supabase.co
VITE_SUPABASE_URL = https://...supabase.co
SUPABASE_ANON_KEY = eyJhbGciOi...
VITE_SUPABASE_ANON_KEY = eyJhbGciOi...
SUPABASE_SERVICE_KEY = eyJhbGciOi...
VITE_APP_NAME = Your Restaurant Name
VITE_APP_URL = https://your-site.vercel.app
```

3. Set scope for each:
   - ✅ Production
   - ✅ Preview
   - ✅ Development

### 4. Deploy

1. Click "Deploy"
2. Wait for build to complete (~2 minutes)
3. Get deployment URL (e.g., `your-site.vercel.app`)

### 5. Update Razorpay Webhook URL

1. Go to Razorpay → Settings → Webhooks
2. Update webhook URL to: `https://your-site.vercel.app/api/webhook`
3. Save changes

### 6. Test Production Deployment

1. Visit your Vercel URL
2. Add items to cart
3. Complete test payment
4. Verify order in Supabase

---

## Part 6: Database Management

### View Orders

1. Go to Supabase → Table Editor → orders
2. See all orders with details

### Query Orders

```sql
-- Get all paid orders
SELECT * FROM orders WHERE payment_status = 'paid';

-- Get orders by phone
SELECT * FROM orders WHERE customer_phone = '9876543210';

-- Get today's orders
SELECT * FROM orders WHERE DATE(created_at) = CURRENT_DATE;

-- Calculate total revenue
SELECT SUM(total_amount) as total_revenue 
FROM orders 
WHERE payment_status = 'paid';
```

### Backup Database

```bash
# Using Supabase CLI
supabase db dump -f backup.sql
```

---

## Part 7: Going to Production

### 1. Switch to Live Mode

**Razorpay:**
1. Complete full KYC verification
2. Switch to Live Mode in dashboard
3. Generate Live API keys
4. Update Vercel environment variables with live keys

**Update these in Vercel:**
```
RAZORPAY_KEY_ID = rzp_live_...
VITE_RAZORPAY_KEY_ID = rzp_live_...
RAZORPAY_KEY_SECRET = [live secret]
RAZORPAY_WEBHOOK_SECRET = [live webhook secret]
```

### 2. Custom Domain (Optional)

1. Buy domain from Namecheap/GoDaddy
2. In Vercel: Settings → Domains
3. Add custom domain
4. Update DNS records (Vercel provides instructions)
5. Wait for SSL certificate (~10 minutes)

### 3. Production Checklist

- [ ] All environment variables use LIVE keys
- [ ] Razorpay KYC completed
- [ ] Custom domain configured (optional)
- [ ] SSL certificate active (HTTPS)
- [ ] Webhook URL updated to production domain
- [ ] Test end-to-end payment flow
- [ ] Monitor first few transactions closely
- [ ] Set up error monitoring (Sentry)
- [ ] Set up analytics (Google Analytics)

---

## Troubleshooting

### Payment Not Verifying

**Problem:** Payment succeeds but order status doesn't update.

**Solutions:**
1. Check Vercel function logs: Vercel → Project → Functions → Logs
2. Verify webhook is receiving events: Razorpay → Webhooks → View Logs
3. Check signature verification is passing
4. Ensure `RAZORPAY_KEY_SECRET` is correct in Vercel

### Webhook Not Working

**Problem:** Razorpay shows webhook failed.

**Solutions:**
1. Verify webhook URL is correct
2. Check `RAZORPAY_WEBHOOK_SECRET` in Vercel
3. Review webhook response in Razorpay dashboard
4. Test webhook manually with cURL:

```bash
curl -X POST https://your-site.vercel.app/api/webhook \
  -H "Content-Type: application/json" \
  -H "x-razorpay-signature: test" \
  -d '{"event":"payment.captured"}'
```

### Database Connection Failed

**Problem:** Can't connect to Supabase.

**Solutions:**
1. Verify `SUPABASE_URL` is correct
2. Check API keys are not expired
3. Ensure RLS policies don't block access
4. Test connection in Supabase SQL editor

### Build Failing on Vercel

**Problem:** Deployment fails during build.

**Solutions:**
1. Check build logs in Vercel
2. Verify all dependencies in `package.json`
3. Test build locally: `pnpm build`
4. Clear Vercel cache and rebuild
5. Check Node.js version compatibility

---

## Monitoring & Maintenance

### Set Up Monitoring

**Error Tracking:**
```bash
pnpm add @sentry/react
```

**Analytics:**
```bash
pnpm add react-ga4
```

### Regular Tasks

**Daily:**
- Monitor failed payments
- Check error logs
- Review customer orders

**Weekly:**
- Database backup
- Review security logs
- Update menu prices if needed

**Monthly:**
- Update dependencies: `pnpm update`
- Review RLS policies
- Check for security updates

---

## Scaling & Optimization

### Performance Optimization

1. **Enable Vercel Analytics:**
   - Project Settings → Analytics
   - Monitor Core Web Vitals

2. **Image Optimization:**
   - Use WebP format for menu images
   - Lazy load images
   - Use Vercel Image Optimization

3. **Code Splitting:**
   - Already configured with Vite
   - Routes lazy-loaded automatically

### Handling High Traffic

1. **Database:**
   - Upgrade Supabase plan if needed
   - Add database indexes:
   ```sql
   CREATE INDEX idx_orders_phone ON orders(customer_phone);
   CREATE INDEX idx_orders_status ON orders(payment_status);
   ```

2. **Serverless Functions:**
   - Vercel automatically scales
   - Monitor usage in dashboard
   - Upgrade plan if hitting limits

---

## Support

For help:
- GitHub Issues: [Report Issue](https://github.com/unknownfriend00007/restaurant-ordering-system/issues)
- Documentation: Check `/docs` folder
- Razorpay Support: support@razorpay.com
- Supabase Support: support@supabase.com

---

## Next Steps

After setup:
1. Customize restaurant info in `src/data/restaurant.ts`
2. Update menu items in `src/data/menu.ts`
3. Customize colors in `tailwind.config.js`
4. Add your logo and images
5. Test thoroughly before going live!

**Good luck with your restaurant! 🍕🎉**