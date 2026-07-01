-- ═══════════════════════════════════════════════════
--  SCHEMA — Área do Paciente · Dra. Fernanda Rodrigues
--  Cole este SQL no Supabase → SQL Editor → Run
-- ═══════════════════════════════════════════════════

-- 1. PACIENTES
create table if not exists patients (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid references auth.users(id) on delete set null,
  name          text not null,
  email         text,
  phone         text,
  birth_date    date,
  diagnosis     text,
  start_date    date default current_date,
  notes         text,
  active        boolean default true,
  created_at    timestamptz default now()
);

-- 2. EVOLUÇÕES (registradas pela Dra. Fernanda)
create table if not exists evolutions (
  id              uuid primary key default gen_random_uuid(),
  patient_id      uuid references patients(id) on delete cascade,
  session_date    date not null default current_date,
  session_number  integer,
  mobility_score  integer check (mobility_score between 0 and 10),
  pain_score      integer check (pain_score between 0 and 10),
  function_score  integer check (function_score between 0 and 10),
  notes           text,
  goals_met       text,
  next_goals      text,
  created_at      timestamptz default now()
);

-- 3. DOCUMENTOS (laudos, receitas, relatórios)
create table if not exists documents (
  id           uuid primary key default gen_random_uuid(),
  patient_id   uuid references patients(id) on delete cascade,
  name         text not null,
  type         text default 'outro', -- laudo | relatorio | receita | exame | outro
  storage_path text,
  url          text,
  created_at   timestamptz default now()
);

-- 4. ACESSO FAMÍLIA
create table if not exists family_access (
  id           uuid primary key default gen_random_uuid(),
  patient_id   uuid references patients(id) on delete cascade,
  name         text,
  email        text not null,
  created_at   timestamptz default now(),
  unique(patient_id, email)
);

-- ───────────────────────────────────────────────────
--  ROW LEVEL SECURITY (RLS)
--  Garante que cada paciente só vê seus próprios dados
-- ───────────────────────────────────────────────────

alter table patients     enable row level security;
alter table evolutions   enable row level security;
alter table documents    enable row level security;
alter table family_access enable row level security;

-- Admin (Fernanda) pode tudo — identificada pelo e-mail no JWT
create policy "admin_all_patients" on patients
  for all using (auth.jwt() ->> 'email' = 'lf.borges.lima@gmail.com');

create policy "admin_all_evolutions" on evolutions
  for all using (auth.jwt() ->> 'email' = 'lf.borges.lima@gmail.com');

create policy "admin_all_documents" on documents
  for all using (auth.jwt() ->> 'email' = 'lf.borges.lima@gmail.com');

create policy "admin_all_family" on family_access
  for all using (auth.jwt() ->> 'email' = 'lf.borges.lima@gmail.com');

-- Paciente só vê os próprios dados (via user_id)
create policy "patient_own_data" on patients
  for select using (user_id = auth.uid());

create policy "patient_own_evolutions" on evolutions
  for select using (
    patient_id in (select id from patients where user_id = auth.uid())
  );

create policy "patient_own_documents" on documents
  for select using (
    patient_id in (select id from patients where user_id = auth.uid())
  );

-- Família: acesso de leitura aos pacientes que listaram o e-mail deles
create policy "family_read_patients" on patients
  for select using (
    id in (
      select patient_id from family_access
      where email = auth.jwt() ->> 'email'
    )
  );

create policy "family_read_evolutions" on evolutions
  for select using (
    patient_id in (
      select patient_id from family_access
      where email = auth.jwt() ->> 'email'
    )
  );

create policy "family_read_documents" on documents
  for select using (
    patient_id in (
      select patient_id from family_access
      where email = auth.jwt() ->> 'email'
    )
  );

-- 5. EXERCÍCIOS POR SESSÃO
create table if not exists session_exercises (
  id           uuid primary key default gen_random_uuid(),
  evolution_id uuid references evolutions(id) on delete cascade,
  patient_id   uuid references patients(id) on delete cascade,
  name         text not null,
  sets         text,
  reps         text,
  notes        text,
  order_index  integer default 0,
  created_at   timestamptz default now()
);

alter table session_exercises enable row level security;

create policy "admin_all_exercises" on session_exercises
  for all using (auth.jwt() ->> 'email' = 'lf.borges.lima@gmail.com');

create policy "patient_own_exercises" on session_exercises
  for select using (
    patient_id in (select id from patients where user_id = auth.uid())
  );

create policy "family_read_exercises" on session_exercises
  for select using (
    patient_id in (
      select patient_id from family_access
      where email = auth.jwt() ->> 'email'
    )
  );

-- ───────────────────────────────────────────────────
--  STORAGE — bucket para documentos
-- ───────────────────────────────────────────────────
insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict do nothing;

create policy "admin_upload_docs" on storage.objects
  for insert with check (
    bucket_id = 'documents'
    and auth.jwt() ->> 'email' = 'lf.borges.lima@gmail.com'
  );

create policy "patient_download_docs" on storage.objects
  for select using (
    bucket_id = 'documents'
  );
