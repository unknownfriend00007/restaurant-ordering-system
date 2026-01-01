# 🚀 Deployment Checklist

## Pre-Deployment Verification

### 1. Environment Variables

✅ **Verify all variables are set in Vercel:**

```bash
# Razorpay
RAZORPAY_KEY_ID
VITE_RAZORPAY_KEY_ID
RAZORPAY_KEY_SECRET
RAZORPAY_WEBHOOK_SECRET

# Supabase
SUPABASE_URL
VITE_SUPABASE_URL
SUPABASE_ANON_KEY
VITE_SUPABASE_ANON_KEY
SUPABASE_SERVICE_KEY

# App Config
VITE_APP_NAME
VITE_APP_URL
```

### 2. Database Setup

```bash
# Run this SQL in Supabase SQL Editor
cat database/schema.sql

# Verify tables created
SELECT * FROM orders LIMIT 1;

# Verify RLS enabled
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'orders';
```

### 3. Razorpay Configuration

- [ ] Webhook URL updated to production domain
- [ ] Webhook events configured: payment.captured, payment.failed, refund.processed
- [ ] Test mode keys for staging
- [ ] Live mode keys for production (after KYC)

### 4. Security Checklist

- [ ] All secrets in environment variables (not in code)
- [ ] `.env` in `.gitignore`
- [ ] RLS policies active on database
- [ ] CORS configured for production domain
- [ ] Error messages don't expose sensitive data
- [ ] Input validation on all endpoints

---

## Deployment Steps

### Step 1: Push to GitHub

```bash
git add .
git commit -m "Production ready"
git push origin main
```

### Step 2: Deploy to Vercel

1. Go to [vercel.com](https://vercel.com)
2. Import GitHub repository
3. Configure:
   - Framework: Vite
   - Build Command: `pnpm build`
   - Output Directory: `dist`
4. Add all environment variables
5. Deploy

### Step 3: Update Webhook URL

1. Get Vercel deployment URL
2. Go to Razorpay → Settings → Webhooks
3. Update URL to: `https://your-site.vercel.app/api/webhook`

### Step 4: Test End-to-End

```bash
# 1. Visit site
https://your-site.vercel.app

# 2. Add items to cart
# 3. Checkout
# 4. Complete test payment
# 5. Verify order in Supabase
```

---

## Post-Deployment

### Monitor First Transactions

```bash
# Watch Vercel function logs
Vercel Dashboard → Functions → Logs

# Watch Razorpay webhook logs
Razorpay Dashboard → Webhooks → View Logs

# Watch Supabase logs
Supabase Dashboard → Logs
```

### Set Up Monitoring

1. **Error Tracking:**
   ```bash
   pnpm add @sentry/react
   ```

2. **Analytics:**
   ```bash
   # Enable Vercel Analytics
   Project Settings → Analytics → Enable
   ```

3. **Uptime Monitoring:**
   - Use UptimeRobot or Pingdom
   - Monitor: `https://your-site.vercel.app/api/health`

---

## Going Live (Production Mode)

### 1. Complete Razorpay KYC

- Submit business documents
- Wait for verification (2-7 days)
- Activate live mode

### 2. Switch to Live Keys

```bash
# Update in Vercel Environment Variables
RAZORPAY_KEY_ID = rzp_live_...
VITE_RAZORPAY_KEY_ID = rzp_live_...
RAZORPAY_KEY_SECRET = [live secret]
RAZORPAY_WEBHOOK_SECRET = [live webhook secret]
```

### 3. Production Checklist

- [ ] Live Razorpay keys configured
- [ ] Webhook URL using live mode
- [ ] Database backups configured
- [ ] Error monitoring active
- [ ] Analytics tracking active
- [ ] Custom domain configured (optional)
- [ ] SSL certificate active
- [ ] Test with real payment

---

## Rollback Procedure

If something goes wrong:

```bash
# Vercel automatic rollback
1. Go to Deployments
2. Find previous working deployment
3. Click "..." menu
4. Select "Promote to Production"

# Database rollback
1. Run backup SQL file
2. Restore from Supabase backup
```

---

## Performance Optimization

### After Launch

1. **Enable Caching:**
   ```json
   // vercel.json
   {
     "headers": [
       {
         "source": "/assets/(.*)",
         "headers": [
           {
             "key": "Cache-Control",
             "value": "public, max-age=31536000, immutable"
           }
         ]
       }
     ]
   }
   ```

2. **Image Optimization:**
   - Use WebP format
   - Compress images
   - Use Vercel Image Optimization

3. **Database Indexing:**
   ```sql
   CREATE INDEX CONCURRENTLY idx_orders_phone_status 
   ON orders(customer_phone, payment_status);
   ```

---

## Maintenance Schedule

### Daily
- [ ] Check error logs
- [ ] Monitor failed payments
- [ ] Review customer orders

### Weekly
- [ ] Database backup
- [ ] Review security logs
- [ ] Update dependencies if needed

### Monthly
- [ ] Security audit
- [ ] Performance review
- [ ] Update documentation

---

## Support Contacts

**Razorpay Support:**
- Email: support@razorpay.com
- Phone: +91 80 6164 7482

**Supabase Support:**
- Email: support@supabase.com
- Discord: https://discord.supabase.com

**Vercel Support:**
- Email: support@vercel.com
- Twitter: @vercel

---

## Success Metrics

Track these after launch:

- ✅ Order completion rate
- ✅ Payment success rate
- ✅ Average order value
- ✅ Page load time
- ✅ Error rate
- ✅ Customer satisfaction

**Congratulations on your deployment! 🎉**