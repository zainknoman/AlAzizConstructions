/**
 * config.example.js — AAC Al Aziz Construction
 * ──────────────────────────────────────────────
 * ✅ THIS FILE IS SAFE TO COMMIT.
 *    It contains no real credentials.
 *
 * Setup instructions:
 *   1. Copy this file:   cp config.example.js config.js
 *   2. Open config.js and replace the placeholder values
 *   3. Get your values from:
 *        Supabase Dashboard → Settings → API
 *          • Project URL      → supabase_url
 *          • anon/public key  → supabase_key
 *
 * ⚠️  NEVER use the service_role key here.
 *     The anon/public key is safe for frontend use.
 *     The service_role key bypasses all RLS — keep it secret.
 */

window.AAC_CONFIG = {
  supabase_url : 'https://YOUR_PROJECT_ID.supabase.co',
  supabase_key : 'YOUR_ANON_PUBLIC_KEY',
};
