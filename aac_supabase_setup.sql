-- ╔══════════════════════════════════════════════════════════════╗
-- ║   AAC – Al Aziz Construction                                 ║
-- ║   Supabase SQL Setup — Tables · RLS · Policies · Admin User  ║
-- ║                                                              ║
-- ║   HOW TO RUN:                                                ║
-- ║   1. Go to Supabase Dashboard → SQL Editor                   ║
-- ║   2. Paste this entire file and click RUN                    ║
-- ║   3. Then follow STEP 7 at the bottom to create admin user   ║
-- ╚══════════════════════════════════════════════════════════════╝


-- ══════════════════════════════════════════════════════════════
-- STEP 0 — EXTENSIONS
-- ══════════════════════════════════════════════════════════════

create extension if not exists "uuid-ossp";


-- ══════════════════════════════════════════════════════════════
-- STEP 1 — DROP OLD POLICIES (safe re-run guard)
-- ══════════════════════════════════════════════════════════════

do $$ begin
  drop policy if exists "Admins: self read"          on admins;
  drop policy if exists "Admins: service role all"   on admins;
  drop policy if exists "Content: public read"       on website_content;
  drop policy if exists "Content: admin write"       on website_content;
  drop policy if exists "Services: public read"      on services;
  drop policy if exists "Services: admin write"      on services;
  drop policy if exists "Projects: public read"      on projects;
  drop policy if exists "Projects: admin write"      on projects;
  drop policy if exists "ProjectImages: public read" on project_images;
  drop policy if exists "ProjectImages: admin write" on project_images;
  drop policy if exists "Testimonials: public read"  on testimonials;
  drop policy if exists "Testimonials: admin write"  on testimonials;
  drop policy if exists "Leads: public insert"       on leads;
  drop policy if exists "Leads: admin manage"        on leads;
  drop policy if exists "Appts: public insert"       on appointments;
  drop policy if exists "Appts: admin manage"        on appointments;
exception when others then null;
end $$;


-- ══════════════════════════════════════════════════════════════
-- STEP 2 — TABLES
-- ══════════════════════════════════════════════════════════════

-- ─── admins ──────────────────────────────────────────────────
-- Allowlist: only rows here are allowed into the CMS panel
create table if not exists admins (
  id         uuid        primary key default uuid_generate_v4(),
  email      text        unique not null,
  role       text        not null default 'admin',
  created_at timestamptz not null default now()
);
comment on table admins is
  'Allowlist of admin emails. A Supabase Auth user must have a matching row here to access the CMS.';

-- ─── website_content ─────────────────────────────────────────
-- Key-value store: key = "hero" | "contact"
create table if not exists website_content (
  id         uuid        primary key default uuid_generate_v4(),
  key        text        unique not null,
  value      jsonb       not null default '{}',
  updated_at timestamptz not null default now()
);
comment on table website_content is 'Key-value CMS content: hero section and contact info.';

-- Auto-bump updated_at on every change
create or replace function set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_website_content_updated_at on website_content;
create trigger trg_website_content_updated_at
  before update on website_content
  for each row execute procedure set_updated_at();

-- ─── services ────────────────────────────────────────────────
create table if not exists services (
  id          uuid        primary key default uuid_generate_v4(),
  title       text        not null,
  emoji       text,
  badge       text,
  description text,
  bullets     jsonb       not null default '[]',
  sort_order  int         not null default 0,
  created_at  timestamptz not null default now()
);
comment on table services is 'Service cards shown on the website services section.';

-- ─── projects ────────────────────────────────────────────────
create table if not exists projects (
  id          uuid        primary key default uuid_generate_v4(),
  title       text        not null,
  emoji       text,
  category    text        not null default 'residential'
                          check (category in ('residential','commercial','renovation')),
  description text,
  location    text,
  year        text,
  thumbnail   text,       -- Supabase Storage public URL
  published   boolean     not null default false,
  created_at  timestamptz not null default now()
);
comment on table projects is 'Portfolio projects. published=true makes them visible on the website.';

-- ─── project_images ──────────────────────────────────────────
create table if not exists project_images (
  id         uuid        primary key default uuid_generate_v4(),
  project_id uuid        not null references projects(id) on delete cascade,
  url        text        not null,
  created_at timestamptz not null default now()
);
comment on table project_images is 'Additional gallery images per project.';

-- ─── testimonials ────────────────────────────────────────────
create table if not exists testimonials (
  id         uuid        primary key default uuid_generate_v4(),
  name       text        not null,
  location   text,
  avatar     text,
  rating     int         not null default 5 check (rating between 1 and 5),
  text       text,
  published  boolean     not null default false,
  created_at timestamptz not null default now()
);
comment on table testimonials is 'Customer reviews. published=true shows them on the website.';

-- ─── leads ───────────────────────────────────────────────────
create table if not exists leads (
  id         uuid        primary key default uuid_generate_v4(),
  name       text,
  phone      text,
  email      text,
  service    text,
  location   text,
  message    text,
  contacted  boolean     not null default false,
  created_at timestamptz not null default now()
);
comment on table leads is 'Contact-form submissions from the public website.';

-- ─── appointments ────────────────────────────────────────────
create table if not exists appointments (
  id             uuid        primary key default uuid_generate_v4(),
  name           text,
  phone          text,
  service        text,
  preferred_date date,
  notes          text,
  status         text        not null default 'New'
                             check (status in ('New','Contacted','Closed')),
  created_at     timestamptz not null default now()
);
comment on table appointments is 'Appointment requests managed in the CMS.';


-- ══════════════════════════════════════════════════════════════
-- STEP 3 — ROW LEVEL SECURITY
-- ══════════════════════════════════════════════════════════════
--
--  Access model:
--  ┌──────────────────────┬──────────┬───────────────────────┐
--  │ Table                │ Public   │ Admin (is_admin())     │
--  ├──────────────────────┼──────────┼───────────────────────┤
--  │ admins               │ ✗        │ SELECT own row         │
--  │ website_content      │ SELECT   │ ALL                    │
--  │ services             │ SELECT   │ ALL                    │
--  │ projects             │ SELECT   │ ALL (incl. drafts)     │
--  │                      │ published│                        │
--  │ project_images       │ SELECT   │ ALL                    │
--  │ testimonials         │ SELECT   │ ALL (incl. drafts)     │
--  │                      │ published│                        │
--  │ leads                │ INSERT   │ ALL                    │
--  │ appointments         │ INSERT   │ ALL                    │
--  └──────────────────────┴──────────┴───────────────────────┘

alter table admins           enable row level security;
alter table website_content  enable row level security;
alter table services         enable row level security;
alter table projects         enable row level security;
alter table project_images   enable row level security;
alter table testimonials     enable row level security;
alter table leads            enable row level security;
alter table appointments     enable row level security;

-- ── Core helper: is the current user in the admins table? ────
-- Uses auth.uid() → looks up email in auth.users → checks admins.
-- This is the ONLY way into the CMS — not just any Supabase user.
create or replace function is_admin()
returns boolean
language sql
security definer
stable
as $$
  select exists (
    select 1
    from   admins a
    join   auth.users u on u.email = a.email
    where  u.id = auth.uid()
  );
$$;
comment on function is_admin() is
  'Returns true only when the logged-in Supabase Auth user has a matching row in public.admins.';


-- ── admins ───────────────────────────────────────────────────
-- Admin can read their own row; service_role bypasses for setup
create policy "Admins: self read"
  on admins for select
  using ( is_admin() );

create policy "Admins: service role all"
  on admins for all
  using ( auth.role() = 'service_role' );

-- ── website_content ──────────────────────────────────────────
create policy "Content: public read"
  on website_content for select
  using ( true );

create policy "Content: admin write"
  on website_content for all
  using     ( is_admin() )
  with check( is_admin() );

-- ── services ─────────────────────────────────────────────────
create policy "Services: public read"
  on services for select
  using ( true );

create policy "Services: admin write"
  on services for all
  using     ( is_admin() )
  with check( is_admin() );

-- ── projects ─────────────────────────────────────────────────
-- Public sees only published; admin sees all + can edit drafts
create policy "Projects: public read"
  on projects for select
  using ( published = true );

create policy "Projects: admin write"
  on projects for all
  using     ( is_admin() )
  with check( is_admin() );

-- ── project_images ───────────────────────────────────────────
create policy "ProjectImages: public read"
  on project_images for select
  using ( true );

create policy "ProjectImages: admin write"
  on project_images for all
  using     ( is_admin() )
  with check( is_admin() );

-- ── testimonials ─────────────────────────────────────────────
-- Public sees only published; admin sees all + can edit drafts
create policy "Testimonials: public read"
  on testimonials for select
  using ( published = true );

create policy "Testimonials: admin write"
  on testimonials for all
  using     ( is_admin() )
  with check( is_admin() );

-- ── leads ────────────────────────────────────────────────────
-- Anon website visitors can INSERT; only admin can SELECT/manage
create policy "Leads: public insert"
  on leads for insert
  with check ( true );

create policy "Leads: admin manage"
  on leads for all
  using     ( is_admin() )
  with check( is_admin() );

-- ── appointments ─────────────────────────────────────────────
create policy "Appts: public insert"
  on appointments for insert
  with check ( true );

create policy "Appts: admin manage"
  on appointments for all
  using     ( is_admin() )
  with check( is_admin() );


-- ══════════════════════════════════════════════════════════════
-- STEP 4 — INDEXES
-- ══════════════════════════════════════════════════════════════

create index if not exists idx_projects_published
  on projects(published) where published = true;

create index if not exists idx_projects_category
  on projects(category);

create index if not exists idx_testimonials_published
  on testimonials(published) where published = true;

create index if not exists idx_leads_created
  on leads(created_at desc);

create index if not exists idx_leads_contacted
  on leads(contacted);

create index if not exists idx_appointments_status
  on appointments(status);

create index if not exists idx_services_sort
  on services(sort_order, created_at);

create index if not exists idx_project_images_project
  on project_images(project_id);


-- ══════════════════════════════════════════════════════════════
-- STEP 5 — DEFAULT SEED DATA
-- ══════════════════════════════════════════════════════════════

-- Hero content
insert into website_content (key, value) values
('hero', '{
  "heading":       "Turn Your Dream Home Into Reality",
  "subheading":    "We bring your vision to life — trusted professionals, superior craftsmanship, and premium-quality construction services delivered with full integrity.",
  "tagline":       "Karachi''s Trusted Builders",
  "stat_projects": "500+",
  "stat_years":    "12+",
  "stat_clients":  "98%",
  "cta1":          "Get Free Quote",
  "cta2":          "Call Now"
}')
on conflict (key) do nothing;

-- Contact info
insert into website_content (key, value) values
('contact', '{
  "phone1":    "0344-6626122",
  "phone2":    "0335-7550226",
  "phone3":    "0304-2446322",
  "whatsapp":  "923446626122",
  "email":     "shaikhms798@gmail.com",
  "address":   "M-90, Munir Mobile Mall, Mezzanine Floor, Block-17, Gulistan-e-Johar, Karachi",
  "maps_url":  "https://maps.google.com/?q=Gulistan-e-Johar+Block+17+Karachi",
  "hours":     "Mon – Sat: 9:00 AM – 7:00 PM",
  "facebook":  "",
  "instagram": ""
}')
on conflict (key) do nothing;

-- Default services
insert into services (title, emoji, badge, description, bullets, sort_order) values
(
  'Electrical Work', '⚡', '👷 Licensed Electricians',
  'Complete electrical solutions by certified professionals.',
  '["Complete new home wiring","Smart home installation","Panel upgrade & repair","Lighting design & fitting","Safety inspection & testing"]',
  1
),(
  'New Construction', '🏗️', '👷‍♂️ Certified Engineers',
  'Full residential and commercial construction from foundation to handover.',
  '["New residential construction","Extensions & room additions","Garage & outbuilding work","Framework, drywall & walling","Full project supervision"]',
  2
),(
  'Renovation', '🔨', '🛠️ Expert Craftsmen',
  'Transform your existing spaces with premium materials and expert craftsmanship.',
  '["Modern kitchen design & fitting","Bathroom upgrades & makeovers","Complete home transformation","Commercial office fit-outs","Elegant flooring installation"]',
  3
)
on conflict do nothing;

-- Sample projects
insert into projects (title, emoji, category, description, location, year, published) values
('Gulistan-e-Johar Villa',  '🏡', 'residential', 'Complete 3-storey residential build from foundation to finishing.', 'Block 17, Karachi',       '2024', true ),
('Office Complex Fit-out',  '🏢', 'commercial',  'Full office interior, wiring, partitions and flooring.',           'Clifton, Karachi',        '2024', true ),
('Luxury Kitchen Remodel',  '🍳', 'renovation',  'Modern kitchen with imported Italian fittings.',                  'DHA Phase 6',             '2024', true ),
('3-Storey Family Home',    '🏠', 'residential', '3-storey family home build from ground up.',                      'North Nazimabad, Karachi','2023', true ),
('Master Bathroom Upgrade', '🚿', 'renovation',  'Full bathroom renovation with modern tiles and waterproofing.',   'PECHS, Karachi',          '2023', true ),
('Retail Shop Renovation',  '🏪', 'commercial',  'Modern retail fit-out with new layout and lighting.',             'Tariq Road, Karachi',     '2023', true )
on conflict do nothing;

-- Sample testimonials
insert into testimonials (name, location, avatar, rating, text, published) values
('Ahmed Raza',             'DHA Phase 5, Karachi',  '👨',      5, 'AAC completely transformed our home in DHA. The quality of work was outstanding — every detail was perfect. They finished on time and within budget.', true),
('Sana Mirza',             'Clifton Block 4',        '👩',      5, 'Professional team, clean work, and no hidden costs. Our kitchen renovation came out exactly as planned. I will definitely use AAC for our next project.', true),
('Farhan Sheikh',          'Gulshan-e-Iqbal',        '👨‍💼',   5, 'The electrical upgrade for our commercial building was flawless. Knowledgeable, fast and reliable. Their safety inspection gave us total peace of mind.', true),
('Tariq & Hina Alam',      'North Nazimabad',        '👨‍👩‍👦',5, 'We built our house from scratch with AAC. Excellent project management — weekly updates, quality checks, and handover on the exact promised date.', true),
('Nadia Hussain',          'PECHS, Karachi',         '👩‍💼',   5, 'Bathroom renovation in just 10 days — modern tiles, new fittings, waterproofing done right. AAC was the best value among three contractors.', true),
('Zain Traders Pvt. Ltd.', 'Tariq Road, Karachi',    '🏢',     5, 'Our office fit-out was complex — multiple floors, wiring, partitions and flooring. AAC coordinated everything perfectly. World-class result.', true)
on conflict do nothing;


-- ══════════════════════════════════════════════════════════════
-- STEP 6 — STORAGE BUCKETS
-- ══════════════════════════════════════════════════════════════
-- Create manually in Supabase Dashboard → Storage → New Bucket:
--
--   Name: project-images   → Public: ON
--   Name: hero-images      → Public: ON
--
-- Storage RLS policies (set in Dashboard → Storage → Policies):
--   project-images: public READ, admin INSERT/DELETE
--   hero-images:    public READ, admin INSERT/DELETE


-- ══════════════════════════════════════════════════════════════
-- STEP 6b — VALIDATION CHECK
-- ══════════════════════════════════════════════════════════════
do $$
declare
  tbl  text;
  tbls text[] := array[
    'admins','website_content','services','projects',
    'project_images','testimonials','leads','appointments'
  ];
begin
  foreach tbl in array tbls loop
    if not exists (
      select 1 from information_schema.tables
      where table_schema = 'public' and table_name = tbl
    ) then
      raise exception 'Table "%" was NOT created — check for errors above.', tbl;
    end if;
  end loop;
  raise notice '✅ All 8 tables verified. Schema is ready.';
end $$;


-- ══════════════════════════════════════════════════════════════
-- STEP 7 — CREATE THE ADMIN USER (read carefully)
-- ══════════════════════════════════════════════════════════════
--
-- ⚠️  Supabase Auth users CANNOT be created via plain SQL.
--     Follow these exact 3 steps in the Dashboard UI:
--
-- ┌─────────────────────────────────────────────────────────────┐
-- │                                                             │
-- │  1. Dashboard → Authentication → Users → "Add User"        │
-- │     Email   :  admin@aac.pk          ← your admin email    │
-- │     Password:  Choose a strong one   ← min 8 characters    │
-- │     ✓ Check  "Auto Confirm Email"                          │
-- │     Click  "Create User"                                    │
-- │                                                             │
-- │  2. The new user row appears. Copy its UUID (looks like:    │
-- │     550e8400-e29b-41d4-a716-446655440000)                   │
-- │                                                             │
-- │  3. In SQL Editor, run this (replace both values):          │
-- │                                                             │
-- │     insert into public.admins (id, email)                   │
-- │     values (                                                │
-- │       'PASTE-UUID-FROM-STEP-2-HERE',                        │
-- │       'admin@aac.pk'                                        │
-- │     );                                                      │
-- │                                                             │
-- │  ✅ Done. Only this email can now log into the CMS.         │
-- │                                                             │
-- │  Security guarantee:                                        │
-- │    • Auth credentials correct  → passes Supabase Auth       │
-- │    • is_admin() check          → email must be in admins    │
-- │    • Both must pass or login fails + session is invalidated │
-- │                                                             │
-- │  To add another admin:  repeat steps 1-3.                  │
-- │  To revoke admin access: DELETE FROM admins WHERE email=..  │
-- │    (Auth account stays; just can't log into CMS anymore)    │
-- │                                                             │
-- └─────────────────────────────────────────────────────────────┘


-- ══════════════════════════════════════════════════════════════
-- STEP 8 — UPDATE BOTH HTML FILES
-- ══════════════════════════════════════════════════════════════
--
-- In BOTH aac_admin.html AND aac_website.html find these lines
-- near the bottom of the <script> block and fill in your values:
--
--   const SUPABASE_URL      = 'https://YOUR_PROJECT.supabase.co';
--   const SUPABASE_ANON_KEY = 'YOUR_ANON_KEY';
--
-- Where to find them in the Dashboard:
--   Settings → API → Project URL          → paste as SUPABASE_URL
--   Settings → API → anon / public key    → paste as SUPABASE_ANON_KEY
--
-- ⚠️  Use the ANON key (public), NOT the service_role key.
--     The service_role key bypasses all RLS — never expose it
--     in a public HTML file.
--
-- ══════════════════════════════════════════════════════════════
-- ✅ FULL SETUP COMPLETE
-- ══════════════════════════════════════════════════════════════



-- Final-Step Admin User Setup (after running SQL)

-- Dashboard → Authentication → Users → Add User — enter email + password, tick "Auto Confirm Email"
-- Copy the UUID of the new user
-- Run in SQL Editor:
Example:
insert into public.admins (id, email)
values ('d354660d-1cbf-4037-ab88-f14629b4c153', 'admin@aac.pk');

