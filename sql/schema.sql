CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'account_tier_enum') THEN
        CREATE TYPE account_tier_enum AS ENUM ('strategic', 'enterprise', 'growth', 'commercial');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'lead_stage_enum') THEN
        CREATE TYPE lead_stage_enum AS ENUM ('new', 'mql', 'sql', 'working', 'disqualified');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'campaign_channel_enum') THEN
        CREATE TYPE campaign_channel_enum AS ENUM ('paid_search', 'content', 'webinar', 'partner', 'email', 'field_event');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'asset_type_enum') THEN
        CREATE TYPE asset_type_enum AS ENUM ('whitepaper', 'guide', 'webinar', 'landing_page', 'case_study', 'toolkit');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'opportunity_stage_enum') THEN
        CREATE TYPE opportunity_stage_enum AS ENUM ('qualification', 'discovery', 'proposal', 'negotiation', 'closed_won', 'closed_lost');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'forecast_category_enum') THEN
        CREATE TYPE forecast_category_enum AS ENUM ('pipeline', 'best_case', 'commit');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'touch_position_enum') THEN
        CREATE TYPE touch_position_enum AS ENUM ('first_touch', 'middle_touch', 'last_touch');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'billing_frequency_enum') THEN
        CREATE TYPE billing_frequency_enum AS ENUM ('monthly', 'annual');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'renewal_status_enum') THEN
        CREATE TYPE renewal_status_enum AS ENUM ('open', 'at_risk', 'won', 'lost');
    END IF;
END $$;

DROP TABLE IF EXISTS renewals CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS attribution_touches CASCADE;
DROP TABLE IF EXISTS opportunities CASCADE;
DROP TABLE IF EXISTS leads CASCADE;
DROP TABLE IF EXISTS content_assets CASCADE;
DROP TABLE IF EXISTS campaigns CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;

CREATE TABLE accounts (
    account_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_name TEXT NOT NULL,
    industry TEXT NOT NULL,
    region TEXT NOT NULL,
    employee_count INTEGER NOT NULL CHECK (employee_count > 0),
    annual_revenue_usd NUMERIC(14,2) NOT NULL CHECK (annual_revenue_usd >= 0),
    account_tier account_tier_enum NOT NULL,
    partner_sourced BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE campaigns (
    campaign_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_name TEXT NOT NULL,
    channel campaign_channel_enum NOT NULL,
    budget_usd NUMERIC(12,2) NOT NULL CHECK (budget_usd >= 0),
    status TEXT NOT NULL,
    launch_date DATE NOT NULL,
    owner_team TEXT NOT NULL
);

CREATE TABLE content_assets (
    asset_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_name TEXT NOT NULL,
    asset_type asset_type_enum NOT NULL,
    theme TEXT NOT NULL,
    owner_team TEXT NOT NULL,
    published_at DATE NOT NULL
);

CREATE TABLE leads (
    lead_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(account_id),
    campaign_id UUID REFERENCES campaigns(campaign_id),
    lead_name TEXT NOT NULL,
    title TEXT NOT NULL,
    source_channel campaign_channel_enum NOT NULL,
    stage lead_stage_enum NOT NULL,
    mql_date DATE,
    sql_date DATE,
    created_at DATE NOT NULL
);

CREATE TABLE opportunities (
    opportunity_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(account_id),
    lead_id UUID REFERENCES leads(lead_id),
    opportunity_name TEXT NOT NULL,
    stage opportunity_stage_enum NOT NULL,
    forecast_category forecast_category_enum NOT NULL,
    amount NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    probability_pct NUMERIC(5,2) NOT NULL CHECK (probability_pct BETWEEN 0 AND 100),
    expected_close_date DATE NOT NULL,
    created_at DATE NOT NULL
);

CREATE TABLE attribution_touches (
    touch_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    opportunity_id UUID NOT NULL REFERENCES opportunities(opportunity_id),
    lead_id UUID REFERENCES leads(lead_id),
    campaign_id UUID REFERENCES campaigns(campaign_id),
    asset_id UUID REFERENCES content_assets(asset_id),
    touch_position touch_position_enum NOT NULL,
    touch_weight NUMERIC(5,2) NOT NULL CHECK (touch_weight BETWEEN 0 AND 1),
    touch_date DATE NOT NULL
);

CREATE TABLE subscriptions (
    subscription_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id UUID NOT NULL REFERENCES accounts(account_id),
    opportunity_id UUID REFERENCES opportunities(opportunity_id),
    arr_value NUMERIC(12,2) NOT NULL CHECK (arr_value >= 0),
    billing_frequency billing_frequency_enum NOT NULL,
    term_months INTEGER NOT NULL CHECK (term_months > 0),
    start_date DATE NOT NULL,
    end_date DATE NOT NULL
);

CREATE TABLE renewals (
    renewal_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(subscription_id),
    renewal_status renewal_status_enum NOT NULL,
    risk_level TEXT NOT NULL,
    renewal_arr NUMERIC(12,2) NOT NULL CHECK (renewal_arr >= 0),
    renewal_date DATE NOT NULL,
    notes TEXT
);

