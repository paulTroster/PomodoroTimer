local obs = obslua
local timer = require("timer")
local config = require("config")

function script_load(settings)
	obs.timer_add(timer.update_timer, 1000)
end

function script_unload()
	obs.timer_remove(timer.update_timer)
end

function script_description()
	return "Pomodoro Timer Script<br>" ..
	       "This script controls focus sessions and breaks. Use the Start, Stop, and Skip Session buttons.<br>" ..
	       "Skip Session instantly ends the current phase (focus or break) and moves to the next one."
end

local function on_start_button_clicked(props, property)
	timer.start_timer()
	return false
end

local function on_stop_button_clicked(props, property)
	timer.stop_timer()
	return false
end

local function on_skip_timer_button_clicked(props, property)
	timer.skip_session()
	return false
end

function script_properties()
	local props = obs.obs_properties_create()
	obs.obs_properties_add_button(props, "start_timer_button", "Start Timer", on_start_button_clicked)
	obs.obs_properties_add_button(props, "stop_timer_button", "Stop Timer", on_stop_button_clicked)
	obs.obs_properties_add_button(props, "skip_timer_button", "Skip Session", on_skip_timer_button_clicked)
	obs.obs_properties_add_bool(props, "fast_mode", "Fast Mode (Testing)")
	obs.obs_properties_add_text(props, "source_name", "Timer Text Source", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "sound_source_name", "Alert Sound Source", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "break_bgm_source_name", "Break BGM Source", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "session_limit_bgm_source_name", "Session-Limit Music Source", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_int(props, "focus_duration", "Focus Minutes", 1, 1440, 1)
	obs.obs_properties_add_int(props, "short_break_minutes", "Short Break Minutes", 1, 1440, 1)
	obs.obs_properties_add_int(props, "session_limit", "Session Limit", 1, 100, 1)
	obs.obs_properties_add_text(props, "session_limit_reached_message", "Session-Limit Reached Message", obs.OBS_TEXT_DEFAULT)
	return props
end

function script_update(settings)
	timer.fast_mode = obs.obs_data_get_bool(settings, "fast_mode")
	timer.time_multiplier = timer.fast_mode and 60 or 1

	config.source_name = obs.obs_data_get_string(settings, "source_name")
	config.sound_source_name = obs.obs_data_get_string(settings, "sound_source_name")
	config.break_bgm_source_name = obs.obs_data_get_string(settings, "break_bgm_source_name")
	config.session_limit_bgm_source_name = obs.obs_data_get_string(settings, "session_limit_bgm_source_name")
	config.focus_duration_minutes = obs.obs_data_get_int(settings, "focus_duration")
	config.short_break_minutes = obs.obs_data_get_int(settings, "short_break_minutes")
	config.session_limit = obs.obs_data_get_int(settings, "session_limit")
	config.session_limit_reached_message = obs.obs_data_get_string(settings, "session_limit_reached_message")
end

function script_defaults(settings)
	obs.obs_data_set_default_bool(settings, "fast_mode", false)
	obs.obs_data_set_default_string(settings, "source_name", config.source_name)
	obs.obs_data_set_default_string(settings, "sound_source_name", config.sound_source_name)
	obs.obs_data_set_default_string(settings, "break_bgm_source_name", config.break_bgm_source_name)
	obs.obs_data_set_default_string(settings, "session_limit_bgm_source_name", config.session_limit_bgm_source_name)
	obs.obs_data_set_default_int(settings, "focus_duration", config.focus_duration_minutes)
	obs.obs_data_set_default_int(settings, "short_break_minutes", config.short_break_minutes)
	obs.obs_data_set_default_int(settings, "session_limit", config.session_limit)
	obs.obs_data_set_default_string(settings, "session_limit_reached_message", config.session_limit_reached_message)
end

function script_save(settings)
	-- Typically unused
end
