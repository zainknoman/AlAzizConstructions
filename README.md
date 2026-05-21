# 🏗️ AAC – Al Aziz Construction
### *Karachi's Trusted Builders — Full-Stack Website & CMS*

[![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Vue.js](https://img.shields.io/badge/Vue_3-4FC08D?style=for-the-badge&logo=vuedotjs&logoColor=white)](https://vuejs.org)
[![TailwindCSS](https://img.shields.io/badge/Tailwind_CSS-38B2AC?style=for-the-badge&logo=tailwind-css&logoColor=white)](https://tailwindcss.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![HTML5](https://img.shields.io/badge/HTML5-E34F26?style=for-the-badge&logo=html5&logoColor=white)](https://developer.mozilla.org/en-US/docs/Web/HTML)

> A production-ready **construction company website** paired with a **secure admin CMS panel** — both powered by Supabase (PostgreSQL) with Row Level Security. All content is managed dynamically with no HTML editing required.

---

## 📸 Screenshots

| Public Website | Admin CMS Dashboard |
|---|---|
| Hero · Services · Projects · Testimonials · Contact | Dashboard · Leads · Appointments · Content Management |

---

## 🗂️ Project Structure

```
AAC-WEBSITE/
├── aac_website.html        # Public-facing marketing website
├── aac_admin.html          # Secure admin CMS panel
└── aac_supabase_setup.sql  # Full database schema + seed data
```

> **Zero dependencies to install.** Both HTML files are fully self-contained — all libraries are loaded from CDN.

---

## ✨ Features

### 🌐 Public Website (`aac_website.html`)
- **Dynamic content rendering** — all sections load from Supabase in real-time
- **Hero section** — editable headline, subtext, stats, CTA buttons
- **Services section** — dynamically rendered service cards with bullet lists
- **Projects portfolio** — filterable grid (Residential / Commercial / Renovation)
- **Testimonials slider** — auto-advancing carousel, 3 per slide
- **Contact section** — live phone numbers, email, address, working hours, map link
- **WhatsApp FAB** — floating click-to-chat button with dynamic number
- **Lead capture form** — saves directly to Supabase `leads` table
- **Scroll animations** — IntersectionObserver-based reveal on all sections
- **Fully responsive** — mobile, tablet, desktop
- **SEO meta tags** — description, keywords, structured title

### 🔐 Admin CMS (`aac_admin.html`)
- **Supabase Auth** — email + password login
- **Double-layer security** — Auth credentials *and* `admins` table membership required
- **Dashboard** — 5 stat cards, recent leads, recent appointments, quick actions
- **Hero management** — edit heading, subtext, tagline, stats, CTA buttons with live preview
- **Services CRUD** — add, edit, delete service cards with emoji, badge, bullet list
- **Projects CRUD** — add, edit, delete, publish/unpublish portfolio projects
- **Testimonials CRUD** — add, edit, delete, publish/unpublish reviews with star picker
- **Contact info editor** — phones, WhatsApp, email, address, hours, social links
- **Leads management** — view, search, mark as contacted, delete, export CSV/JSON
- **Appointment requests** — status workflow (New → Contacted → Closed), export CSV
- **Import/Export** — full JSON backup + per-table CSV export
- **Collapsible sidebar** — icon-only or full-label mode
- **Toast notifications** — success/error/info feedback on every action
- **Confirm dialogs** — safe delete with confirmation prompt

### 🗄️ Database (Supabase / PostgreSQL)
- **8 tables** — `admins`, `website_content`, `services`, `projects`, `project_images`, `testimonials`, `leads`, `appointments`
- **Row Level Security** — every table protected with per-role policies
- **`is_admin()` function** — validates admin access via `auth.users` ↔ `admins` join
- **Public read** — services, published projects, published testimonials, website content
- **Public insert** — leads and appointments (contact form, no auth required)
- **Admin full access** — all tables, all operations, authenticated + in admins table only
- **Indexes** — optimised queries on published, category, status, created_at

---

## 🚀 Quick Start

### 1. Run the Database Schema

1. Go to **Supabase Dashboard → SQL Editor**
2. Paste the contents of `aac_supabase_setup.sql` and click **Run**
3. This creates all 8 tables, RLS policies, indexes, and seed data

### 2. Create the Admin User

```
Dashboard → Authentication → Users → Add User
  Email   : admin@yourdomain.com
  Password: (strong password)
  ✓ Auto Confirm Email → Create User
```

Then copy the new user's UUID and run:

```sql
insert into public.admins (id, email)
values ('PASTE-UUID-HERE', 'admin@yourdomain.com');
```

### 3. Add Credentials to Both HTML Files

In **both** `aac_admin.html` and `aac_website.html`, find and update:

```js
const SUPABASE_URL      = 'https://YOUR_PROJECT.supabase.co';
const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
```

Your values: **Dashboard → Settings → API**
- Project URL → `SUPABASE_URL`
- `anon / public` key → `SUPABASE_ANON_KEY` *(never use the `service_role` key in frontend files)*

### 4. Serve the Files

Open via a local server — **do not open as `file://`** (browser blocks Supabase auth iframes):

```bash
# Python (no install)
python -m http.server 8080

# Node
npx serve .
```

Then visit:
- `http://localhost:8080/aac_website.html` — public site
- `http://localhost:8080/aac_admin.html`   — admin panel

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Frontend — Website** | Vanilla JS, HTML5, CSS3 |
| **Frontend — Admin** | Vue 3 (CDN), Tailwind CSS (CDN) |
| **Database** | Supabase (PostgreSQL) |
| **Authentication** | Supabase Auth (PKCE flow) |
| **File Storage** | Supabase Storage |
| **Fonts** | Google Fonts — Oswald, Source Sans 3, Rajdhani |
| **Hosting** | Any static host (Netlify, Vercel, GitHub Pages, cPanel) |

---

## 🗄️ Database Schema

```
admins              — admin email allowlist (id, email, role)
website_content     — key-value CMS (hero, contact) as JSONB
services            — service cards (title, emoji, badge, bullets, sort_order)
projects            — portfolio items (title, category, location, year, published)
project_images      — gallery images per project (project_id FK)
testimonials        — customer reviews (name, rating, text, published)
leads               — contact form submissions (name, phone, email, service)
appointments        — appointment requests (name, service, date, status)
```

### RLS Policy Design

```
┌──────────────────────┬──────────────────┬─────────────────────┐
│ Table                │ Public (anon)    │ Admin (is_admin())  │
├──────────────────────┼──────────────────┼─────────────────────┤
│ website_content      │ SELECT           │ ALL                 │
│ services             │ SELECT           │ ALL                 │
│ projects             │ SELECT published │ ALL (incl. drafts)  │
│ testimonials         │ SELECT published │ ALL (incl. drafts)  │
│ leads                │ INSERT           │ ALL                 │
│ appointments         │ INSERT           │ ALL                 │
│ admins               │ —                │ SELECT own row      │
└──────────────────────┴──────────────────┴─────────────────────┘
```

---

## 🔒 Security Model

Access to the admin panel requires **two independent checks to pass**:

1. **Supabase Auth** — valid email + password credentials
2. **`is_admin()` RLS function** — email must exist in `public.admins` table

```sql
-- Even a valid Supabase Auth user is rejected if not in admins:
create function is_admin() returns boolean as $$
  select exists (
    select 1 from admins a
    join auth.users u on u.email = a.email
    where u.id = auth.uid()
  );
$$ language sql security definer stable;
```

To revoke admin access: `DELETE FROM admins WHERE email = 'user@example.com';`
The Supabase Auth account remains but the user can no longer log into the CMS.

---

## 📦 Data Management

### Export (from Admin → Import/Export tab)
| Export | Format | Contents |
|---|---|---|
| Full JSON Backup | `.json` | All tables, hero, contact |
| Leads | `.csv` or `.json` | Lead submissions |
| Appointments | `.csv` | Appointment requests |
| Projects | `.csv` | Portfolio items |

### Import
Drag & drop any previously exported JSON backup into the Import panel to restore all data.

---

## 🌍 Deployment

The project is two static HTML files — deploy anywhere:

### Netlify / Vercel (Recommended)
```bash
# Drop both HTML files into a folder and drag to netlify.com/drop
# Or connect your GitHub repo for auto-deploy
```

### GitHub Pages
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/yourusername/aac-website.git
git push -u origin main
# Enable Pages in repo Settings → Pages → Branch: main
```

### cPanel / Shared Hosting
Upload both HTML files to `public_html/` via File Manager or FTP.

> **Note:** After deploying, add your domain to **Supabase Dashboard → Authentication → URL Configuration → Site URL** to allow auth redirects.

---

## 🗺️ Roadmap

- [ ] Image upload via Supabase Storage (project thumbnails)
- [ ] Appointment booking form on public website
- [ ] Email notifications on new leads (Supabase Edge Functions)
- [ ] Google Analytics integration
- [ ] Multi-language support (English / Urdu)
- [ ] PWA / offline support

---

## 📞 Contact

**AAC – Al Aziz Construction**
📍 M-90, Munir Mobile Mall, Mezzanine Floor, Block-17, Gulistan-e-Johar, Karachi
📱 0344-6626122 · 0335-7550226 · 0304-2446322
✉️ shaikhms798@gmail.com

---

## 📄 License

This project is proprietary software developed for AAC – Al Aziz Construction.
All rights reserved © 2025 AAC – Al Aziz Construction.

---

<div align="center">
  <strong>Built with ❤️ for Karachi's construction industry</strong><br/>
  <sub>Powered by Supabase · Vue 3 · Tailwind CSS</sub>
</div>
