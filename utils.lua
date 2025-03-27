local obs = obslua
local utils = {}

function utils.set_timer_text(text, source_name)
	local source = obs.obs_get_source_by_name(source_name)
	if source then
		local settings = obs.obs_data_create()
		obs.obs_data_set_string(settings, "text", text)
		obs.obs_source_update(source, settings)
		obs.obs_data_release(settings)
		obs.obs_source_release(source)
	end
end

function utils.play_media_source(source_name_to_play)
	if not source_name_to_play or source_name_to_play == "" then return end
	local source = obs.obs_get_source_by_name(source_name_to_play)
	if source then
		local src_settings = obs.obs_source_get_settings(source)
		obs.obs_data_set_bool(src_settings, "is_muted", false)
		obs.obs_source_update(source, src_settings)
		obs.obs_data_release(src_settings)
		obs.obs_source_media_restart(source)
		obs.obs_source_release(source)
	end
end

function utils.stop_media_source(source_name_to_stop)
	if not source_name_to_stop or source_name_to_stop == "" then return end
	local source = obs.obs_get_source_by_name(source_name_to_stop)
	if source then
		local src_settings = obs.obs_source_get_settings(source)
		obs.obs_data_set_bool(src_settings, "is_muted", true)
		obs.obs_source_update(source, src_settings)
		obs.obs_data_release(src_settings)
		obs.obs_source_release(source)
	end
end

function utils.play_alert_sound(sound_source_name)
	if not sound_source_name or sound_source_name == "" then return end
	local source = obs.obs_get_source_by_name(sound_source_name)
	if source then
		local src_settings = obs.obs_source_get_settings(source)
		obs.obs_data_set_bool(src_settings, "is_muted", false)
		obs.obs_source_update(source, src_settings)
		obs.obs_data_release(src_settings)
		obs.obs_source_media_restart(source)
		obs.obs_source_release(source)
	end
end

return utils