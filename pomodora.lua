-- luacheck: globals obslua script_properties script_load script_unload script_save script_update script_defaults
local obs = obslua

----------------------------------------------------------
-- Configuration Defaults
----------------------------------------------------------
local source_name                   = "PomodoroTimer"
local sound_source_name             = "AlertSound"
local break_bgm_source_name         = "BreakBGM"
local session_limit_bgm_source_name = "SessionLimitMusic"

local focus_duration_minutes = 240
local short_break_minutes    = 10
local long_break_minutes     = 10
local session_limit          = 12

local progress_bar_source    = "PomodoroProgressBar"
local progress_bar_blocks    = 12
local blink_state            = false

local focus_message              = "Focus Time!"
local short_break_message        = "Short Break!"
local session_limit_reached_message = "Session Limit Reached!"

local fast_mode      = false
local time_multiplier = 1

----------------------------------------------------------
-- Timer State
----------------------------------------------------------
local timer_active             = false
local time_left                = focus_duration_minutes * 60
local session_count            = 0
local mode                     = "focus"
local session_progress_minutes = 0

----------------------------------------------------------
-- Utility: Set Timer Text
----------------------------------------------------------
local function set_timer_text(text)
  local src = obs.obs_get_source_by_name(source_name)
  if not src then return end
  local d = obs.obs_data_create()
  obs.obs_data_set_string(d, "text", text)
  obs.obs_source_update(src, d)
  obs.obs_data_release(d)
  obs.obs_source_release(src)
end

----------------------------------------------------------
-- Utility: Draw Progress Bar (with blink)
----------------------------------------------------------
local function update_minute_progress_bar()
  local bar_src = obs.obs_get_source_by_name(progress_bar_source)
  if not bar_src then return end

  local d = obs.obs_data_create()
  local total = focus_duration_minutes
  local filled = math.min(session_progress_minutes, total)
  local blocks = progress_bar_blocks

  local per_block = total / blocks
  local filled_blocks = math.floor(filled / per_block)
  if filled_blocks > blocks then filled_blocks = blocks end

  local bar = ""
  for i = 1, blocks do
    if i <= filled_blocks then
      bar = bar .. "█"
    elseif i == filled_blocks + 1 then
      bar = bar .. (blink_state and "░" or " ")
    else
      bar = bar .. "░"
    end
  end

  obs.obs_data_set_string(d, "text", bar)
  obs.obs_source_update(bar_src, d)
  obs.obs_data_release(d)
  obs.obs_source_release(bar_src)
end

----------------------------------------------------------
-- Utility: Media Controls
----------------------------------------------------------
local function play_media(name)
  if name == "" then return end
  local s = obs.obs_get_source_by_name(name)
  if not s then return end
  local d = obs.obs_source_get_settings(s)
  obs.obs_data_set_bool(d, "is_muted", false)
  obs.obs_source_update(s, d)
  obs.obs_data_release(d)
  obs.obs_source_media_restart(s)
  obs.obs_source_release(s)
end

local function stop_media(name)
  if name == "" then return end
  local s = obs.obs_get_source_by_name(name)
  if not s then return end
  local d = obs.obs_source_get_settings(s)
  obs.obs_data_set_bool(d, "is_muted", true)
  obs.obs_source_update(s, d)
  obs.obs_data_release(d)
  obs.obs_source_release(s)
end

local function play_alert_sound()
  play_media(sound_source_name)
end

----------------------------------------------------------
-- Timer Logic (called every second)
----------------------------------------------------------
local function update_timer()
  if not timer_active then return end

  -- blink toggle + redraw
  blink_state = not blink_state
  if mode == "focus" then
    update_minute_progress_bar()
  end

  -- countdown
  time_left = time_left - time_multiplier

  -- minute‐by‐minute track
  if mode == "focus" then
    local elapsed = (focus_duration_minutes * 60 - time_left) / 60
    local pm = math.floor(elapsed)
    if pm > session_progress_minutes then
      session_progress_minutes = pm
    end
  end

  -- phase transitions
  if time_left <= 0 then
    if mode == "focus" then
      session_count = session_count + 1
      if session_count >= session_limit then
        set_timer_text(session_limit_reached_message)
        timer_active = false
        play_media(session_limit_bgm_source_name)
        return
      else
        mode = "short_break"
        time_left = short_break_minutes * 60
        set_timer_text(short_break_message)
        play_alert_sound()
        play_media(break_bgm_source_name)
        session_progress_minutes = 0
        update_minute_progress_bar()
      end
    else
      stop_media(break_bgm_source_name)
      play_alert_sound()
      mode = "focus"
      time_left = focus_duration_minutes * 60
      set_timer_text(focus_message)
    end
  end

  -- update timer text
  if mode == "focus" then
    local m, s = math.floor(time_left/60), time_left%60
    set_timer_text(string.format(
      "%s\nSession: %d/%d\n%02d:%02d", -- Made changes here
      focus_message, session_count+1, session_limit, m, s
    ))
  else
    local m, s = math.floor(time_left/60), time_left%60
    set_timer_text(string.format("%s\n%02d:%02d", short_break_message, m, s))
  end
end

----------------------------------------------------------
-- Start/Stop Timer
----------------------------------------------------------
function start_timer()
  if not timer_active then
    time_left = focus_duration_minutes * 60
    session_progress_minutes = 0
    update_minute_progress_bar()
    timer_active = true
  end
end

function stop_timer()
  if timer_active then timer_active = false end
  -- full reset
  time_left = focus_duration_minutes * 60
  session_count = 0
  session_progress_minutes = 0
  update_minute_progress_bar()
  local m, s = focus_duration_minutes, 0
  set_timer_text(string.format(
    "%s\nSession: 1/%d\n%02d:%02d",
    focus_message, session_limit, m, s
  ))
end

----------------------------------------------------------
-- Button Handlers
----------------------------------------------------------
local function on_start_button_clicked()  start_timer() return false end
local function on_stop_button_clicked()   stop_timer()  return false end
local function on_skip_timer_button_clicked()
  if mode == "focus" then
    session_count = session_count + 1
    if session_count >= session_limit then
      set_timer_text(session_limit_reached_message)
      timer_active = false
      play_media(session_limit_bgm_source_name)
    else
      mode = "short_break"
      time_left = short_break_minutes * 60
      set_timer_text(short_break_message)
      play_alert_sound()
      play_media(break_bgm_source_name)
    end
    session_progress_minutes = 0
    update_minute_progress_bar()
  else
    stop_media(break_bgm_source_name)
    play_alert_sound()
    mode = "focus"
    time_left = focus_duration_minutes * 60
    set_timer_text(focus_message)
    session_progress_minutes = 0
    update_minute_progress_bar()
  end
  return false
end

----------------------------------------------------------
-- OBS Script Hooks & UI
----------------------------------------------------------
function script_load(_)    obs.timer_add(update_timer, 1000) end
function script_unload()   obs.timer_remove(update_timer)  end

function script_description()
  return [[
    Pomodoro Timer with blinking progress bar.
    Use Start, Stop & Skip Session.
  ]]
end

function script_properties()
  local p = obs.obs_properties_create()
  obs.obs_properties_add_button(p, "start_btn", "Start Timer", on_start_button_clicked)
  obs.obs_properties_add_button(p, "stop_btn",  "Stop Timer",  on_stop_button_clicked)
  obs.obs_properties_add_button(p, "skip_btn",  "Skip Session", on_skip_timer_button_clicked)
  obs.obs_properties_add_bool(p, "fast_mode", "Fast Mode (Testing)")
  obs.obs_properties_add_text(p, "source_name", "Timer Text Source", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(p, "sound_source_name", "Alert Sound Source", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(p, "break_bgm_source_name", "Break BGM Source", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(p, "session_limit_bgm_source_name", "Session-Limit Music Source", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_int(p, "focus_duration",      "Focus Minutes",       1, 1440, 1)
  obs.obs_properties_add_int(p, "short_break_minutes", "Short Break Minutes", 1, 1440, 1)
  obs.obs_properties_add_int(p, "long_break_minutes",  "Long Break Minutes",  1, 1440, 1)
  obs.obs_properties_add_int(p, "session_limit",       "Session Limit",       1, 100, 1)
  obs.obs_properties_add_text(p, "session_limit_reached_message", "Session-Limit Reached Message", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_text(p, "progress_bar_source", "Progress Bar Text Source", obs.OBS_TEXT_DEFAULT)
  obs.obs_properties_add_int(p, "progress_bar_blocks", "Progress Bar Blocks", 1, 100, 1)
  return p
end

function script_update(data)
  fast_mode      = obs.obs_data_get_bool(data, "fast_mode")
  time_multiplier = fast_mode and 60 or 1

  source_name                    = obs.obs_data_get_string(data, "source_name")
  sound_source_name              = obs.obs_data_get_string(data, "sound_source_name")
  break_bgm_source_name          = obs.obs_data_get_string(data, "break_bgm_source_name")
  session_limit_bgm_source_name  = obs.obs_data_get_string(data, "session_limit_bgm_source_name")
  focus_duration_minutes         = obs.obs_data_get_int(data, "focus_duration")
  short_break_minutes            = obs.obs_data_get_int(data, "short_break_minutes")
  long_break_minutes             = obs.obs_data_get_int(data, "long_break_minutes")
  session_limit                  = obs.obs_data_get_int(data, "session_limit")
  session_limit_reached_message  = obs.obs_data_get_string(data, "session_limit_reached_message")
  progress_bar_source            = obs.obs_data_get_string(data, "progress_bar_source")
  progress_bar_blocks            = obs.obs_data_get_int(data, "progress_bar_blocks")
end

function script_defaults(data)
  obs.obs_data_set_default_bool(data, "fast_mode", false)
  obs.obs_data_set_default_string(data, "source_name", source_name)
  obs.obs_data_set_default_string(data, "sound_source_name", sound_source_name)
  obs.obs_data_set_default_string(data, "break_bgm_source_name", break_bgm_source_name)
  obs.obs_data_set_default_string(data, "session_limit_bgm_source_name", session_limit_bgm_source_name)
  obs.obs_data_set_default_int(data, "focus_duration", focus_duration_minutes)
  obs.obs_data_set_default_int(data, "short_break_minutes", short_break_minutes)
  obs.obs_data_set_default_int(data, "long_break_minutes", long_break_minutes)
  obs.obs_data_set_default_int(data, "session_limit", session_limit)
  obs.obs_data_set_default_string(data, "session_limit_reached_message", session_limit_reached_message)
  obs.obs_data_set_default_string(data, "progress_bar_source", progress_bar_source)
  obs.obs_data_set_default_int(data, "progress_bar_blocks", progress_bar_blocks)
end

function script_save(_) end
