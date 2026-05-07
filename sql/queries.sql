-- 1. Pipeline coverage by quarter
SELECT DATE_TRUNC('quarter', expected_close_date) AS close_quarter,
       COUNT(*) AS opportunities,
       SUM(amount) AS open_pipeline,
       ROUND(SUM(amount * probability_pct / 100.0), 2) AS weighted_pipeline
FROM opportunities
WHERE stage NOT IN ('closed_won', 'closed_lost')
GROUP BY close_quarter
ORDER BY close_quarter;

-- 2. CAC by campaign channel
SELECT c.channel,
       ROUND(SUM(c.budget_usd), 2) AS spend,
       COUNT(DISTINCT CASE WHEN o.stage = 'closed_won' THEN o.account_id END) AS won_accounts,
       ROUND(SUM(c.budget_usd) / NULLIF(COUNT(DISTINCT CASE WHEN o.stage = 'closed_won' THEN o.account_id END), 0), 2) AS cac
FROM campaigns c
LEFT JOIN leads l ON l.campaign_id = c.campaign_id
LEFT JOIN opportunities o ON o.lead_id = l.lead_id
GROUP BY c.channel
ORDER BY spend DESC;

-- 3. Lead-to-opportunity conversion by campaign
SELECT c.campaign_name,
       COUNT(DISTINCT l.lead_id) AS leads,
       COUNT(DISTINCT o.opportunity_id) AS opportunities,
       ROUND(100.0 * COUNT(DISTINCT o.opportunity_id) / NULLIF(COUNT(DISTINCT l.lead_id), 0), 2) AS conversion_pct
FROM campaigns c
LEFT JOIN leads l ON l.campaign_id = c.campaign_id
LEFT JOIN opportunities o ON o.lead_id = l.lead_id
GROUP BY c.campaign_name
ORDER BY conversion_pct DESC, opportunities DESC;

-- 4. Attributed pipeline by touch position
SELECT at.touch_position,
       ROUND(SUM(o.amount * at.touch_weight), 2) AS attributed_pipeline
FROM attribution_touches at
JOIN opportunities o ON o.opportunity_id = at.opportunity_id
WHERE o.stage NOT IN ('closed_lost')
GROUP BY at.touch_position
ORDER BY attributed_pipeline DESC;

-- 5. Renewal risk exposure
SELECT r.risk_level,
       COUNT(*) AS renewals,
       ROUND(SUM(r.renewal_arr), 2) AS renewal_arr_exposed
FROM renewals r
GROUP BY r.risk_level
ORDER BY renewal_arr_exposed DESC;

-- 6. Forecast category coverage
SELECT forecast_category,
       COUNT(*) AS opportunities,
       ROUND(SUM(amount), 2) AS total_pipeline
FROM opportunities
WHERE stage NOT IN ('closed_won', 'closed_lost')
GROUP BY forecast_category
ORDER BY total_pipeline DESC;

-- 7. Content-influenced pipeline
SELECT ca.asset_name,
       ca.asset_type,
       ROUND(SUM(o.amount * at.touch_weight), 2) AS influenced_pipeline
FROM content_assets ca
JOIN attribution_touches at ON at.asset_id = ca.asset_id
JOIN opportunities o ON o.opportunity_id = at.opportunity_id
GROUP BY ca.asset_name, ca.asset_type
ORDER BY influenced_pipeline DESC;

-- 8. Partner-sourced win performance
SELECT a.partner_sourced,
       COUNT(DISTINCT o.opportunity_id) AS opportunities,
       COUNT(DISTINCT CASE WHEN o.stage = 'closed_won' THEN o.opportunity_id END) AS wins,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN o.stage = 'closed_won' THEN o.opportunity_id END) / NULLIF(COUNT(DISTINCT o.opportunity_id), 0), 2) AS win_rate_pct,
       ROUND(SUM(CASE WHEN o.stage = 'closed_won' THEN o.amount ELSE 0 END), 2) AS won_pipeline
FROM accounts a
JOIN opportunities o ON o.account_id = a.account_id
GROUP BY a.partner_sourced
ORDER BY won_pipeline DESC;

