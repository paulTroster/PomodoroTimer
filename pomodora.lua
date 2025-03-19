-- luacheck: globals obslua script_properties script_load script_unload script_save script_update script_defaults start_timer stop_timer
local obs = obslua

----------------------------------------------------------
-- Configuration Defaults
----------------------------------------------------------
local source_name = "PomodoroTimer" -- Text source for displaying the countdown
local sound_source_name = "AlertSound" -- Media source that plays a short alert/bell
local break_bgm_source_name = "BreakBGM" -- Media source that plays background music during break
local session_limit_bgm_source_name = "SessionLimitMusic" -- Media source that plays at session limit

local focus_duration_minutes = 240 
local short_break_minutes = 10

-- Messages
local focus_message = "Focus Time!"
local short_break_message = "Short Break!"
local session_limit_reached_message = "Session Limit Reached!"

local session_limit = 4

-- Fast Mode: if true, 1 real second = 60 "timer" seconds
local fast_mode = false
local time_multiplier = 1 -- We'll set it in script_update()

----------------------------------------------------------
-- Timer State
----------------------------------------------------------
local timer_active = false
local time_left = focus_duration_minutes * 60
local session_count = 0
local mode = "focus" -- "focus" or "short_break"

----------------------------------------------------------
-- Utility: Set Timer Text
----------------------------------------------------------
local function set_timer_text(text)
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local settings = obs.obs_data_create()
		obs.obs_data_set_string(settings, "text", text)
		obs.obs_source_update(source, settings)
		obs.obs_data_release(settings)
		obs.obs_source_release(source)
	end
end

----------------------------------------------------------
-- Utility: Play a Media Source from the Beginning
----------------------------------------------------------
local function play_media_source(source_name_to_play)
	if not source_name_to_play or source_name_to_play == "" then
		return
	end
	local source = obs.obs_get_source_by_name(source_name_to_play)
	if source ~= nil then
		local src_settings = obs.obs_source_get_settings(source)
		-- Unmute
		obs.obs_data_set_bool(src_settings, "is_muted", false)
		obs.obs_source_update(source, src_settings)
		obs.obs_data_release(src_settings)
		-- Restart from beginning
		obs.obs_source_media_restart(source)
		obs.obs_source_release(source)
	end
end

----------------------------------------------------------
-- Utility: Stop (Mute) a Media Source
----------------------------------------------------------
local function stop_media_source(source_name_to_stop)
	if not source_name_to_stop or source_name_to_stop == "" then
		return
	end
	local source = obs.obs_get_source_by_name(source_name_to_stop)
	if source ~= nil then
		local src_settings = obs.obs_source_get_settings(source)
		obs.obs_data_set_bool(src_settings, "is_muted", true)
		obs.obs_source_update(source, src_settings)
		obs.obs_data_release(src_settings)
		obs.obs_source_release(source)
	end
end

----------------------------------------------------------
-- Utility: Play the Alert Sound (Short Beep/Bell)
----------------------------------------------------------
local function play_alert_sound()
	if not sound_source_name or sound_source_name == "" then
		return
	end
	local source = obs.obs_get_source_by_name(sound_source_name)
	if source ~= nil then
		local src_settings = obs.obs_source_get_settings(source)
		-- Unmute
		obs.obs_data_set_bool(src_settings, "is_muted", false)
		obs.obs_source_update(source, src_settings)
		obs.obs_data_release(src_settings)
		-- Restart from beginning
		obs.obs_source_media_restart(source)
		obs.obs_source_release(source)
	end
end

----------------------------------------------------------
-- Timer Logic (called every second)
----------------------------------------------------------
local function update_timer()
	if not timer_active then
		return
	end

	time_left = time_left - time_multiplier
	if time_left <= 0 then
		if mode == "focus" then
			-- Completed a focus session
			session_count = session_count + 1
			if session_count >= session_limit then
				-- Session limit reached
				set_timer_text(session_limit_reached_message)
				timer_active = false
				-- Play session-limit music
				play_media_source(session_limit_bgm_source_name)
				return
			else
				-- Switch to break
				mode = "short_break"
				time_left = short_break_minutes * 60
				set_timer_text(short_break_message)
				-- Play alert sound at start of break
				play_alert_sound()
				-- Start break BGM
				play_media_source(break_bgm_source_name)
			end
		else
			-- Completed a short break
			-- Stop the break BGM
			stop_media_source(break_bgm_source_name)
			-- Play alert sound at the end of the break
			play_alert_sound()
			-- Return to focus
			mode = "focus"
			time_left = focus_duration_minutes * 60
			set_timer_text(focus_message)
		end
	end

	-- Update the displayed timer text
	if mode == "focus" then
		local minutes = math.floor(time_left / 60)
		local seconds = time_left % 60
		local timer_display = string.format(
			"%s\nSession: %d/%d\n%02d:%02d",
			focus_message,
			session_count + 1,
			session_limit,
			minutes,
			seconds
		)
		set_timer_text(timer_display)
	else
		-- Break mode
		local minutes = math.floor(time_left / 60)
		local seconds = time_left % 60
		local timer_display = string.format("%s\n%02d:%02d", short_break_message, minutes, seconds)
		set_timer_text(timer_display)
	end
end

----------------------------------------------------------
-- Start/Stop Timer
----------------------------------------------------------
function start_timer()
	if not timer_active then
		time_left = focus_duration_minutes * 60
		timer_active = true
	end
end

function stop_timer()
	if timer_active then
		timer_active = false
	end
end

----------------------------------------------------------
-- OBS Script Hooks
----------------------------------------------------------
function script_load(settings)
	obs.timer_add(update_timer, 1000)
end

function script_unload()
	obs.timer_remove(update_timer)
end

-- Updated script description with the new skip functionality
function script_description()
	return "Pomodoro Timer Script<br>" ..
	       "This script controls focus sessions and breaks. Use the Start, Stop, and Skip Session buttons.<br>" ..
	       "Skip Session instantly ends the current phase (focus or break) and moves to the next one."
end

-- Button handler for Start
local function on_start_button_clicked(props, property)
	start_timer()
	return false
end

-- Button handler for Stop
local function on_stop_button_clicked(props, property)
	stop_timer()
	return false
end

-- Updated Button handler for Skip Session (skips current session regardless of mode)
local function on_skip_timer_button_clicked(props, property)
	if mode == "focus" then
		-- Skip focus: simulate end of focus session
		session_count = session_count + 1
		if session_count >= session_limit then
			set_timer_text(session_limit_reached_message)
			timer_active = false
			play_media_source(session_limit_bgm_source_name)
		else
			mode = "short_break"
			time_left = short_break_minutes * 60
			set_timer_text(short_break_message)
			play_alert_sound()
			play_media_source(break_bgm_source_name)
		end
	else
		-- Skip break: simulate end of break session
		stop_media_source(break_bgm_source_name)
		play_alert_sound()
		mode = "focus"
		time_left = focus_duration_minutes * 60
		set_timer_text(focus_message)
	end
	return false
end

-- Updated Script Properties to reflect new button label
function script_properties()
	local props = obs.obs_properties_create()

	-- 1) START/STOP/SKIP BUTTONS AT THE TOP
	obs.obs_properties_add_button(props, "start_timer_button", "Start Timer", on_start_button_clicked)
	obs.obs_properties_add_button(props, "stop_timer_button", "Stop Timer", on_stop_button_clicked)
	obs.obs_properties_add_button(props, "skip_timer_button", "Skip Session", on_skip_timer_button_clicked)
	
	-- 2) CHECKBOX FOR FAST MODE
	obs.obs_properties_add_bool(props, "fast_mode", "Fast Mode (Testing)")

	-- 3) Other config fields
	obs.obs_properties_add_text(props, "source_name", "Timer Text Source", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "sound_source_name", "Alert Sound Source", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "break_bgm_source_name", "Break BGM Source", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(
		props,
		"session_limit_bgm_source_name",
		"Session-Limit Music Source",
		obs.OBS_TEXT_DEFAULT
	)

	obs.obs_properties_add_int(props, "focus_duration", "Focus Minutes", 1, 1440, 1)
	obs.obs_properties_add_int(props, "short_break_minutes", "Short Break Minutes", 1, 1440, 1)
	obs.obs_properties_add_int(props, "session_limit", "Session Limit", 1, 100, 1)

	obs.obs_properties_add_text(
		props,
		"session_limit_reached_message",
		"Session-Limit Reached Message",
		obs.OBS_TEXT_DEFAULT
	)

	return props
end

-- Called when user changes settings in the Scripts window
function script_update(settings)
	-- Fast Mode
	fast_mode = obs.obs_data_get_bool(settings, "fast_mode")
	time_multiplier = fast_mode and 60 or 1

	-- Load other fields
	source_name = obs.obs_data_get_string(settings, "source_name")
	sound_source_name = obs.obs_data_get_string(settings, "sound_source_name")
	break_bgm_source_name = obs.obs_data_get_string(settings, "break_bgm_source_name")
	session_limit_bgm_source_name = obs.obs_data_get_string(settings, "session_limit_bgm_source_name")

	focus_duration_minutes = obs.obs_data_get_int(settings, "focus_duration")
	short_break_minutes = obs.obs_data_get_int(settings, "short_break_minutes")
	session_limit = obs.obs_data_get_int(settings, "session_limit")

	session_limit_reached_message = obs.obs_data_get_string(settings, "session_limit_reached_message")
end

function script_defaults(settings)
	obs.obs_data_set_default_bool(settings, "fast_mode", false)
	obs.obs_data_set_default_string(settings, "source_name", source_name)
	obs.obs_data_set_default_string(settings, "sound_source_name", sound_source_name)
	obs.obs_data_set_default_string(settings, "break_bgm_source_name", break_bgm_source_name)
	obs.obs_data_set_default_string(settings, "session_limit_bgm_source_name", session_limit_bgm_source_name)

	obs.obs_data_set_default_int(settings, "focus_duration", focus_duration_minutes)
	obs.obs_data_set_default_int(settings, "short_break_minutes", short_break_minutes)
	obs.obs_data_set_default_int(settings, "session_limit", session_limit)

	obs.obs_data_set_default_string(settings, "session_limit_reached_message", session_limit_reached_message)
end

function script_save(settings)
	-- Typically unused
end
