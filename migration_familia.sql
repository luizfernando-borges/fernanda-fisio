-- ══════════════════════════════════════════════════════════
-- MIGRATION: FAMÍLIA — familiares, observações, visibilidade
-- Rodar no Supabase SQL Editor
-- ══════════════════════════════════════════════════════════

-- 1. Familiares vinculados ao paciente
CREATE TABLE IF NOT EXISTS family_members (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_id  UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  name        TEXT NOT NULL,
  email       TEXT NOT NULL,
  status      TEXT DEFAULT 'pending', -- 'pending', 'active'
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(patient_id, email)
);

-- 2. Observações da família sobre evoluções
CREATE TABLE IF NOT EXISTS family_observations (
  id                UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_id        UUID REFERENCES patients(id) ON DELETE CASCADE NOT NULL,
  evolution_id      UUID REFERENCES evolutions(id) ON DELETE CASCADE NOT NULL,
  family_member_id  UUID REFERENCES family_members(id) ON DELETE CASCADE NOT NULL,
  message           TEXT NOT NULL,
  fernanda_reply    TEXT,
  replied_at        TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Controle de visibilidade por evolução e documento
ALTER TABLE evolutions ADD COLUMN IF NOT EXISTS shared_with_family BOOLEAN DEFAULT TRUE;
ALTER TABLE documents  ADD COLUMN IF NOT EXISTS shared_with_family BOOLEAN DEFAULT TRUE;

-- 4. RLS
ALTER TABLE family_members     ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_observations ENABLE ROW LEVEL SECURITY;

-- Admin vê tudo
DROP POLICY IF EXISTS "admin_family_members"      ON family_members;
DROP POLICY IF EXISTS "admin_family_observations" ON family_observations;
CREATE POLICY "admin_family_members"      ON family_members      FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "admin_family_observations" ON family_observations FOR ALL USING (auth.role() = 'authenticated');

-- Família lê por email (magic link auth)
DROP POLICY IF EXISTS "family_read_members"      ON family_members;
DROP POLICY IF EXISTS "family_read_observations" ON family_observations;
DROP POLICY IF EXISTS "family_insert_observation" ON family_observations;

CREATE POLICY "family_read_members" ON family_members
  FOR SELECT USING (email = auth.jwt() ->> 'email');

CREATE POLICY "family_read_observations" ON family_observations
  FOR SELECT USING (
    patient_id IN (
      SELECT patient_id FROM family_members WHERE email = auth.jwt() ->> 'email'
    )
  );

CREATE POLICY "family_insert_observation" ON family_observations
  FOR INSERT WITH CHECK (
    patient_id IN (
      SELECT patient_id FROM family_members WHERE email = auth.jwt() ->> 'email' AND status = 'active'
    )
  );

