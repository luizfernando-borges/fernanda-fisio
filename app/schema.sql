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

-- 5. AVALIAÇÃO INICIAL DO PACIENTE
create table if not exists patient_assessments (
  id                       uuid primary key default gen_random_uuid(),
  patient_id               uuid references patients(id) on delete cascade unique,
  assessment_date          date not null default current_date,

  -- Anamnese
  main_complaint           text,
  disease_history          text,
  medical_history          text,
  previous_surgeries       text,
  medications              text,
  allergies                text,

  -- Funcional
  functional_level         text,  -- independente / assistido / dependente
  mobility_aids            text,  -- nenhum / bengala / andador / cadeira de rodas
  adl_notes                text,

  -- Exame físico
  inspection_notes         text,
  rom_notes                text,
  muscle_strength_notes    text,
  sensitivity              text,  -- normal / alterada / ausente
  balance_level            text,  -- bom / regular / comprometido / ausente
  coordination_notes       text,

  -- Escalas iniciais (0–10)
  initial_mobility_score   integer check (initial_mobility_score between 0 and 10),
  initial_pain_score       integer check (initial_pain_score between 0 and 10),
  initial_function_score   integer check (initial_function_score between 0 and 10),

  -- Diagnóstico e plano
  diagnostic_hypothesis    text,
  short_term_goals         text,
  long_term_goals          text,
  treatment_plan           text,
  session_frequency        text,
  estimated_duration       text,

  additional_notes         text,
  created_at               timestamptz default now(),
  updated_at               timestamptz default now()
);

alter table patient_assessments enable row level security;

cr