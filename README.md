# MK Itinerary Maker

A free tool by MK Solutions for travel agents. An agent registers, sets up their profile once (logo, company details, bank details, default policies) and gets an MK Agent ID. Then they enter a trip and download a 6-page A4 PDF itinerary: cover, trip overview, day-wise plan with photos, quotation with GST, inclusions and exclusions, and policies and terms. There are 5 themes.

## Files

- `index.html`: the live tool. Upload this to the website, or turn on GitHub Pages for this repo. It is generated, so edit `src/index.html` instead.
- `src/index.html`: the source. With no database keys it runs in preview mode, where accounts stay in the browser.
- `build.sh`: run `sh build.sh` after editing the source. It writes `index.html` with the database keys added.
- `supabase/schema.sql`: database tables, row-level security and the Agent ID trigger (Supabase project "NK Itinerary Tool").

## Database setup notes

- In Supabase, go to Authentication, then URL Configuration, and set the Site URL to the address where the tool is hosted. The confirmation and password reset emails link there.
- The free Supabase email service sends only a few emails per hour. Connect your own SMTP before many agents sign up.
- The key in `build.sh` is the publishable (browser) key. Row-level security makes sure each agent can only see their own profile and trips.
