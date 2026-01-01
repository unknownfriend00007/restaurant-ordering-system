# Complete Setup Guide

This guide will walk you through setting up the Restaurant Ordering System from scratch.

## Prerequisites

- Node.js 18+ and pnpm installed
- Razorpay account (test mode)
- Supabase account
- Vercel account (for deployment)
- Git installed

## Step 1: Clone Repository

```bash
git clone https://github.com/unknownfriend00007/restaurant-ordering-system.git
cd restaurant-ordering-system
```

## Step 2: Install Dependencies

```bash
pnpm install
```

## Step 3: Razorpay Setup

### 3.1 Create Razorpay Account
1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Sign up and complete verification
3. Switch to **Test Mode** (toggle in top bar)

### 3.2 Get API Keys
1. Navigate to Settings → API Keys
2. Generate Test Keys
3. Copy **Key ID** (starts with `rzp_test_`)
4. Copy **Key Secret** (keep this secret!)

### 3.3 Setup Webhook
1. Go to Settings → Webhooks
2. Click "+ New Webhook"
3. Enter webhook URL: `https://yoursite.vercel.app/api/webhook`
4. Select events:
   - `payment.authorized`
   - `payment.captured`
   - `payment.failed`
5. Set Secret: Generate a random string (or let Razorpay generate)
6. Save webhook and copy the secret

## Step 4: Supabase Setup

### 4.1 Create Project
1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Click "New Project"
3. Fill in details and create
4. Wait for database provisioning (~2 minutes)

### 4.2 Run Database Schema
1. Go to SQL Editor in Supabase dashboard
2. Copy contents of `database/schema.sql`
3. Paste and run the query
4. Verify tables created successfully

### 4.3 Seed Menu Data (Optional)
1. Copy contents of `database/menu-seed.sql`
2. Run in SQL Editor
3. Verify menu items inserted

### 4.4 Get API Credentials
1. Go to Settings → API
2. Copy:
   - Project URL
   - `anon` public key
   - `service_role` secret key (keep secret!)

## Step 5: Environment Variables

Create `.env` file in project root:

```env
# Razorpay (from Step 3)
VITE_RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=your_secret_key_here
RAZORPAY_WEBHOOK_SECRET=your_webhook_secret_here

# Supabase (from Step 4)
VITE_SUPABASE_URL=https://xxxxxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# App Config
VITE_APP_NAME="My Restaurant"
VITE_APP_URL=http://localhost:3000
```

⚠️ **Security Note:** Never commit `.env` to Git! It's in `.gitignore` by default.

## Step 6: Run Development Server

```bash
pnpm dev
```

Open http://localhost:3000

## Step 7: Test Payment Flow

### Test Cards (Razorpay Test Mode)

**Successful Payment:**
- Card: `4111 1111 1111 1111`
- CVV: Any 3 digits
- Expiry: Any future date
- Name: Any name

**Failed Payment:**
- Card: `4000 0000 0000 0002`

**UPI (Test):**
- UPI ID: `success@razorpay`
- UPI ID (fail): `failure@razorpay`

### Test Workflow
1. Browse menu and add items to cart
2. Go to checkout
3. Fill customer details
4. Click "Proceed to Payment"
5. Razorpay modal opens
6. Select payment method and use test credentials
7. Complete payment
8. Verify order success page
9. Check Supabase database for order record

## Step 8: Verify Webhook

### Local Webhook Testing
Since webhooks need public URLs, use ngrok for local testing:

```bash
# Install ngrok
npm install -g ngrok

# Expose local port
ngrok http 3000

# Update webhook URL in Razorpay to:
https://your-ngrok-url.ngrok.io/api/webhook
```

### Webhook Verification
1. Make a test payment
2. Check Razorpay Dashboard → Webhooks → Logs
3. Verify webhook received and processed
4. Check database for updated payment status

## Step 9: Deploy to Vercel

### 9.1 Push to GitHub
```bash
git add .
git commit -m "Complete setup"
git push origin main
```

### 9.2 Connect to Vercel
1. Go to [Vercel Dashboard](https://vercel.com/)
2. Click "New Project"
3. Import your GitHub repository
4. Configure project:
   - Framework Preset: Vite
   - Build Command: `pnpm build`
   - Output Directory: `dist`

### 9.3 Add Environment Variables
Add all environment variables from `.env`:
- VITE_RAZORPAY_KEY_ID
- RAZORPAY_KEY_SECRET ⚠️
- RAZORPAY_WEBHOOK_SECRET ⚠️
- VITE_SUPABASE_URL
- VITE_SUPABASE_ANON_KEY
- SUPABASE_SERVICE_KEY ⚠️
- VITE_APP_NAME
- VITE_APP_URL (use Vercel URL)

⚠️ Mark sensitive keys as "Secret"

### 9.4 Deploy
1. Click "Deploy"
2. Wait for build to complete
3. Get deployment URL

### 9.5 Update Webhook URL
1. Go to Razorpay Dashboard
2. Update webhook URL to: `https://your-vercel-app.vercel.app/api/webhook`
3. Save changes

## Step 10: Production Checklist

Before going live:

- [ ] Switch Razorpay from Test to Live mode
- [ ] Get Live API keys from Razorpay
- [ ] Update environment variables with Live keys
- [ ] Update webhook URL with production domain
- [ ] Test complete payment flow in production
- [ ] Enable Supabase database backups
- [ ] Set up error monitoring (Sentry/LogRocket)
- [ ] Configure custom domain in Vercel
- [ ] Add SSL certificate (automatic with Vercel)
- [ ] Update `VITE_APP_URL` to custom domain
- [ ] Test on mobile devices
- [ ] Run security audit
- [ ] Set up database monitoring
- [ ] Configure rate limiting
- [ ] Add analytics (Google Analytics/Plausible)

## Troubleshooting

### Payment not processing
- Check browser console for errors
- Verify Razorpay keys in .env
- Check network tab for API failures
- Verify webhook URL is correct

### Database errors
- Check RLS policies are enabled
- Verify service key is used in backend
- Check SQL queries in Supabase logs

### Deployment issues
- Check Vercel build logs
- Verify all environment variables set
- Ensure API routes are in `/api` folder
- Check function logs in Vercel dashboard

### Webhook not receiving events
- Verify webhook URL is publicly accessible
- Check webhook signature verification
- Review Razorpay webhook logs
- Ensure correct events are subscribed

## Support

For issues:
1. Check [GitHub Issues](https://github.com/unknownfriend00007/restaurant-ordering-system/issues)
2. Review documentation
3. Check Razorpay/Supabase docs
4. Create new issue with details

## Next Steps

- Customize menu items in database
- Update restaurant branding
- Add more payment methods
- Implement order tracking
- Build admin dashboard
- Add email notifications
- Implement SMS updates