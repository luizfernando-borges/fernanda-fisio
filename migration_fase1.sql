-- ══════════════════════════════════════════════════════════
-- FASE 1: Status de paciente + Soft Delete
-- Rodar no Supabase SQL Editor
-- ══════════════════════════════════════════════════════════

-- 1. Adiciona coluna treatment_status
ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS treatment_status TEXT NOT NULL DEFAULT 'ativo'
  CHECK (treatment_status IN ('ativo','pausado','finalizado'));

-- 2. Migra dados existentes: active=true → ativo, active=false → finalizado
UPDATE patients SET treatment_status = 'ativo'      WHERE active = true;
UPDATE patients SET treatment_status = 'finalizado' WHERE active = false;

-- 3. Adiciona soft delete
ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ DEFAULT NULL;

-- 4. RLS — excluir registros deletados das queries normais
-- (o filtro deleted_at IS NULL é feito no JS; o RLS abaixo é opcional mas boa prática)
-- Nenhuma policy nova necessária; o JS já filtra.

-- Verificação
SELECT id, name, active, treatment_status, deleted_at
FROM patients
ORDER BY name
LIMIT 20;
