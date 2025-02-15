-- Pomodoro Pro Timer V1 for OBS By Animal shadow
obs = obslua
source_name = "PomodoroTimer" -- Change this to the name of your text source in OBS
focus_duration_minutes = 90 -- default 90 minutes
short_break_minutes = 15 -- default 15 minutes
long_break_minutes = 20 -- default 20 minutes
timer_active = false
time_left = focus_duration_minutes * 60
session_count = 0
mode = "focus" -- Initialize the mode as focus

-- Customizable messages
focus_message = "Focus Time!" -- Default focus message
short_break_message = "Short Break!" -- Default short break message
long_break_message = "Long Break!" -- Default long break message

-- Function to set the timer text
function set_timer_text(text)
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local settings = obs.obs_data_create()
		obs.obs_data_set_string(settings, "text", text)
		obs.obs_source_update(source, settings)
		obs.obs_data_release(settings)
		obs.obs_source_release(source)
	end
end

-- Timer callback function
function timer_callback()
	if not timer_active then
		return
	end

	time_left = time_left - 1

	if time_left <= 0 then
		if session_count % 4 == 0 and session_count ~= 0 then
			time_left = long_break_minutes * 60
			set_timer_text(long_break_message)
			mode = "long_break"
		elseif mode == "focus" then
			time_left = short_break_minutes * 60
			set_timer_text(short_break_message)
			mode = "break"
		else
			time_left = focus_duration_minutes * 60
			set_timer_text(focus_message)
			mode = "focus"
			session_count = session_count + 1
		end
	else
		local minutes = math.floor(time_left / 60)
		local seconds = time_left % 60
		set_timer_text(string.format("%02d:%02d", minutes, seconds))
	end
end

-- Function to start the timer
function start_timer(pressed)
	if not timer_active then
		timer_active = true
		time_left = focus_duration_minutes * 60 -- Reset time to full duration
		mode = "focus" -- Reset mode to focus
		session_count = 0 -- Reset session count
		set_timer_text(focus_message) -- Show the initial focus message
		obs.timer_add(timer_callback, 1000)
	end
end

-- Function to stop the timer
function stop_timer(pressed)
	if timer_active then
		timer_active = false
		obs.timer_remove(timer_callback)
		set_timer_text("Timer Stopped") -- Update text to indicate stopped timer
	end
end

-- Script properties for customization in OBS
function script_properties()
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

-- Load the script settings
function script_load(settings)
	focus_duration_minutes = obs.obs_data_get_int(settings, "focus_duration_minutes") or focus_duration_minutes
	short_break_minutes = obs.obs_data_get_int(settings, "short_break_minutes") or short_break_minutes
	long_break_minutes = obs.obs_data_get_int(settings, "long_break_minutes") or long_break_minutes
	source_name = obs.obs_data_get_string(settings, "source_name") or source_name
	focus_message = obs.obs_data_get_string(settings, "focus_message") or focus_message
	short_break_message = obs.obs_data_get_string(settings, "short_break_message") or short_break_message
	long_break_message = obs.obs_data_get_string(settings, "long_break_message") or long_break_message
end

-- Save the script settings
function script_save(settings)
	obs.obs_data_set_int(settings, "focus_duration_minutes", focus_duration_minutes)
	obs.obs_data_set_int(settings, "short_break_minutes", short_break_minutes)
	obs.obs_data_set_int(settings, "long_break_minutes", long_break_minutes)
	obs.obs_data_set_string(settings, "source_name", source_name)
	obs.obs_data_set_string(settings, "focus_message", focus_message)
	obs.obs_data_set_string(settings, "short_break_message", short_break_message)
	obs.obs_data_set_string(settings, "long_break_message", long_break_message)
end

-- Update the script settings
function script_update(settings)
	focus_duration_minutes = obs.obs_data_get_int(settings, "focus_duration_minutes") or focus_duration_minutes
	short_break_minutes = obs.obs_data_get_int(settings, "short_break_minutes") or short_break_minutes
	long_break_minutes = obs.obs_data_get_int(settings, "long_break_minutes") or long_break_minutes
	source_name = obs.obs_data_get_string(settings, "source_name") or source_name
	focus_message = obs.obs_data_get_string(settings, "focus_message") or focus_message
	short_break_message = obs.obs_data_get_string(settings, "short_break_message") or short_break_message
	long_break_message = obs.obs_data_get_string(settings, "long_break_message") or long_break_message
end
