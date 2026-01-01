# Deployment Guide

Complete checklist for deploying to production.

## Pre-Deployment Checklist

### 1. Code Quality
- [ ] All TypeScript types defined (no `any`)
- [ ] ESLint passes with no errors
- [ ] All console.logs removed (except server logs)
- [ ] Commented code removed
- [ ] Build completes without warnings
- [ ] Bundle size optimized (<500KB gzipped)

### 2. Testing
- [ ] All payment flows tested (success/failure)
- [ ] Mobile responsive on iOS/Android
- [ ] Cross-browser tested (Chrome, Safari, Firefox)
- [ ] Webhook processing verified
- [ ] Order creation/retrieval working
- [ ] Cart functionality tested
- [ ] Form validation working
- [ ] Error states displayed correctly

### 3. Security
- [ ] Environment variables secured
- [ ] No secrets in code/Git history
- [ ] HTTPS enforced
- [ ] Security headers configured
- [ ] RLS policies tested
- [ ] Price verification working
- [ ] Signature verification working
- [ ] Input validation complete

### 4. Database
- [ ] Schema applied to production DB
- [ ] Menu items populated
- [ ] Indexes created
- [ ] RLS policies enabled
- [ ] Backup configured
- [ ] Connection pooling set up

### 5. Third-Party Services
- [ ] Razorpay Live mode enabled
- [ ] Live API keys obtained
- [ ] Webhook URL updated
- [ ] Webhook events subscribed
- [ ] Test payment in Live mode completed
- [ ] Supabase production tier selected

## Deployment Steps

### Step 1: Switch to Production Keys

#### Razorpay
1. Go to Razorpay Dashboard
2. Switch from Test to Live mode (top toggle)
3. Complete KYC if not done
4. Go to Settings → API Keys
5. Generate Live Keys
6. Copy Key ID and Key Secret

#### Supabase
1. Ensure on paid tier (free tier has limits)
2. Enable Point-in-Time Recovery (backups)
3. Set up daily backups
4. Configure connection pooling
5. Enable database replication (if needed)

### Step 2: Update Environment Variables

In Vercel dashboard:

```env
# Production Razorpay Keys
VITE_RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=<live_secret>          # Mark as Secret
RAZORPAY_WEBHOOK_SECRET=<webhook_secret>   # Mark as Secret

# Production Supabase
VITE_SUPABASE_URL=<production_url>
VITE_SUPABASE_ANON_KEY=<anon_key>
SUPABASE_SERVICE_KEY=<service_key>         # Mark as Secret

# Production App Config
VITE_APP_NAME="Your Restaurant Name"
VITE_APP_URL=https://your-domain.com
```

### Step 3: Deploy to Vercel

#### Via Git Push
```bash
git add .
git commit -m "Production ready"
git push origin main
```

Vercel auto-deploys from main branch.

#### Via Vercel CLI
```bash
npm i -g vercel
vercel login
vercel --prod
```

### Step 4: Configure Custom Domain

1. Go to Vercel project settings
2. Domains → Add Domain
3. Enter your domain (e.g., `order.yourrestaurant.com`)
4. Add DNS records as shown:
   - Type: A
   - Name: @ or subdomain
   - Value: 76.76.21.21
   - OR CNAME: cname.vercel-dns.com
5. Wait for DNS propagation (~1-24 hours)
6. Vercel auto-issues SSL certificate

### Step 5: Update Webhook URL

1. Razorpay Dashboard → Webhooks
2. Edit existing webhook or create new
3. Update URL to: `https://your-domain.com/api/webhook`
4. Verify signature is enabled
5. Save

### Step 6: Test in Production

#### Test Checklist
1. Visit production URL
2. Browse menu
3. Add items to cart
4. Go to checkout
5. Fill real details
6. Make small real payment (₹50)
7. Verify payment success
8. Check order in database
9. Verify webhook received
10. Test on mobile device

⚠️ **Important:** Use real payment for first test to verify Live mode working.

### Step 7: Monitor First Hours

**Monitor:**
- Vercel function logs
- Supabase database logs
- Razorpay dashboard (payments)
- Error tracking (if configured)

**Check every 30 minutes for first 2 hours:**
- Any failed payments?
- Webhook delivery success rate
- Order creation rate
- Database performance

## Post-Deployment

### Monitoring Setup

#### 1. Error Tracking (Optional but recommended)

**Sentry:**
```bash
pnpm add @sentry/react @sentry/vite-plugin
```

```typescript
// src/main.tsx
import * as Sentry from "@sentry/react";

Sentry.init({
  dsn: "your_sentry_dsn",
  environment: "production",
  tracesSampleRate: 1.0,
});
```

#### 2. Analytics (Optional)

**Plausible (Privacy-friendly):**
```html
<!-- index.html -->
<script defer data-domain="yourdomain.com" 
  src="https://plausible.io/js/script.js"></script>
```

#### 3. Uptime Monitoring

**Options:**
- [UptimeRobot](https://uptimerobot.com/) (Free)
- [Better Uptime](https://betteruptime.com/)
- [Pingdom](https://www.pingdom.com/)

Monitor:
- Homepage: `https://your-domain.com`
- API health: `https://your-domain.com/api/health` (create this)

### Performance Optimization

#### 1. Enable Vercel Analytics
```bash
pnpm add @vercel/analytics
```

```typescript
// src/main.tsx
import { Analytics } from '@vercel/analytics/react';

<App />
<Analytics />
```

#### 2. Image Optimization
- Compress images (use tinypng.com)
- Convert to WebP format
- Use lazy loading

#### 3. Code Splitting
```typescript
// Lazy load pages
const Menu = lazy(() => import('./pages/Menu'));
const Checkout = lazy(() => import('./pages/Checkout'));
```

#### 4. Database Optimization
- Enable connection pooling in Supabase
- Add indexes on frequently queried columns (already in schema)
- Monitor slow queries

### Backup Strategy

#### Database Backups
1. Supabase automatic daily backups (7 days retention)
2. Manual backups before major changes:
```sql
-- Export orders
COPY orders TO '/path/orders_backup.csv' CSV HEADER;
```

#### Code Backups
- Git repository (already backed up on GitHub)
- Tag releases:
```bash
git tag -a v1.0.0 -m "Production release"
git push origin v1.0.0
```

### Scaling Considerations

#### When to scale?
- >100 orders/hour
- >1000 concurrent users
- Database queries >500ms
- API response times >2s

#### Scaling Options

**Vercel:**
- Upgrade to Pro ($20/mo) for better limits
- Edge functions for lower latency

**Supabase:**
- Upgrade to Pro ($25/mo)
- Enable read replicas
- Increase connection pool

**Database:**
- Add caching layer (Redis)
- Denormalize frequently accessed data
- Implement database sharding (for very high scale)

**CDN:**
- Already included with Vercel
- Consider CloudFront for images

## Rollback Procedure

If deployment fails:

### Quick Rollback
1. Go to Vercel Dashboard
2. Deployments tab
3. Find last working deployment
4. Click "..." → "Promote to Production"

### Manual Rollback
```bash
git revert HEAD
git push origin main
```

### Emergency Maintenance Mode

Create `api/maintenance.ts`:
```typescript
export default function handler(req, res) {
  res.status(503).json({
    error: 'Scheduled maintenance. Please try again in 30 minutes.'
  });
}
```

Update routes to return maintenance response.

## Maintenance Schedule

### Daily
- [ ] Check error logs
- [ ] Monitor payment success rate
- [ ] Review customer support tickets

### Weekly
- [ ] Review performance metrics
- [ ] Check database size
- [ ] Update dependencies
- [ ] Backup database manually

### Monthly
- [ ] Security audit
- [ ] Review API usage
- [ ] Optimize slow queries
- [ ] Update documentation
- [ ] Review and respond to GitHub issues

### Quarterly
- [ ] Dependency major updates
- [ ] Security penetration test
- [ ] Performance benchmark
- [ ] Infrastructure cost review
- [ ] Feature planning

## Cost Estimation

### Free Tier (Testing/MVP)
- Vercel: Free (Hobby)
- Supabase: Free (500MB database, 2GB bandwidth)
- Razorpay: No monthly fee (2% + tax per transaction)
- Domain: ~₹500-1000/year

**Total:** ~₹1000/year + transaction fees

### Production (Small Scale)
- Vercel Pro: $20/month
- Supabase Pro: $25/month
- Razorpay: 2% + GST per transaction
- Domain: ~₹1000/year
- Error tracking: $0-29/month

**Total:** ~$45-74/month + transaction fees

### High Scale (1000+ orders/day)
- Vercel Pro: $20/month
- Supabase Pro: $25-100/month (depending on usage)
- Razorpay: Negotiated rates (1.5-2%)
- CDN: $10-50/month
- Monitoring: $50/month

**Total:** ~$105-220/month + transaction fees

## Support Contacts

**Vercel:**
- Dashboard: https://vercel.com/dashboard
- Support: support@vercel.com
- Discord: https://vercel.com/discord

**Supabase:**
- Dashboard: https://app.supabase.com
- Support: support@supabase.io
- Discord: https://discord.supabase.com

**Razorpay:**
- Dashboard: https://dashboard.razorpay.com
- Support: support@razorpay.com
- Phone: 1800-102-0098

## Success Metrics

Track these KPIs:
- Payment success rate (target: >95%)
- Average order value
- Cart abandonment rate (target: <30%)
- Page load time (target: <3s)
- API response time (target: <500ms)
- Uptime (target: 99.9%)
- Conversion rate (visitors → orders)

## Congratulations! 🎉

Your restaurant ordering system is now live in production!