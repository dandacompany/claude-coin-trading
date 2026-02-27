-- 암호화폐 자동매매 시스템 초기 스키마

-- 1. 매매 결정 기록
CREATE TABLE decisions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  market TEXT NOT NULL DEFAULT 'KRW-BTC',
  decision TEXT NOT NULL CHECK (decision IN ('매수', '매도', '관망')),
  confidence DECIMAL(3,2),
  reason TEXT NOT NULL,
  market_data_snapshot TEXT,
  fear_greed_value INTEGER,
  rsi_value DECIMAL(5,2),
  current_price BIGINT,
  sma20_price BIGINT,
  trade_amount BIGINT,
  trade_volume DECIMAL(18,8),
  executed BOOLEAN DEFAULT FALSE,
  execution_result JSONB,
  profit_loss DECIMAL(10,2),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_decisions_created_at ON decisions(created_at DESC);
CREATE INDEX idx_decisions_market ON decisions(market);
CREATE INDEX idx_decisions_decision ON decisions(decision);

-- 2. 포트폴리오 스냅샷
CREATE TABLE portfolio_snapshots (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  total_krw BIGINT NOT NULL,
  total_crypto_value BIGINT NOT NULL,
  total_value BIGINT NOT NULL,
  holdings JSONB NOT NULL,
  daily_return DECIMAL(10,4),
  cumulative_return DECIMAL(10,4),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_portfolio_created_at ON portfolio_snapshots(created_at DESC);

-- 3. 시장 데이터 기록
CREATE TABLE market_data (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  market TEXT NOT NULL DEFAULT 'KRW-BTC',
  price BIGINT NOT NULL,
  volume_24h DECIMAL(18,4),
  change_rate_24h DECIMAL(10,6),
  fear_greed_value INTEGER,
  fear_greed_class TEXT,
  rsi_14 DECIMAL(5,2),
  sma_20 BIGINT,
  news_sentiment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_market_data_created_at ON market_data(created_at DESC);

-- 4. 사용자 피드백
CREATE TABLE feedback (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  type TEXT NOT NULL CHECK (type IN ('parameter_change', 'behavior_change', 'one_time', 'general')),
  content TEXT NOT NULL,
  applied BOOLEAN DEFAULT FALSE,
  applied_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_feedback_applied ON feedback(applied);
CREATE INDEX idx_feedback_type ON feedback(type);

-- 5. 실행 로그
CREATE TABLE execution_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  execution_mode TEXT NOT NULL CHECK (execution_mode IN ('analyze', 'execute', 'dry_run')),
  decision_id UUID REFERENCES decisions(id),
  duration_ms INTEGER,
  data_sources JSONB,
  errors JSONB,
  raw_output TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_execution_logs_created_at ON execution_logs(created_at DESC);

-- 6. 전략 변경 이력
CREATE TABLE strategy_history (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  version INTEGER NOT NULL,
  content TEXT NOT NULL,
  change_summary TEXT,
  changed_by TEXT DEFAULT 'user',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_strategy_history_version ON strategy_history(version DESC);
