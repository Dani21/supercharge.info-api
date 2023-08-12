-- ============================================================================
-- File for SQL that will change the schema.  Clear this file after prod deploy.
-- ============================================================================
set search_path to supercharge;

ALTER TYPE site_status_type ADD VALUE 'ARCHIVED' BEFORE 'CLOSED_PERM';
ALTER TABLE site DROP COLUMN enabled;
