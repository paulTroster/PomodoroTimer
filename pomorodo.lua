-- luacheck: globals obslua script_properties script_load script_save script_update script_defaults start_timer stop_timer
local obs = obslua

----------------------------------------------------------
-- Configuration Defaults (locals)
----------------------------------------------------------
local source_name = "PomodoroTimer" -- Name of your text source in OBS
local sound_source_name = "AlertSound" -- Name of your media source for playing sound

local focus_duration_minutes = 90 -- Focus duration (minutes)
local short_break_minutes = 15 -- Short break duration (minutes)
local long_break_minutes = 20 -- Long break duration (minutes)

-- Customizable messages
local focus_message = "Focus Time!"
local short_break_message = "Short Break!"
local long_break_message = "Long Break!"

-- Session limit for focus sessions (only used when not testing breaks)
local session_limit = 4

-- Testing Mode for break transitions:
-- When true, the timer simply alternates between focus and break modes,
-- ignoring session count and long break durations.
local test_breaks = false

-- Fast mode: when enabled, time passes faster for testing purposes.
-- In fast mode, each real second simulates 60 seconds (1 minute) of timer time.
local fast_mode = true
local time_multiplier = fast_mode and 60 or 1

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

-- Play sound using the media source specified by sound_source_name.
local function play_sound()
	local source = obs.obs_get_source_by_name(sound_source_name)
	if source then
		obs.obs_source_media_restart(source)
		obs.obs_source_release(source)
	else
		obs.script_log(obs.LOG_WARNING, "Sound source '" .. sound_source_name .. "' not found!")
	end
end

-- Load configuration settings from OBS
local function load_config(settings)
	focus_duration_minutes = obs.obs_data_get_int(settings, "focus_duration_minutes") or focus_duration_minutes
	short_break_minutes = obs.obs_data_get_int(settings, "short_break_minutes") or short_break_minutes
	long_break_minutes = obs.obs_data_get_int(settings, "long_break_minutes") or long_break_minutes

	source_name = obs.obs_data_get_string(settings, "source_name") or source_name
	sound_source_name = obs.obs_data_get_string(settings, "sound_source_name") or sound_source_name

	focus_message = obs.obs_data_get_string(settings, "focus_message") or focus_message
	short_break_message = obs.obs_data_get_string(settings, "short_break_message") or short_break_message
	long_break_message = obs.obs_data_get_string(settings, "long_break_message") or long_break_message

	test_breaks = obs.obs_data_get_bool(settings, "test_breaks")

	fast_mode = obs.obs_data_get_bool(settings, "fast_mode")
	time_multiplier = fast_mode and 60 or 1
end

----------------------------------------------------------
-- Timer Functions (locals)
----------------------------------------------------------

-- Timer callback function (called every second)
local function timer_callback()
	if not timer_active then
		return
	end

	-- Subtract more seconds per tick when in fast mode.
	time_left = time_left - time_multiplier

	if time_left <= 0 then
		if test_breaks then
			-- Testing mode: simple toggle between focus and break.
			if mode == "focus" then
				mode = "short_break"
				time_left = short_break_minutes * 60
				set_timer_text(short_break_message)
			else
				mode = "focus"
				time_left = focus_duration_minutes * 60
				set_timer_text(focus_message)
			end
			play_sound()
		else
			-- Regular mode: use session count logic.
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
				play_sound()
			else
				mode = "focus"
				time_left = focus_duration_minutes * 60
				set_timer_text(focus_message)
				play_sound()
			end
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
	obs.obs_properties_add_text(props, "sound_source_name", "Sound Source Name", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_int(props, "focus_duration_minutes", "Focus Duration (minutes)", 1, 180, 1)
	obs.obs_properties_add_int(props, "short_break_minutes", "Short Break (minutes)", 1, 30, 1)
	obs.obs_properties_add_int(props, "long_break_minutes", "Long Break (minutes)", 1, 60, 1)
	obs.obs_properties_add_text(props, "focus_message", "Focus Message", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "short_break_message", "Short Break Message", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_text(props, "long_break_message", "Long Break Message", obs.OBS_TEXT_DEFAULT)
	obs.obs_properties_add_bool(props, "test_breaks", "Test Breaks Mode")
	obs.obs_properties_add_bool(props, "fast_mode", "Fast Mode (Accelerated Time)")
	obs.obs_properties_add_button(props, "start_button", "Start Timer", start_timer)
	obs.obs_properties_add_button(props, "stop_button", "Stop Timer", stop_timer)

	return props
end
_G.script_properties = script_properties

-- Set default values so that OBS loads your defaults in the properties.
local function script_defaults(settings)
	obs.obs_data_set_default_int(settings, "focus_duration_minutes", focus_duration_minutes)
	obs.obs_data_set_default_int(settings, "short_break_minutes", short_break_minutes)
	obs.obs_data_set_default_int(settings, "long_break_minutes", long_break_minutes)
	obs.obs_data_set_default_string(settings, "source_name", source_name)
	obs.obs_data_set_default_string(settings, "sound_source_name", sound_source_name)
	obs.obs_data_set_default_string(settings, "focus_message", focus_message)
	obs.obs_data_set_default_string(settings, "short_break_message", short_break_message)
	obs.obs_data_set_default_string(settings, "long_break_message", long_break_message)
	obs.obs_data_set_default_bool(settings, "test_breaks", test_breaks)
	obs.obs_data_set_default_bool(settings, "fast_mode", fast_mode)
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
	obs.obs_data_set_string(settings, "sound_source_name", sound_source_name)
	obs.obs_data_set_string(settings, "focus_message", focus_message)
	obs.obs_data_set_string(settings, "short_break_message", short_break_message)
	obs.obs_data_set_string(settings, "long_break_message", long_break_message)
	obs.obs_data_set_bool(settings, "test_breaks", test_breaks)
	obs.obs_data_set_bool(settings, "fast_mode", fast_mode)
end
_G.script_save = script_save

local function script_update(settings)
	load_config(settings)
end
_G.script_update = script_update
