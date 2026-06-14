-- Production indexes for high-traffic home, fixtures, predictions, sponsors, and links.
-- These are safe to run repeatedly and do not alter business rules or RLS policies.

create index if not exists idx_matches_status_start_lock
  on public.matches (status, match_start_at, prediction_lock_at);

create index if not exists idx_matches_start_status
  on public.matches (match_start_at, status);

create index if not exists idx_match_predictions_match_points_submitted
  on public.match_predictions (match_id, points_total desc, submitted_at asc);

create index if not exists idx_match_predictions_user_submitted
  on public.match_predictions (user_id, submitted_at desc);

create index if not exists idx_match_predictions_match_user
  on public.match_predictions (match_id, user_id);

create index if not exists idx_sponsor_banners_home_lookup
  on public.sponsor_banners (placement, slot, is_active, sort_order);

create index if not exists idx_app_links_key_active
  on public.app_links (link_key, is_active);

create index if not exists idx_match_prize_pools_match_active
  on public.match_prize_pools (match_id, is_active);
