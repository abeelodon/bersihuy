# Midtrans Sandbox Edge Functions

Functions:

- `create-midtrans-transaction`
- `check-midtrans-payment`

Required secrets:

```text
MIDTRANS_SERVER_KEY=SB-Mid-server-...
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
SUPABASE_SERVICE_ROLE_KEY=...
```

The hosted Supabase environment provides the Supabase variables by default.
Set the Midtrans key with Supabase secrets and never commit a real `.env` file.

Both functions expect an authenticated customer JWT. Keep JWT verification
enabled when deploying them.
