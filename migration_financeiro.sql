-- ══════════════════════════════════════════════════════════
-- FINANCEIRO: Pacotes de tratamento + Pagamentos
-- Rodar no Supabase SQL Editor
-- ══════════════════════════════════════════════════════════

-- 1. PACOTES DE TRATAMENTO
CREATE TABLE IF NOT EXISTS treatment_packages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  total_sessions  INT  NOT NULL DEFAULT 10,
  sessions_used   INT  NOT NULL DEFAULT 0,
  total_value     NUMERIC(10,2) NOT NULL,
  payment_model   TEXT NOT NULL DEFAULT 'avista'
    CHECK (payment_model IN ('avista','entrada_final','parcelado','por_sessao','mensal')),
  notes           TEXT,
  status          TEXT NOT NULL DEFAULT 'ativo'
    CHECK (status IN ('ativo','concluido','cancelado')),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 2. PAGAMENTOS
CREATE TABLE IF NOT EXISTS payments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  package_id      UUID NOT NULL REFERENCES treatment_packages(id) ON DELETE CASCADE,
  patient_id      UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
  amount          NUMERIC(10,2) NOT NULL,
  payment_date    DATE NOT NULL DEFAULT CURRENT_DATE,
  method          TEXT NOT NULL DEFAULT 'pix'
    CHECK (method IN ('pix','dinheiro','transferencia')),
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- 3. RLS
ALTER TABLE treatment_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments            ENABLE ROW LEVEL SECURITY;

-- Drop antes de recriar (evita erro de duplicata)
DROP POLICY IF EXISTS "admin_all_packages" ON treatment_packages;
DROP POLICY IF EXISTS "admin_all_payments" ON payments;

CREATE POLICY "admin_all_packages" ON treatment_packages
  FOR ALL USING (auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com');

CREATE POLICY "admin_all_payments" ON payments
  FOR ALL USING (auth.jwt() ->> 'email' = 'fernandarodfisioterapeuta@gmail.com');

-- 4. Verificação
SELECT 'treatment_packages' AS tabela, COUNT(*) FROM treatment_packages
UNION ALL
SELECT 'payments', COUNT(*) FROM payments;
