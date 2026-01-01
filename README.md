# Restaurant Online Ordering System

🍽️ A production-ready, secure restaurant online ordering system with Razorpay payment integration.

[![TypeScript](https://img.shields.io/badge/TypeScript-007ACC?style=flat&logo=typescript&logoColor=white)](https://www.typescriptlang.org/)
[![React](https://img.shields.io/badge/React-20232A?style=flat&logo=react&logoColor=61DAFB)](https://reactjs.org/)
[![Vite](https://img.shields.io/badge/Vite-646CFF?style=flat&logo=vite&logoColor=white)](https://vitejs.dev/)
[![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=flat&logo=tailwind-css&logoColor=white)](https://tailwindcss.com/)

## ✨ Features

### Customer Features
- 🏠 Beautiful landing page with restaurant info
- 📱 Mobile-first responsive design
- 🍔 Browse menu with images, descriptions, and prices
- 🛒 Shopping cart with add/remove/update quantities
- 💳 Secure Razorpay payment integration (UPI, Cards, Net Banking, Wallets)
- 📦 Order tracking and history
- ✅ Order success/failure pages
- 🔔 Toast notifications for feedback

### Security Features
- 🔒 Server-side price verification
- 🔐 Cryptographic payment signature verification (HMAC-SHA256)
- 🛡️ Webhook signature verification
- 🚫 Input validation and sanitization
- 📊 Row Level Security (RLS) on database
- 🔑 Environment variable security
- 🎯 PCI-DSS compliant (no card data stored)
- ⚡ Timing-safe comparison for signatures
- 🔄 Idempotent webhook processing

### Technical Features
- ⚛️ Built with React 18 + TypeScript
- 🎨 Styled with Tailwind CSS + shadcn/ui
- 🚀 Lightning-fast Vite build
- 📡 Vercel Serverless Functions for backend
- 🗄️ Supabase (PostgreSQL) database
- 🔀 React Router v6 for navigation
- 📦 pnpm for fast package management

## 🏗️ Architecture

```
┌─────────────┐
│   Client    │
│  (React)    │
└──────┬──────┘
       │
       ├──────────────────┐
       │                  │
       v                  v
┌──────────────┐   ┌──────────────┐
│   Vercel     │   │   Supabase   │
│  Functions   │◄─►│  (Database)  │
└──────┬───────┘   └──────────────┘
       │
       v
┌──────────────┐
│  Razorpay    │
│   Gateway    │
└──────────────┘
```

## 🚀 Quick Start

### Prerequisites
- Node.js 18+
- pnpm (`npm install -g pnpm`)
- Razorpay account
- Supabase account
- Vercel account (for deployment)

### Installation

1. **Clone repository**
```bash
git clone https://github.com/unknownfriend00007/restaurant-ordering-system.git
cd restaurant-ordering-system
```

2. **Install dependencies**
```bash
pnpm install
```

3. **Set up environment variables**
```bash
cp .env.example .env
# Edit .env with your keys
```

4. **Set up database**
- Run `database/schema.sql` in Supabase SQL Editor
- (Optional) Run `database/menu-seed.sql` for sample menu

5. **Start development server**
```bash
pnpm dev
```

Open http://localhost:3000

## 📚 Documentation

Detailed guides available in `/docs`:

- **[SETUP.md](docs/SETUP.md)** - Complete setup instructions
- **[SECURITY.md](docs/SECURITY.md)** - Security implementation details
- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Production deployment guide

## 🔒 Security Highlights

### Price Verification Flow
```typescript
// Backend recalculates prices from database
const menuItems = await fetchMenuFromDB();
const calculatedTotal = cart.items.reduce((sum, item) => {
  const menuItem = menuItems.find(m => m.id === item.id);
  return sum + (menuItem.price * item.quantity);
}, 0);

// Reject if client-submitted price doesn't match
if (Math.abs(calculatedTotal - submittedTotal) > 0.01) {
  throw new Error('Price mismatch');
}
```

### Payment Verification
```typescript
// Verify Razorpay signature
const message = `${order_id}|${payment_id}`;
const expectedSignature = crypto
  .createHmac('sha256', RAZORPAY_KEY_SECRET)
  .update(message)
  .digest('hex');

// Timing-safe comparison
const isValid = crypto.timingSafeEqual(
  Buffer.from(expectedSignature),
  Buffer.from(signature)
);
```

## 📁 Project Structure

```
restaurant-ordering-system/
├── src/
│   ├── components/       # React components
│   ├── pages/           # Page components
│   ├── lib/             # Utilities & clients
│   ├── context/         # State management
│   └── types/           # TypeScript types
├── api/                 # Serverless functions
│   ├── create-order.ts
│   ├── verify-payment.ts
│   └── webhook.ts
├── database/            # SQL schema & seeds
├── docs/                # Documentation
└── public/              # Static assets
```

## 🧪 Testing

### Test Cards (Razorpay Test Mode)

**Successful Payment:**
- Card: `4111 1111 1111 1111`
- CVV: Any 3 digits
- Expiry: Any future date

**Failed Payment:**
- Card: `4000 0000 0000 0002`

**Test UPI:**
- Success: `success@razorpay`
- Failure: `failure@razorpay`

## 📊 Database Schema

### Orders Table
- Order details and payment status
- Customer information
- Items (JSONB array)
- Payment tracking fields
- Timestamps

### Menu Items Table
- Source of truth for prices
- Categories and descriptions
- Availability flags
- Vegetarian indicators

### Security
- Row Level Security (RLS) enabled
- Parameterized queries
- No deletion policy (soft delete)

## 🌐 Deployment

### Deploy to Vercel

1. **Push to GitHub**
```bash
git push origin main
```

2. **Connect to Vercel**
- Import GitHub repository
- Add environment variables
- Deploy

3. **Update webhook URL**
- Set in Razorpay: `https://yoursite.vercel.app/api/webhook`

4. **Go live!**

See [DEPLOYMENT.md](docs/DEPLOYMENT.md) for complete guide.

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| Frontend | React 18, TypeScript, Vite |
| Styling | Tailwind CSS, shadcn/ui |
| Routing | React Router v6 |
| Backend | Vercel Serverless Functions |
| Database | Supabase (PostgreSQL) |
| Payments | Razorpay |
| Deployment | Vercel |
| Package Manager | pnpm |

## 📝 Environment Variables

```env
# Public (Frontend + Backend)
VITE_RAZORPAY_KEY_ID=rzp_test_xxx
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
VITE_APP_NAME="Restaurant Name"
VITE_APP_URL=https://yoursite.com

# Secret (Backend Only)
RAZORPAY_KEY_SECRET=secret_xxx
RAZORPAY_WEBHOOK_SECRET=whsec_xxx
SUPABASE_SERVICE_KEY=eyJ...
```

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

MIT License - see LICENSE file

## 🐛 Issues

Found a bug? [Open an issue](https://github.com/unknownfriend00007/restaurant-ordering-system/issues)

## 👨‍💻 Author

**unknownfriend00007**
- GitHub: [@unknownfriend00007](https://github.com/unknownfriend00007)

## 🙏 Acknowledgments

- [Razorpay](https://razorpay.com/) for payment gateway
- [Supabase](https://supabase.com/) for backend infrastructure
- [Vercel](https://vercel.com/) for hosting
- [shadcn/ui](https://ui.shadcn.com/) for beautiful components

## 📈 Roadmap

- [ ] Admin dashboard
- [ ] Real-time order tracking
- [ ] SMS notifications
- [ ] Email receipts
- [ ] Multiple restaurant support
- [ ] Loyalty program
- [ ] Promotional codes
- [ ] Order scheduling
- [ ] Reviews and ratings

---

⭐ Star this repo if you find it helpful!