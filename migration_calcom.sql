-- Migration: Cal.com integration
-- Run once in Supabase SQL Editor

-- Adiciona colunas ao appointments para tracking do Cal.com
ALTER TABLE appointments
  ADD COLUMN IF NOT EXISTS cal_booking_id TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS attendee_name  TEXT,
  ADD COLUMN IF NOT EXISTS attendee_email TEXT,
  ADD COLUMN IF NOT EXISTS source         TEXT DEFAULT 'manual'; -- 'manual' | 'calcom'

-- Índice para upsert eficiente
CREATE UNIQUE INDEX IF NOT EXISTS idx_appointments_cal_booking_id
  ON appointments(cal_booking_id)
  WHERE cal_booking_id IS NOT NULL;
