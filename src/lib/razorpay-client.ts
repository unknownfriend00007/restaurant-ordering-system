import { RazorpayOptions, RazorpayResponse } from '@/types';
import { loadRazorpayScript } from './utils';

/**
 * Initialize and display Razorpay checkout
 * @param options Razorpay checkout options
 * @returns Promise that resolves when checkout is initialized
 */
export async function displayRazorpay(
  options: RazorpayOptions
): Promise<void> {
  // Load Razorpay script
  const isLoaded = await loadRazorpayScript();

  if (!isLoaded) {
    throw new Error(
      'Failed to load Razorpay SDK. Please check your internet connection.'
    );
  }

  if (!window.Razorpay) {
    throw new Error('Razorpay SDK not available');
  }

  // Create and open Razorpay checkout
  const razorpay = new window.Razorpay(options);
  razorpay.open();
}

/**
 * Create order via backend API
 */
export async function createOrder(data: {
  items: any[];
  totalAmount: number;
  customerName: string;
  customerPhone: string;
  customerAddress: string;
}): Promise<any> {
  const response = await fetch('/api/create-order', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Failed to create order');
  }

  return response.json();
}

/**
 * Verify payment via backend API
 */
export async function verifyPayment(data: {
  razorpay_order_id: string;
  razorpay_payment_id: string;
  razorpay_signature: string;
}): Promise<any> {
  const response = await fetch('/api/verify-payment', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(data),
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.error || 'Payment verification failed');
  }

  return response.json();
}