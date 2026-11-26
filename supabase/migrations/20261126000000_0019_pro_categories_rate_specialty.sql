ALTER TABLE pro_categories
  ADD COLUMN IF NOT EXISTS rate numeric,
  ADD COLUMN IF NOT EXISTS specialty text;
