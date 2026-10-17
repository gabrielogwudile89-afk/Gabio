# Novareach Digital Marketplace Starter

This project is a responsive marketplace starter for Netlify. It includes a landing page, searchable product/service listings, signup/login UI, Supabase-backed shared listings when configured, and a schema for profiles/listings/orders.

## Deploy on Android
1. Download and extract the ZIP.
2. Sign in at https://app.netlify.com and open your existing site's deploy page.
3. Upload the extracted project folder (or its contents through Netlify's manual deploy interface).
4. It first runs in preview mode with clearly labelled demo listings.
5. Create a project at https://supabase.com/dashboard.
6. In Supabase SQL Editor, run all of `supabase-schema.sql`.
7. Copy the Supabase Project URL and anon/public key from project settings.
8. Edit `config.js` and fill `supabaseUrl` and `supabaseAnonKey`. Only use the anon/public key, never `service_role`.
9. Redeploy to Netlify. Set the Site URL and allowed redirect URLs in Supabase Auth settings, then test signup and login.

## Important: not yet production-ready
Checkout, verified payment webhooks, seller payouts, refunds, messaging, image uploads, moderation/admin tools, delivery tracking, multi-currency support, and global tax/shipping policies are not implemented. The website does not currently accept payments. Do not accept customer money until secure server-side checkout and payment verification are built and tested. Never put payment secret keys or Supabase service-role keys in browser code. Confirm payment-provider support for your countries, business model, and seller payouts before launch.
