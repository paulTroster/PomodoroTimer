local config = require("config")
local utils = require("utils")

local timer = {}

-- Timer state variables
timer.timer_active = false
timer.time_left = config.focus_duration_minutes * 60
timer.session_count = 0
timer.mode = "focus"  -- "focus" or "short_break"
timer.fast_mode = false
timer.time_multiplier = 1

function timer.update_timer()
	if not timer.timer_active then return end

	timer.time_left = timer.time_left - timer.time_multiplier
	if timer.time_left <= 0 then
		if timer.mode == "focus" then
			timer.session_count = timer.session_count + 1
			if timer.session_count >= config.session_limit then
				utils.set_timer_text(config.session_limit_reached_message, config.source_name)
				timer.timer_active = false
				utils.play_media_source(config.session_limit_bgm_source_name)
				return
			else
				timer.mode = "short_break"
				timer.time_left = config.short_break_minutes * 60
				utils.set_timer_text(config.short_break_message, config.source_name)
				utils.play_alert_sound(config.sound_source_name)
				utils.play_media_source(config.break_bgm_source_name)
			end
		else
			utils.stop_media_source(config.break_bgm_source_name)
			utils.play_alert_sound(config.sound_source_name)
			timer.mode = "focus"
			timer.time_left = config.focus_duration_minutes * 60
			utils.set_timer_text(config.focus_message, config.source_name)
		end
	end

	if timer.mode == "focus" then
		local minutes = math.floor(timer.time_left / 60)
		local seconds = timer.time_left % 60
		local timer_display = string.format(
			"%s\nSession: %d/%d\n%02d:%02d",
			config.focus_message, timer.session_count + 1, config.session_limit, minutes, seconds
		)
		utils.set_timer_text(timer_display, config.source_name)
	else
		local minutes = math.floor(timer.time_left / 60)
		local seconds = timer.time_left % 60
		local timer_display = string.format("%s\n%02d:%02d", config.short_break_message, minutes, seconds)
		utils.set_timer_text(timer_display, config.source_name)
	end
end

function timer.start_timer()
	if not timer.timer_active then
		timer.time_left = config.focus_duration_minutes * 60
		timer.timer_active = true
	end
end

function timer.stop_timer()
	if timer.timer_active then
		timer.timer_active = false
	end
end

function timer.skip_session()
	if timer.mode == "focus" then
		timer.session_count = timer.session_count + 1
		if timer.session_count >= config.session_limit then
			utils.set_timer_text(config.session_limit_reached_message, config.source_name)
			timer.timer_active = false
			utils.play_media_source(config.session_limit_bgm_source_name)
		else
			timer.mode = "short_break"
			timer.time_left = config.short_break_minutes * 60
			utils.set_timer_text(config.short_break_message, config.source_name)
			utils.play_alert_sound(config.sound_source_name)
			utils.play_media_source(config.break_bgm_source_name)
		end
	else
		utils.stop_media_source(config.break_bgm_source_name)
		utils.play_alert_sound(config.sound_source_name)
		timer.mode = "focus"
		timer.time_left = config.focus_duration_minutes * 60
		utils.set_timer_text(config.focus_message, config.source_name)
	end
end

return timer
