-- ══════════════════════════════════════════════════════════
-- MIGRATION: AGENDA — treatment_start_date + appointments
-- Rodar no Supabase SQL Editor
-- ══════════════════════════════════════════════════════════

-- 1. Data de início do tratamento no paciente
ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS treatment_start_date DATE;

-- 2. Tabela de compromissos fixos (bloqueios recorrentes da agenda)
CREATE TABLE IF NOT EXISTS schedule_blocks (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  label       TEXT NOT NULL,           -- ex: "Clinica Elgra", "Sr. Edvaldo"
  day_of_week INTEGER NOT NULL,        -- 0=Dom, 1=Seg, 2=Ter, 3=Qua, 4=Qui, 5=Sex, 6=Sáb
  start_time  TIME NOT NULL,
  end_time    TIME NOT NULL,
  location    TEXT,
  color       TEXT DEFAULT '#94A3B8',  -- cor no calendário
  active      BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Tabela de atendimentos individuais (sessões marcadas)
CREATE TABLE IF NOT EXISTS appointments (
  id           UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  patient_id   UUID REFERENCES patients(id) ON DELETE SET NULL,
  date         DATE NOT NULL,
  start_time   TIME NOT NULL,
  end_time     TIME NOT NULL,
  type         TEXT DEFAULT 'session',  -- 'session', 'evaluation', 'block'
  status       TEXT DEFAULT 'scheduled',-- 'scheduled', 'done', 'cancelled'
  notes        TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Pedidos de agendamento vindos do site público
CREATE TABLE IF NOT EXISTS booking_requests (
  id             UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name           TEXT NOT NULL,
  phone          TEXT,
  email          TEXT,
  preferred_date DATE,
  preferred_time TIME,
  message        TEXT,
  status         TEXT DEFAULT 'pending', -- 'pending', 'confirmed', 'rejected'
  created_at     TIMESTAMPTZ DEFAULT NOW()
);

-- 5. RLS
ALTER TABLE schedule_blocks   ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments      ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_requests  ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_schedule_blocks"  ON schedule_blocks;
DROP POLICY IF EXISTS "admin_appointments"     ON appointments;
DROP POLICY IF EXISTS "admin_booking_requests" ON booking_requests;
DROP POLICY IF EXISTS "public_booking_insert"  ON booking_requests;

CREATE POLICY "admin_schedule_blocks"  ON schedule_blocks  FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "admin_appointments"     ON appointments     FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "admin_booking_requests" ON booking_requests FOR ALL USING (auth.role() = 'authenticated');
CREATE POLICY "public_booking_insert"  ON booking_requests FOR INSERT WITH CHECK (true);

-- 6. Pré-popular bloqueios fixos da Fernanda
INSERT INTO schedule_blocks (label, day_of_week, start_time, end_time, location, color) VALUES
  ('Clinica Elgra',     1, '08:00', '12:00', 'Clinica Elgra',                        '#475569'),
  ('Clinica Elgra',     2, '08:00', '12:00', 'Clinica Elgra',                        '#475569'),
  ('Clinica Elgra',     3, '08:00', '12:00', 'Clinica Elgra',                        '#475569'),
  ('Clinica Elgra',     4, '08:00', '12:00', 'Clinica Elgra',                        '#475569'),
  ('Clinica Elgra',     5, '08:00', '12:00', 'Clinica Elgra',                        '#475569'),
  ('Sr. Edvaldo',       1, '12:30', '13:30', 'Ribeirao Pires, Pq. Aliança',          '#B45309'),
  ('D. Maria Helena',   1, '14:00', '15:00', 'Ribeirao Pires, Bosque Santana',       '#B45309'),
  ('CEPHO',             2, '14:00', '15:40', 'Faculdade Santo André',                '#1D4ED8'),
  ('D. Salete',         4, '12:30', '13:30', 'Ribeirão Pires, Vila Suissa',          '#B45309'),
  ('Sr. Raulino',       4, '15:30', '16:30', 'Ribeirão Pires, Santa Luzia',          '#B45309'),
  ('CEPHO',             5, '14:00', '15:40', 'Faculdade Santo André',                '#1D4ED8'),
  ('Josiane',           5, '16:30', '17:30', 'São Paulo, Cambuci',                   '#B45309'),
  ('Sr. Raulino',       6, '15:30', '16:30', 'Ribeirão Pires, Santa Luzia',          '#B45309')
ON CONFLICT DO NOTHING;

