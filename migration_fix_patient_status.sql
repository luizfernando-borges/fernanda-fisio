-- ══════════════════════════════════════════════════════════
-- FIX: Adiciona coluna patient_status + deleted_at
-- Rodar no Supabase SQL Editor
-- ══════════════════════════════════════════════════════════

-- 1. Adiciona patient_status (coluna correta usada pelo admin)
ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS patient_status TEXT NOT NULL DEFAULT 'ativo'
  CHECK (patient_status IN ('ativo','pausado','finalizado','arquivado'));

-- 2. Se treatment_status já existe, copia os valores
UPDATE patients
  SET patient_status = treatment_status
  WHERE treatment_status IS NOT NULL
    AND treatment_status IN ('ativo','pausado','finalizado','arquivado');

-- 3. Garante deleted_at (soft delete)
ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

-- Verificação
SELECT id, name, patient_status, deleted_at
FROM patients
ORDER BY name
LIMIT 20;
