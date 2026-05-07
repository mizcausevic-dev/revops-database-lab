WITH account_seed(account_name, industry, region, employee_count, annual_revenue_usd, account_tier, partner_sourced) AS (
    VALUES
    ('Northstar Cloud', 'Cloud Infrastructure', 'North America', 1200, 180000000, 'enterprise', TRUE),
    ('Aperture Health', 'Healthcare Technology', 'North America', 800, 95000000, 'growth', FALSE),
    ('Helio Commerce', 'Retail Technology', 'EMEA', 620, 72000000, 'growth', FALSE),
    ('Pinnacle Ledger', 'FinTech', 'North America', 2100, 320000000, 'strategic', TRUE),
    ('Vector Grid', 'Energy Software', 'EMEA', 980, 130000000, 'enterprise', FALSE),
    ('Signal Harbor', 'Cybersecurity', 'North America', 540, 68000000, 'growth', TRUE),
    ('Atlas Media', 'Media Platforms', 'APAC', 430, 52000000, 'commercial', FALSE),
    ('Elevate HR', 'HR Tech', 'North America', 710, 88000000, 'growth', FALSE),
    ('Bluepeak Systems', 'Industrial SaaS', 'EMEA', 1500, 210000000, 'enterprise', TRUE),
    ('Crescent Data', 'Analytics', 'North America', 390, 47000000, 'commercial', FALSE),
    ('Orchid Legal', 'Legal Tech', 'EMEA', 560, 61000000, 'growth', FALSE),
    ('Summit Reach', 'MarTech', 'North America', 980, 145000000, 'enterprise', TRUE)
)
INSERT INTO accounts (account_name, industry, region, employee_count, annual_revenue_usd, account_tier, partner_sourced)
SELECT account_name, industry, region, employee_count, annual_revenue_usd, account_tier::account_tier_enum, partner_sourced
FROM account_seed;

WITH campaign_seed(campaign_name, channel, budget_usd, status, launch_date, owner_team) AS (
    VALUES
    ('Platform Modernization Search', 'paid_search', 42000, 'active', '2026-01-10', 'Demand Gen'),
    ('Executive RevOps Webinar', 'webinar', 18000, 'completed', '2026-02-14', 'Revenue Marketing'),
    ('Partner Expansion Toolkit', 'partner', 22000, 'active', '2026-02-28', 'Channel Marketing'),
    ('Customer Lifecycle Guide', 'content', 12000, 'active', '2026-03-03', 'Content'),
    ('Forecasting Nurture Stream', 'email', 9000, 'active', '2026-03-19', 'Lifecycle Marketing'),
    ('Field Transformation Dinner', 'field_event', 26000, 'completed', '2026-04-06', 'Field Marketing'),
    ('Security Governance Search', 'paid_search', 31000, 'active', '2026-04-21', 'Demand Gen'),
    ('Content Ops Webinar Series', 'webinar', 15000, 'planned', '2026-05-05', 'Content Marketing')
)
INSERT INTO campaigns (campaign_name, channel, budget_usd, status, launch_date, owner_team)
SELECT campaign_name, channel::campaign_channel_enum, budget_usd, status, launch_date::date, owner_team
FROM campaign_seed;

WITH asset_seed(asset_name, asset_type, theme, owner_team, published_at) AS (
    VALUES
    ('RevOps Operating Model Playbook', 'guide', 'revops', 'Content', '2026-01-20'),
    ('Executive Forecast Readiness Webinar', 'webinar', 'forecasting', 'Revenue Marketing', '2026-02-18'),
    ('Attribution Framework Whitepaper', 'whitepaper', 'attribution', 'Content', '2026-02-27'),
    ('Content Governance Toolkit', 'toolkit', 'content_ops', 'SEO Platform', '2026-03-11'),
    ('Partner Revenue Case Study', 'case_study', 'channel', 'Channel Marketing', '2026-03-30'),
    ('Customer Health Landing Page', 'landing_page', 'retention', 'Lifecycle Marketing', '2026-04-22')
)
INSERT INTO content_assets (asset_name, asset_type, theme, owner_team, published_at)
SELECT asset_name, asset_type::asset_type_enum, theme, owner_team, published_at::date
FROM asset_seed;

WITH numbered_accounts AS (
    SELECT account_id, account_name, ROW_NUMBER() OVER (ORDER BY account_name) AS rn
    FROM accounts
),
numbered_campaigns AS (
    SELECT campaign_id, channel, ROW_NUMBER() OVER (ORDER BY campaign_name) AS rn
    FROM campaigns
)
INSERT INTO leads (account_id, campaign_id, lead_name, title, source_channel, stage, mql_date, sql_date, created_at)
SELECT a.account_id,
       c.campaign_id,
       CONCAT(a.account_name, ' Contact ', seq.n),
       CASE seq.n
           WHEN 1 THEN 'VP Revenue Operations'
           WHEN 2 THEN 'Director of Growth'
           ELSE 'Head of Platform'
       END,
       c.channel,
       CASE seq.n
           WHEN 1 THEN 'sql'
           WHEN 2 THEN 'mql'
           ELSE 'working'
       END::lead_stage_enum,
       DATE '2026-03-01' + ((a.rn + seq.n) * 3),
       CASE WHEN seq.n = 1 THEN DATE '2026-03-12' + ((a.rn + seq.n) * 2) ELSE NULL END,
       DATE '2026-02-18' + ((a.rn + seq.n) * 2)
FROM numbered_accounts a
JOIN numbered_campaigns c ON c.rn = ((a.rn - 1) % 8) + 1
JOIN (VALUES (1), (2)) AS seq(n) ON TRUE;

WITH numbered_leads AS (
    SELECT l.lead_id, l.account_id, l.created_at, a.account_name, ROW_NUMBER() OVER (ORDER BY l.created_at, l.lead_id) AS rn
    FROM leads l
    JOIN accounts a ON a.account_id = l.account_id
    WHERE l.stage IN ('sql', 'mql')
)
INSERT INTO opportunities (account_id, lead_id, opportunity_name, stage, forecast_category, amount, probability_pct, expected_close_date, created_at)
SELECT account_id,
       lead_id,
       CONCAT(account_name, ' - ', CASE WHEN rn % 2 = 0 THEN 'Platform Expansion' ELSE 'RevOps Modernization' END),
       CASE
           WHEN rn IN (1, 2, 10) THEN 'closed_won'
           WHEN rn IN (5, 11) THEN 'closed_lost'
           WHEN rn % 4 = 0 THEN 'proposal'
           WHEN rn % 3 = 0 THEN 'negotiation'
           ELSE 'discovery'
       END::opportunity_stage_enum,
       CASE
           WHEN rn % 3 = 0 THEN 'commit'
           WHEN rn % 2 = 0 THEN 'best_case'
           ELSE 'pipeline'
       END::forecast_category_enum,
       55000 + (rn * 17000),
       CASE
           WHEN rn % 3 = 0 THEN 72
           WHEN rn % 2 = 0 THEN 54
           ELSE 35
       END,
       DATE '2026-07-01' + (rn * 12),
       created_at + 15
FROM numbered_leads
LIMIT 14;

WITH numbered_assets AS (
    SELECT asset_id, ROW_NUMBER() OVER (ORDER BY asset_name) AS rn
    FROM content_assets
),
numbered_opps AS (
    SELECT o.opportunity_id, o.lead_id, o.created_at, ROW_NUMBER() OVER (ORDER BY o.created_at, o.opportunity_id) AS rn
    FROM opportunities o
)
INSERT INTO attribution_touches (opportunity_id, lead_id, campaign_id, asset_id, touch_position, touch_weight, touch_date)
SELECT o.opportunity_id,
       o.lead_id,
       l.campaign_id,
       a.asset_id,
       touch.touch_position::touch_position_enum,
       touch.touch_weight,
       o.created_at - touch.days_before
FROM numbered_opps o
JOIN leads l ON l.lead_id = o.lead_id
JOIN numbered_assets a ON a.rn = ((o.rn - 1) % 6) + 1
JOIN (
    VALUES
    ('first_touch', 0.30, 35),
    ('middle_touch', 0.25, 18),
    ('last_touch', 0.45, 4)
) AS touch(touch_position, touch_weight, days_before) ON TRUE;

WITH numbered_subscriptions AS (
    SELECT o.account_id,
           o.opportunity_id,
           o.stage,
           o.amount,
           ROW_NUMBER() OVER (ORDER BY o.created_at, o.opportunity_id) AS rn
    FROM opportunities o
    WHERE o.stage IN ('closed_won', 'proposal', 'negotiation')
    LIMIT 10
)
INSERT INTO subscriptions (account_id, opportunity_id, arr_value, billing_frequency, term_months, start_date, end_date)
SELECT account_id,
       opportunity_id,
       CASE WHEN stage = 'closed_won' THEN amount * 0.92 ELSE amount * 0.75 END,
       CASE WHEN rn % 2 = 0 THEN 'annual' ELSE 'monthly' END::billing_frequency_enum,
       CASE WHEN rn % 2 = 0 THEN 12 ELSE 24 END,
       DATE '2026-08-01' + (rn * 10),
       DATE '2027-07-31' + (rn * 10)
FROM numbered_subscriptions;

WITH numbered_renewals AS (
    SELECT s.subscription_id, s.arr_value, s.end_date, ROW_NUMBER() OVER (ORDER BY s.start_date, s.subscription_id) AS rn
    FROM subscriptions s
)
INSERT INTO renewals (subscription_id, renewal_status, risk_level, renewal_arr, renewal_date, notes)
SELECT subscription_id,
       CASE
           WHEN rn % 5 = 0 THEN 'at_risk'
           WHEN rn % 7 = 0 THEN 'lost'
           WHEN rn % 3 = 0 THEN 'won'
           ELSE 'open'
       END::renewal_status_enum,
       CASE
           WHEN rn % 5 = 0 THEN 'high'
           WHEN rn % 2 = 0 THEN 'medium'
           ELSE 'low'
       END,
       arr_value * CASE WHEN rn % 4 = 0 THEN 1.08 ELSE 1.00 END,
       end_date - 30,
       CASE
           WHEN rn % 5 = 0 THEN 'Executive review required before renewal.'
           WHEN rn % 2 = 0 THEN 'Monitor product adoption and CS sentiment.'
           ELSE 'Healthy posture with standard renewal motion.'
       END
FROM numbered_renewals;

