-- ============================================================
-- DENTAL CLAIMS AUTOMATION PERFORMANCE ANALYSIS
-- Author: Jeevan Lal Mourya | TriForza Portfolio Project
-- Dataset: 12,000 synthetic dental claims (Pre vs Post Automation)
-- ============================================================

-- ── 1. EXECUTIVE KPI SUMMARY ──────────────────────────────
SELECT
    period,
    COUNT(*)                                            AS total_claims,
    ROUND(AVG(processing_days), 2)                      AS avg_cycle_days,
    ROUND(SUM(CASE WHEN status='Error'     THEN 1 ELSE 0 END)*100.0/COUNT(*), 2) AS error_rate_pct,
    ROUND(SUM(CASE WHEN status='Duplicate' THEN 1 ELSE 0 END)*100.0/COUNT(*), 2) AS duplicate_rate_pct,
    ROUND(SUM(CASE WHEN status='Approved'  THEN 1 ELSE 0 END)*100.0/COUNT(*), 2) AS approval_rate_pct,
    ROUND(AVG(manual_minutes), 2)                       AS avg_manual_min_per_claim,
    ROUND(SUM(manual_minutes)/60.0, 0)                  AS total_manual_hours
FROM claims
GROUP BY period;

-- ── 2. AUTOMATION IMPACT: CYCLE TIME BY CLAIM TYPE ────────
SELECT
    claim_type,
    ROUND(AVG(CASE WHEN period='Pre-Automation'  THEN processing_days END), 2) AS pre_auto_days,
    ROUND(AVG(CASE WHEN period='Post-Automation' THEN processing_days END), 2) AS post_auto_days,
    ROUND(AVG(CASE WHEN period='Pre-Automation'  THEN processing_days END) -
          AVG(CASE WHEN period='Post-Automation' THEN processing_days END), 2) AS days_saved
FROM claims
GROUP BY claim_type
ORDER BY days_saved DESC;

-- ── 3. MONTHLY CLAIM VOLUME TREND ─────────────────────────
SELECT
    month,
    period,
    COUNT(*)                                            AS claim_volume,
    ROUND(AVG(processing_days), 2)                      AS avg_days,
    ROUND(SUM(CASE WHEN status='Error' THEN 1 ELSE 0 END)*100.0/COUNT(*), 2) AS error_rate_pct
FROM claims
GROUP BY month, period
ORDER BY month;

-- ── 4. ROI CALCULATION ────────────────────────────────────
SELECT
    'FTE Hours Saved (6 months)'          AS metric,
    ROUND((SUM(CASE WHEN period='Pre-Automation'  THEN manual_minutes END) -
           SUM(CASE WHEN period='Post-Automation' THEN auto_minutes   END)) / 60.0, 0) AS value
FROM claims
UNION ALL
SELECT 'Estimated Annual FTE Savings ($)',
    ROUND((SUM(CASE WHEN period='Pre-Automation' THEN manual_minutes END)/60.0 * 2 * 28), 0)
FROM claims
UNION ALL
SELECT 'Error Rate Reduction (%)',
    ROUND(
        SUM(CASE WHEN period='Pre-Automation'  AND status='Error' THEN 1.0 ELSE 0 END)/
        SUM(CASE WHEN period='Pre-Automation'  THEN 1.0 ELSE 0 END)*100 -
        SUM(CASE WHEN period='Post-Automation' AND status='Error' THEN 1.0 ELSE 0 END)/
        SUM(CASE WHEN period='Post-Automation' THEN 1.0 ELSE 0 END)*100, 2)
FROM claims
UNION ALL
SELECT 'Cycle Time Reduction (%)',
    ROUND((1.0 - AVG(CASE WHEN period='Post-Automation' THEN CAST(processing_days AS REAL) END) /
                 AVG(CASE WHEN period='Pre-Automation'  THEN CAST(processing_days AS REAL) END)) * 100, 1)
FROM claims;

-- ── 5. TOP 10 PROVIDERS BY CLAIM VOLUME & ERROR RATE ──────
SELECT
    provider_id,
    COUNT(*)                                             AS total_claims,
    ROUND(SUM(CASE WHEN status='Error' THEN 1 ELSE 0 END)*100.0/COUNT(*), 1) AS error_rate_pct,
    ROUND(AVG(processing_days), 2)                       AS avg_days,
    ROUND(SUM(claim_amount), 2)                          AS total_billed
FROM claims
GROUP BY provider_id
ORDER BY total_claims DESC
LIMIT 10;

-- ── 6. DATA VALIDATION CHECK ──────────────────────────────
SELECT
    'Null claim_id'       AS check_name, COUNT(*) AS issues FROM claims WHERE claim_id IS NULL
UNION ALL SELECT 'Null submitted_date', COUNT(*) FROM claims WHERE submitted_date IS NULL
UNION ALL SELECT 'Negative amount',     COUNT(*) FROM claims WHERE claim_amount < 0
UNION ALL SELECT 'Days < 0',            COUNT(*) FROM claims WHERE processing_days < 0
UNION ALL SELECT 'Invalid status',      COUNT(*) FROM claims
    WHERE status NOT IN ('Approved','Denied','Pending','Error','Duplicate');
