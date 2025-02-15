-- luacheck: globals obslua script_properties script_load script_save script_update script_defaults start_timer stop_timer
local obs = obslua

----------------------------------------------------------
-- Configuration Defaults (locals)
----------------------------------------------------------
local source_name = "PomodoroTimer" -- Name of your text source in OBS
local focus_duration_minutes = 90 -- Focus duration (minutes)
local short_break_minutes = 15 -- Short break duration (minutes)
local long_break_minutes = 20 -- Long break duration (minutes)

-- Customizable messages
local focus_message = "Focus Time!"
local short_break_message = "Short Break!"
local long_break_message = "Long Break!"

-- Session limit for focus sessions
local session_limit = 4

----------------------------------------------------------
-- Timer State Variables (locals)
----------------------------------------------------------
local timer_active = false
local time_left = focus_duration_minutes * 60
local session_count = 0
local mode = "focus" -- Modes: "focus", "short_break", "long_break"

----------------------------------------------------------
-- Utility Functions (locals)
----------------------------------------------------------

-- Update the OBS text source.
-- Displays session info if in focus mode, or "Break" if in break mode.
local function set_timer_text(text)
	local source = obs.obs_get_source_by_name(source_name)
	if source then
		local settings = obs.obs_data_create()
		local header = ""
		if mode == "focus" then
			header = string.format("Session: %d / %d", session_count, session_limit)
		else
			header = "Break"
		end
		local finalText = string.format("%s\n%s", header, text)
		obs.obs_data_set_string(settings, "text", finalText)
		obs.obs_source_update(source, settings)
		obs.obs_data_release(settings)
		obs.obs_source_release(source)
	end
end

-- Format seconds as MM:SS
local function format_time(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%02d:%02d", minutes, secs)
end

-- Load configuration settings from OBS
local function load_config(settings)
	focus_duration_minutes = obs.obs_data_get_int(settings, "focus_duration_minutes") or focus_duration_minutes
	short_break_minutes = obs.obs_data_get_int(settings, "short_break_minutes") or short_break_minutes
	long_break_minutes = obs.obs_data_get_int(settings, "long_break_minutes") or long_break_minutes
	source_name = obs.obs_data_get_string(settings, "source_name") or source_name
	focus_message = obs.obs_data_get_string(settings, "focus_message") or focus_message
	short_break_message = obs.obs_data_get_string(settings, "short_break_message") or short_break_message
	long_break_message = obs.obs_data_get_string(settings, "long_break_message") or long_break_message
end

----------------------------------------------------------
-- Timer Functions (locals)
----------------------------------------------------------

-- Timer callback function (called every second)
local function timer_callback()
	if not timer_active then
		return
	end

	time_left = time_left - 1

	if time_left <= 0 then
		if mode == "focus" then
			session_count = session_count + 1
			if session_count % session_limit == 0 then
				mode = "long_break"
				time_left = long_break_minutes * 60
				set_timer_text(long_break_message)
			else
				mode = "short_break"
				time_left = short_break_minutes * 60
				set_timer_text(short_break_message)
			end
		else
			mode = "focus"
			time_left = focus_duration_minutes * 60
			set_timer_text(focus_message)
		end
	else
		set_timer_text(format_time(time_left))
	end
end

----------------------------------------------------------
-- OBS Callback Functions (locals, then exported to globals)
----------------------------------------------------------

local function start_timer(pressed)
	if timer_active then
		return
	end

	timer_active = true
	time_left = focus_duration_minutes * 60 -- Reset to full focus duration
	mode = "focus"
	session_count = 0
	set_timer_text(focus_message)
	obs.timer_add(timer_callback, 1000)
end
_G.start_timer = start_timer

local function stop_timer(pressed)
	if timer_active then
		timer_active = false
		obs.timer_remove(timer_callback)
		set_timer_text("Timer Stopped")
	end
end
_G.stop_timer = stop_timer

local function script_properties()
	local props = obs.obs_properties_create()

	obs.obs_properties_add_text(props, "source_name", "Text Source Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_int(props, "focus_duration_minutes", "Focus Duration (minutes)", 1, 180, 1)
	obs.obs_properties_add_int(props, "short_break_minutes", "Short Break (minutes)", 1, 30, 1)
	obs.obs_properties_add_int(props, "long_break_minutes", "Long Break (minutes)", 1, 60, 1)
	obs.obs_properties_add_text(props, "focus_message", "Focus Message", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "short_break_message", "Short Break Message", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "long_break_message", "Long Break Message", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_button(props, "start_button", "Start Timer", start_timer)
	obs.obs_properties_add_button(props, "stop_button", "Stop Timer", stop_timer)

	return props
end
_G.script_properties = script_properties

-- This function sets the default values for your script settings.
local function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "focus_duration_minutes", focus_duration_minutes)
	obs.obs_data_set_default_int(settings, "short_break_minutes", short_break_minutes)
	obs.obs_data_set_default_int(settings, "long_break_minutes", long_break_minutes)
	obs.obs_data_set_default_string(settings, "source_name", source_name)
	obs.obs_data_set_default_string(settings, "focus_message", focus_message)
	obs.obs_data_set_default_string(settings, "short_break_message", short_break_message)
	obs.obs_data_set_default_string(settings, "long_break_message", long_break_message)
end
_G.script_defaults = script_defaults

local function script_load(settings)
	load_config(settings)
end
_G.script_load = script_load

local function script_save(settings)
	obs.obs_data_set_int(settings, "focus_duration_minutes", focus_duration_minutes)
	obs.obs_data_set_int(settings, "short_break_minutes", short_break_minutes)
	obs.obs_data_set_int(settings, "long_break_minutes", long_break_minutes)
	obs.obs_data_set_string(settings, "source_name", source_name)
	obs.obs_data_set_string(settings, "focus_message", focus_message)
	obs.obs_data_set_string(settings, "short_break_message", short_break_message)
	obs.obs_data_set_string(settings, "long_break_message", long_break_message)
end
_G.script_save = script_save

local function script_update(settings)
	load_config(settings)
end
_G.script_update = script_update
