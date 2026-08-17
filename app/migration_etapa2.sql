-- ══════════════════════════════════════════════════════════════
--  MIGRATION ETAPA 2 — Prontuário Fisioterapêutico Digital
--  Dra. Fernanda Rodrigues · drafernandafisio.com.br
--  Execute no Supabase SQL Editor → Run
--  Versão 2 (corrigida): storage completo, RLS documentada
-- ══════════════════════════════════════════════════════════════

-- ────────────────────────────────────────────────────────────
-- NOTA DE ARQUITETURA: RLS baseada em e-mail (PROVISÓRIO)
-- ────────────────────────────────────────────────────────────
-- As policies abaixo identificam o admin pelo e-mail do JWT.
-- Isso é funcional mas provisório: depende de um e-mail fixo
-- e não escala se houver mais de um administrador no futuro.
--
-- Caminho de migração futura (sem alterar schema):
--   1. No Supabase Dashboard: Authentication → Users
--      → selecione a usuária Fernanda → Edit → Raw App Meta Data
--      → adicione: { "role": "admin" }
--   2. Rode nova migration substituindo todas as ocorrências de:
--        auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com'
--      por:
--        auth.jwt() -> 'app_metadata' ->> 'role' = 'admin'
--
-- Essa transição não requer mudança de schema, apenas o passo
-- manual no Dashboard + uma migration de policies.
-- ────────────────────────────────────────────────────────────


-- ════════════════════════════════════════════════════════════
-- 1. CORRIGIR RLS DAS TABELAS EXISTENTES
--    Troca o e-mail antigo pelo correto em todas as policies
-- ════════════════════════════════════════════════════════════

-- Pacientes
DROP POLICY IF EXISTS "admin_all_patients" ON patients;
CREATE POLICY "admin_all_patients" ON patients
  FOR ALL USING (
    auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com'
  );

-- Evoluções
DROP POLICY IF EXISTS "admin_all_evolutions" ON evolutions;
CREATE POLICY "admin_all_evolutions" ON evolutions
  FOR ALL USING (
    auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com'
  );

-- Documentos (tabela, não bucket)
DROP POLICY IF EXISTS "admin_all_documents" ON documents;
CREATE POLICY "admin_all_documents" ON documents
  FOR ALL USING (
    auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com'
  );

-- Acesso família
DROP POLICY IF EXISTS "admin_all_family" ON family_access;
CREATE POLICY "admin_all_family" ON family_access
  FOR ALL USING (
    auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com'
  );

-- Avaliações antigas (mantida como backup)
DROP POLICY IF EXISTS "admin_all_assessments" ON patient_assessments;
CREATE POLICY "admin_all_assessments" ON patient_assessments
  FOR ALL USING (
    auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com'
  );

-- Exercícios por sessão
DROP POLICY IF EXISTS "admin_all_exercises" ON session_exercises;
CREATE POLICY "admin_all_exercises" ON session_exercises
  FOR ALL USING (
    auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com'
  );


-- ════════════════════════════════════════════════════════════
-- 2. EXPANDIR TABELA PACIENTES
--    Dados pessoais completos para o prontuário
-- ════════════════════════════════════════════════════════════

ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS cpf            text,
  ADD COLUMN IF NOT EXISTS rg             text,
  ADD COLUMN IF NOT EXISTS sex            text,       -- 'M' | 'F' | 'Outro'
  ADD COLUMN IF NOT EXISTS marital_status text,       -- solteiro | casado | divorciado | viuvo | outro
  ADD COLUMN IF NOT EXISTS profession     text,
  ADD COLUMN IF NOT EXISTS education      text,
  ADD COLUMN IF NOT EXISTS phone2         text,
  ADD COLUMN IF NOT EXISTS address_street text,
  ADD COLUMN IF NOT EXISTS address_number text,
  ADD COLUMN IF NOT EXISTS address_compl  text,
  ADD COLUMN IF NOT EXISTS address_hood   text,       -- bairro
  ADD COLUMN IF NOT EXISTS address_city   text,
  ADD COLUMN IF NOT EXISTS address_state  text DEFAULT 'SP',
  ADD COLUMN IF NOT EXISTS address_zip    text,
  ADD COLUMN IF NOT EXISTS emerg_name     text,
  ADD COLUMN IF NOT EXISTS emerg_phone    text,
  ADD COLUMN IF NOT EXISTS emerg_relation text;


-- ════════════════════════════════════════════════════════════
-- 3. EXPANDIR TABELA EVOLUCOES
--    Campos clínicos adicionais por sessão
-- ════════════════════════════════════════════════════════════

ALTER TABLE evolutions
  ADD COLUMN IF NOT EXISTS presence           boolean DEFAULT true,
  ADD COLUMN IF NOT EXISTS payment_received   boolean,
  ADD COLUMN IF NOT EXISTS pain_present       boolean,
  ADD COLUMN IF NOT EXISTS progress           text,   -- 'melhorou' | 'igual' | 'piorou'
  ADD COLUMN IF NOT EXISTS conduct            text,
  ADD COLUMN IF NOT EXISTS home_exercises     text,
  ADD COLUMN IF NOT EXISTS visible_to_patient boolean DEFAULT false;


-- ════════════════════════════════════════════════════════════
-- 4. CRIAR TABELA EVALUATIONS
--    Substitui patient_assessments com suporte a múltiplos tipos
--    Tipos: 'general' | 'orthopedic' | 'neuro' | 'gero'
--    Campos específicos de cada formulário ficam em data (jsonb)
-- ════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS evaluations (
  id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id         uuid        REFERENCES patients(id) ON DELETE CASCADE,
  type               text        NOT NULL DEFAULT 'general',
  status             text        DEFAULT 'draft',     -- 'draft' | 'completed'
  evaluation_date    date        NOT NULL DEFAULT current_date,
  data               jsonb       DEFAULT '{}',
  visible_to_patient boolean     DEFAULT false,
  created_at         timestamptz DEFAULT now(),
  updated_at         timestamptz DEFAULT now()
);

CREATE INDEX IF NOT EXISTS evaluations_patient_type
  ON evaluations(patient_id, type);

ALTER TABLE evaluations ENABLE ROW LEVEL SECURITY;

-- Admin: acesso total
DROP POLICY IF EXISTS "admin_all_evaluations" ON evaluations;
CREATE POLICY "admin_all_evaluations" ON evaluations
  FOR ALL USING (
    auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com'
  );

-- Paciente: vê apenas avaliações explicitamente liberadas
DROP POLICY IF EXISTS "patient_own_evaluations" ON evaluations;
CREATE POLICY "patient_own_evaluations" ON evaluations
  FOR SELECT USING (
    visible_to_patient = true
    AND patient_id IN (
      SELECT id FROM patients WHERE user_id = auth.uid()
    )
  );

-- Familiar: vê apenas avaliações liberadas do paciente vinculado
DROP POLICY IF EXISTS "family_read_evaluations" ON evaluations;
CREATE POLICY "family_read_evaluations" ON evaluations
  FOR SELECT USING (
    visible_to_patient = true
    AND patient_id IN (
      SELECT patient_id FROM family_access
      WHERE email = auth.jwt() ->> 'email'
    )
  );


-- ════════════════════════════════════════════════════════════
-- 5. STORAGE — bucket documents
--    Bucket permanece PRIVADO (public = false)
--    Políticas escopadas por usuário; nenhuma expõe dados públicos
-- ════════════════════════════════════════════════════════════

-- Garante que o bucket existe (idempotente)
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', false)
ON CONFLICT DO NOTHING;

-- ── Admin ──────────────────────────────────────────────────

-- Admin: upload
DROP POLICY IF EXISTS "admin_upload_docs" ON storage.objects;
CREATE POLICY "admin_upload_docs" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'documents'
    AND auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com'
  );

-- Admin: visualizar / baixar (necessário para o painel admin)
DROP POLICY IF EXISTS "admin_select_docs" ON storage.objects;
CREATE POLICY "admin_select_docs" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'documents'
    AND auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com'
  );

-- Admin: remover arquivos
DROP POLICY IF EXISTS "admin_delete_docs" ON storage.objects;
CREATE POLICY "admin_delete_docs" ON storage.objects
  FOR DELETE USING (
    bucket_id = 'documents'
    AND auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com'
  );

-- ── Paciente ───────────────────────────────────────────────
-- O path dos objetos segue o padrão: {patient_id}/{arquivo}
-- split_part(name, '/', 1) extrai o patient_id do path

DROP POLICY IF EXISTS "patient_download_docs" ON storage.objects;
DROP POLICY IF EXISTS "patient_download_own_docs" ON storage.objects;
CREATE POLICY "patient_download_own_docs" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'documents'
    AND split_part(name, '/', 1) IN (
      SELECT id::text FROM patients WHERE user_id = auth.uid()
    )
  );

-- ── Familiar ───────────────────────────────────────────────

DROP POLICY IF EXISTS "family_download_docs" ON storage.objects;
CREATE POLICY "family_download_docs" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'documents'
    AND split_part(name, '/', 1) IN (
      SELECT patient_id::text FROM family_access
      WHERE email = auth.jwt() ->> 'email'
    )
  );


-- ════════════════════════════════════════════════════════════
-- 6. MIGRAR patient_assessments → evaluations (type = 'general')
--    Preserva todos os dados existentes
--    WHERE NOT EXISTS garante idempotência (seguro rodar 2x)
-- ════════════════════════════════════════════════════════════

INSERT INTO evaluations (
  patient_id, type, status, evaluation_date, data, created_at, updated_at
)
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
  WHERE e.patient_id = pa.patient_id
    AND e.type = 'general'
);


-- ════════════════════════════════════════════════════════════
-- TABELAS NÃO REMOVIDAS NESTA ETAPA
-- ════════════════════════════════════════════════════════════
-- patient_assessments permanece intacta como backup.
-- Para remover somente após validar que a migração funcionou:
--
--   DROP TABLE IF EXISTS patient_assessments;
--
-- ════════════════════════════════════════════════════════════
