-- ══════════════════════════════════════════════════════════════
--  MIGRATION ETAPA 2 — Prontuário Fisioterapêutico Digital
--  Dra. Fernanda Rodrigues · drafernandafisio.com.br
--  Execute no Supabase → SQL Editor → Run
-- ══════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────
-- 1. CORRIGIR RLS — email antigo → fernandarodfisioterapeuta@gmail.com
-- ────────────────────────────────────────────────────────────

-- Pacientes
DROP POLICY IF EXISTS "admin_all_patients" ON patients;
CREATE POLICY "admin_all_patients" ON patients
  FOR ALL USING (auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com');

-- Evoluções
DROP POLICY IF EXISTS "admin_all_evolutions" ON evolutions;
CREATE POLICY "admin_all_evolutions" ON evolutions
  FOR ALL USING (auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com');

-- Documentos
DROP POLICY IF EXISTS "admin_all_documents" ON documents;
CREATE POLICY "admin_all_documents" ON documents
  FOR ALL USING (auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com');

-- Família
DROP POLICY IF EXISTS "admin_all_family" ON family_access;
CREATE POLICY "admin_all_family" ON family_access
  FOR ALL USING (auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com');

-- Avaliações antigas
DROP POLICY IF EXISTS "admin_all_assessments" ON patient_assessments;
CREATE POLICY "admin_all_assessments" ON patient_assessments
  FOR ALL USING (auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com');

-- Exercícios de sessão
DROP POLICY IF EXISTS "admin_all_exercises" ON session_exercises;
CREATE POLICY "admin_all_exercises" ON session_exercises
  FOR ALL USING (auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com');

-- Storage: upload de documentos
DROP POLICY IF EXISTS "admin_upload_docs" ON storage.objects;
CREATE POLICY "admin_upload_docs" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'documents'
    AND auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com'
  );

-- ────────────────────────────────────────────────────────────
-- 2. EXPANDIR TABELA PACIENTES
--    Adiciona dados pessoais completos conforme prontuário
-- ────────────────────────────────────────────────────────────

ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS cpf            text,
  ADD COLUMN IF NOT EXISTS rg             text,
  ADD COLUMN IF NOT EXISTS sex            text,       -- 'M' | 'F' | 'Outro'
  ADD COLUMN IF NOT EXISTS marital_status text,       -- solteiro | casado | divorciado | viúvo | outro
  ADD COLUMN IF NOT EXISTS profession     text,
  ADD COLUMN IF NOT EXISTS education      text,       -- grau de escolaridade
  ADD COLUMN IF NOT EXISTS phone2         text,       -- segundo telefone
  ADD COLUMN IF NOT EXISTS address_street text,
  ADD COLUMN IF NOT EXISTS address_number text,
  ADD COLUMN IF NOT EXISTS address_compl  text,       -- complemento
  ADD COLUMN IF NOT EXISTS address_hood   text,       -- bairro
  ADD COLUMN IF NOT EXISTS address_city   text,
  ADD COLUMN IF NOT EXISTS address_state  text DEFAULT 'SP',
  ADD COLUMN IF NOT EXISTS address_zip    text,       -- CEP
  ADD COLUMN IF NOT EXISTS emerg_name     text,       -- contato de emergência: nome
  ADD COLUMN IF NOT EXISTS emerg_phone    text,       -- contato de emergência: telefone
  ADD COLUMN IF NOT EXISTS emerg_relation text;       -- contato de emergência: parentesco

-- ────────────────────────────────────────────────────────────
-- 3. EXPANDIR TABELA EVOLUÇÕES
--    Adiciona campos clínicos por sessão
-- ────────────────────────────────────────────────────────────

ALTER TABLE evolutions
  ADD COLUMN IF NOT EXISTS presence           boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS payment_received   boolean,
  ADD COLUMN IF NOT EXISTS pain_present       boolean,
  ADD COLUMN IF NOT EXISTS progress           text,   -- 'melhorou' | 'igual' | 'piorou'
  ADD COLUMN IF NOT EXISTS conduct            text,   -- conduta realizada
  ADD COLUMN IF NOT EXISTS home_exercises     text,   -- exercícios para casa
  ADD COLUMN IF NOT EXISTS visible_to_patient boolean DEFAULT false;

-- ────────────────────────────────────────────────────────────
-- 4. CRIAR TABELA EVALUATIONS
--    Substitui patient_assessments — suporta múltiplos tipos:
--    'general' | 'orthopedic' | 'neuro' | 'gero'
--    Os campos específicos de cada formulário ficam em `data` (JSONB)
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS evaluations (
  id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id         uuid        REFERENCES patients(id) ON DELETE CASCADE,
  type               text        NOT NULL DEFAULT 'general',
  status             text        DEFAULT 'draft',      -- 'draft' | 'completed'
  evaluation_date    date        NOT NULL DEFAULT current_date,
  data               jsonb       DEFAULT '{}',
  visible_to_patient boolean     DEFAULT false,
  created_at         timestamptz DEFAULT now(),
  updated_at         timestamptz DEFAULT now()
);

-- Índice para busca por paciente + tipo
CREATE INDEX IF NOT EXISTS evaluations_patient_type
  ON evaluations(patient_id, type);

ALTER TABLE evaluations ENABLE ROW LEVEL SECURITY;

-- Admin pode tudo
CREATE POLICY "admin_all_evaluations" ON evaluations
  FOR ALL USING (auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com');

-- Paciente vê apenas avaliações marcadas como visíveis
CREATE POLICY "patient_own_evaluations" ON evaluations
  FOR SELECT USING (
    visible_to_patient = true
    AND patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
  );

-- Familiar vê apenas avaliações visíveis do paciente vinculado
CREATE POLICY "family_read_evaluations" ON evaluations
  FOR SELECT USING (
    visible_to_patient = true
    AND patient_id IN (
      SELECT patient_id FROM family_access
      WHERE email = auth.jwt() ->> 'email'
    )
  );

-- ────────────────────────────────────────────────────────────
-- 5. MIGRAR patient_assessments → evaluations (tipo: 'general')
--    Os dados já salvos são preservados automaticamente
-- ────────────────────────────────────────────────────────────

INSERT INTO evaluations (patient_id, type, status, evaluation_date, data, created_at, updated_at)
SELECT
  pa.patient_id,
  'general',
  'completed',
  pa.assessment_date,
  jsonb_build_object(
    'main_complaint',         pa.main_complaint,
    'disease_history',        pa.disease_history,
    'medical_history',        pa.medical_history,
    'previous_surgeries',     pa.previous_surgeries,
    'medications',            pa.medications,
    'allergies',              pa.allergies,
    'functional_level',       pa.functional_level,
    'mobility_aids',          pa.mobility_aids,
    'adl_notes',              pa.adl_notes,
    'inspection_notes',       pa.inspection_notes,
    'rom_notes',              pa.rom_notes,
    'muscle_strength_notes',  pa.muscle_strength_notes,
    'sensitivity',            pa.sensitivity,
    'balance_level',          pa.balance_level,
    'coordination_notes',     pa.coordination_notes,
    'initial_mobility_score', pa.initial_mobility_score,
    'initial_pain_score',     pa.initial_pain_score,
    'initial_function_score', pa.initial_function_score,
    'diagnostic_hypothesis',  pa.diagnostic_hypothesis,
    'short_term_goals',       pa.short_term_goals,
    'long_term_goals',        pa.long_term_goals,
    'treatment_plan',         pa.treatment_plan,
    'session_frequency',      pa.session_frequency,
    'estimated_duration',     pa.estimated_duration,
    'additional_notes',       pa.additional_notes
  ),
  pa.created_at,
  pa.updated_at
FROM patient_assessments pa
WHERE NOT EXISTS (
  SELECT 1 FROM evaluations e
  WHERE e.patient_id = pa.patient_id AND e.type = 'general'
);

-- ────────────────────────────────────────────────────────────
-- NOTA IMPORTANTE
-- Após confirmar que tudo está funcionando, você pode remover
-- a tabela antiga com o comando abaixo (não execute agora):
--
-- DROP TABLE IF EXISTS patient_assessments;
-- ────────────────────────────────────────────────────────────
