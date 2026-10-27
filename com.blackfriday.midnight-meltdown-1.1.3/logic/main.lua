local M = {}
local INCIDENT_NS = 259200000000000 -- 72 hours of simulated time
local BASE_HOSTS = 2

local function countdown(ns)
  local left = math.max(0, INCIDENT_NS - (ns or 0))
  local total_seconds = math.floor(left / 1000000000)
  local days = math.floor(total_seconds / 86400)
  local hours = math.floor((total_seconds % 86400) / 3600)
  local minutes = math.floor((total_seconds % 3600) / 60)
  if left <= 0 then return "INCIDENT WINDOW OPEN" end
  if days > 0 then return string.format("%dd %02dh %02dm", days, hours, minutes) end
  return string.format("%02dh %02dm", hours, minutes)
end

function M.init(ctx)
  local saved = ctx.state or {}
  return { started_ns = saved.started_ns or 0 }
end

function M.step(ctx)
  local snap = ctx.snapshot or {}
  local topbar = snap.topbar or {}
  local now = (ctx.quantum and ctx.quantum.sim_time_ns) or snap.sim_time_ns or 0
  local host_count = #(snap.hosts or {})
  local left = INCIDENT_NS - now
  local upgraded = host_count > BASE_HOSTS
  local ready_text
  local tone

  if left <= 0 then
    ready_text = "INCIDENT WINDOW OPEN. Stabilise services and protect customers."
    tone = "Danger"
  elseif upgraded then
    ready_text = "Upgrade detected. Check spare capacity, switching, gateway throughput and cash reserves."
    tone = "Good"
  else
    ready_text = "UPGRADE REQUIRED: add host capacity before the countdown reaches zero. Also review gateway and switch headroom."
    tone = "Warn"
  end

  ctx:panel("countdown_hud", {
    values = {
      time_left = { Stat = { value = countdown(now), detail = left <= 0 and "incident window open" or "upgrade before zero", tone = tone } },
      upgrade = { Text = ready_text },
    },
  })

  ctx:panel("black_friday_board", {
    values = {
      countdown = { Stat = { value = countdown(now), detail = "72-hour preparation deadline", tone = tone } },
      hosts = { Stat = { value = tostring(host_count), detail = upgraded and "additional host detected" or "starting baseline: 2 hosts", tone = upgraded and "Good" or "Warn" } },
      customers = { Stat = { value = tostring(topbar.customer_count or 0), detail = "current customers", tone = "Neutral" } },
      readiness = { Text = ready_text .. "\n\nSuggested checks:\n1. Add host capacity.\n2. Check switch ports and uplink bandwidth.\n3. Check gateway capacity.\n4. Keep emergency cash available." },
    },
  })
  ctx:save_state({ started_ns = now })
end

function M.migrate(_from_schema, saved)
  return saved or { started_ns = 0 }
end

return M
