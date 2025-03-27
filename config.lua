local config = {}

config.source_name = "PomodoroTimer"             -- Timer text source
config.sound_source_name = "AlertSound"            -- Alert sound source
config.break_bgm_source_name = "BreakBGM"            -- Break background music source
config.session_limit_bgm_source_name = "SessionLimitMusic" -- Session-limit music source

config.focus_duration_minutes = 240
config.short_break_minutes = 10

config.focus_message = "Focus Time!"
config.short_break_message = "Short Break!"
config.session_limit_reached_message = "Session Limit Reached!"

config.session_limit = 4

return config
