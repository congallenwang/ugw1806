#!/usr/bin/lua
package.path='/opt/lantiq/wave/scripts/?.lua'
require("uci")
--dofile('/opt/lantiq/wave/scripts/map_opwrt_wave.lua')
dofile('/opt/lantiq/wave/scripts/wave_util.lua')
dofile('/opt/lantiq/wave/scripts/security_config.lua')
dofile('/opt/lantiq/wave/scripts/radio_config.lua')
dofile('/opt/lantiq/wave/scripts/wps_config.lua')
dofile('/opt/lantiq/wave/scripts/macaddr_acl_config.lua')

local pantek_os = require("pantek_os")
local pantek_wave_up = require("pantek_wave_up")
local x = uci.cursor()
local xuci = require('luci.model.uci').cursor()

--%s;conf_file:write(string.format(\(.*\)=%[sd\\n", ]*['"]\(.*\)['"]));write_str_config(conf_file, \1", '\2', '\2');g
--################ Physical radio parameters ################
function physical_radio_setting(conf_file, device_name, opwrt_device_dir)
	conf_file:write("################ Physical radio parameters ################\n")
	write_str_config(conf_file, "interface", device_name, nil) 
	write_str_config(conf_file, "driver", 'nl80211', 'nl80211') 
	write_str_config(conf_file, "logger_syslog_level", '3', '3') 
	write_str_config(conf_file, "ctrl_interface", '/var/run/hostapd', '/var/run/hostapd')
	write_str_config(conf_file, "ctrl_interface_group", '0', '0')
--	write_str_config(conf_file, "atf_config_file", '/tmp/wlan_wave/hostapd_atf_wlan0.conf', '/tmp/wlan_wave/hostapd_atf_wlan0.conf') 
end
function  wmm_setting(conf_file, opwrt_device_dir)
	conf_file:write("###___WMM_parameters___###\n")
	write_str_config(conf_file, 'wmm_ac_be_aifs', '3', '3')
	write_str_config(conf_file, 'wmm_ac_be_cwmin', '4', '4')
	write_str_config(conf_file, 'wmm_ac_be_cwmax', '10', '10')
	write_str_config(conf_file, 'wmm_ac_be_txop_limit', '0', '0')
	write_str_config(conf_file, 'wmm_ac_bk_aifs', '7', '7')
	write_str_config(conf_file, 'wmm_ac_bk_cwmin', '4', '4')
	write_str_config(conf_file, 'wmm_ac_bk_cwmax', '10', '10')
	write_str_config(conf_file, 'wmm_ac_bk_txop_limit', '0', '0')
	write_str_config(conf_file, 'wmm_ac_vi_aifs', '2', '2')
	write_str_config(conf_file, 'wmm_ac_vi_cwmin', '3', '3')
	write_str_config(conf_file, 'wmm_ac_vi_cwmax', '4', '4')
	write_str_config(conf_file, 'wmm_ac_vi_txop_limit', '94', '94')
	write_str_config(conf_file, 'wmm_ac_vo_aifs', '2', '2')
	write_str_config(conf_file, 'wmm_ac_vo_cwmin', '2', '2')
	write_str_config(conf_file, 'wmm_ac_vo_cwmax', '3', '3')
	write_str_config(conf_file, 'wmm_ac_vo_txop_limit', '47', '47')
end
--############## VAP parameters #############
function vap_parameters(conf_file, opwrt_iface_dir, vap_name, dev_index, net_index)
	
	--############## %s VAP parameters #############
	conf_file:write(string.format("############## %s VAP parameters #############\n", vap_name))

	if(net_index > 1) then
		write_str_config(conf_file, "bss", vap_name, vap_name)
	end
	write_str_config(conf_file, "vendor_elements", 'dd050009860100', 'dd050009860100')

	local base_addr = luci.util.exec(string.format("uboot_env --get --name ethaddr"))
	-- base, device_num, vap_num, inc(wan+lan1,lan2,lan3,lan4)
	local bssid = get_mac_addr(base_addr, dev_index - 1, net_index -1, 5)
	print('bssid', bssid)
	write_str_config(conf_file, "bssid", opwrt_iface_dir['bssid'], bssid)
	--###___SSID_parameters___###
	conf_file:write(string.format("###___SSID_parameters___###\n"))
	write_str_config(conf_file, "bridge", opwrt_iface_dir['network'], 'br-lan')--opwrt_iface_dir['network']))
	write_str_config(conf_file, "ssid", opwrt_iface_dir['ssid'], 'PantekSDK-test') 
	write_str_config(conf_file, "utf8_ssid", '1', '1') 
       
end
--###___AccessPoint_parameters___###
function ap_parameters(conf_file, opwrt_device_dir, opwrt_iface_dir, op_name, vap_name)
	conf_file:write("###___AccessPoint_parameters___###\n")
	write_flag(conf_file, "ignore_broadcast_ssid", opwrt_iface_dir['hidden']) --1:hidden, 0: no hidden
	write_flag(conf_file, "ap_isolate", opwrt_iface_dir['ap_isolation']) --1:isolate, 0: no isolate
	write_str_config(conf_file, "dtim_period",opwrt_device_dir['dtim'], '2')
	write_str_config(conf_file, "ap_max_inactivity", '60', '60')
	write_str_config(conf_file, "max_num_sta", opwrt_iface_dir['maxsta'], '32')
	write_str_config(conf_file, "num_res_sta", '0', '0')
	if(opwrt_device_dir['operation_mode'] == 'anac' )then
		write_str_config(conf_file, "opmode_notif", '1', '1')
	end
	write_str_config(conf_file, "qos_map_set", '0,7,8,15,16,23,24,31,32,39,40,47,48,55,56,63', '0,7,8,15,16,23,24,31,32,39,40,47,48,55,56,63')
	write_flag(conf_file, "wmm_enabled", opwrt_iface_dir['WMMEnable'])
	write_flag(conf_file, "uapsd_advertisement_enabled", opwrt_iface_dir['uapsd_enable']) --WMM Automatic Power Save Delivery (APSD) function configuration
	write_str_config(conf_file, "proxy_arp", '1', '1')
	macaddr_acl_setting(conf_file, opwrt_iface_dir, op_name, vap_name)
	write_str_config(conf_file, "gas_comeback_delay", '0', '0')
end
--###___MBO_parameters___###
function mbo_parameters(conf_file, opwrt_device_dir)
	conf_file:write("###___MBO_parameters___###\n")
	write_str_config(conf_file, "mbo", '1', '1')
	write_str_config(conf_file, "mbo_cell_aware", '1', '1')
	write_str_config(conf_file, "rrm_neighbor_report", '1', '1')
	write_str_config(conf_file, "bss_transition", '1', '1')
	write_str_config(conf_file, "mbo_pmf_bypass", '1', '1')
	write_str_config(conf_file, "interworking", '1', '1')
	write_str_config(conf_file, "access_network_type", '0', '0')
end
--###___11k_parameters___###
function rrm_parameters(conf_file, opwrt_device_dir)
	conf_file:write("###___11k_parameters___###\n")
	write_str_config(conf_file, "rrm_link_measurement", '1', '1')
	write_str_config(conf_file, "rrm_sta_statistics", '1', '1')
	write_str_config(conf_file, "rrm_channel_load", '1', '1')
	write_str_config(conf_file, "rrm_noise_histogram", '1', '1')
	write_str_config(conf_file, "rrm_beacon_report_passive", '1', '1')
	write_str_config(conf_file, "rrm_beacon_report_table", '1', '1')
end

local function prase_wireless_uci(section)
	config = xuci:get_all('wireless', section)
	return config
end

local function disable_iface(dev)

	local device_name = dev:name()
	--disable old hostapd configuration
	run_command(string.format('killall hostapd_%s', device_name))
	--down device 
	run_command(string.format('ifconfig %s down', device_name))
	-- 0. remove from ppa table
	for index, net in ipairs(dev:get_wifinets()) do
		local vap_name = get_vap_name(device_name, index)
		--remove from ppa
		run_command(string.format("/usr/bin/ppacmd dellan -i %s", vap_name))
	end
end
--
--Param:
--		dev:device info
--
function wifi_reload(dev, dev_index) 
	local ret

	local device_name = dev:name()
	--disable current wifi iface
	disable_iface(dev)

	local opwrt_device_dir = prase_wireless_uci(device_name)

	--check wifi device switch
	if(opwrt_device_dir['disabled'] == '1') then
		print(opwrt_device_dir['disabled'])
		return 0 -- wifi switch disable 
	end

	local hostapd_conf = string.format('%s/hostapd_%s.conf', wave_tmpdir, device_name) 
	--create hostapd configuration file
	local conf_file = io.open(hostapd_conf, 'w+')

	--update config detail to hostapd_wlanX.conf
	physical_radio_setting(conf_file, device_name, opwrt_device_dir)
	wmm_setting(conf_file, opwrt_device_dir)
	radio_setting(conf_file, device_name, opwrt_device_dir)
	for net_index, net in ipairs(dev:get_wifinets()) do
		local op_name = net:name()
		local vap_name = get_vap_name(device_name, net_index)
		local opwrt_iface_dir = prase_wireless_uci(op_name)

		while true do  --replace continue
			print (opwrt_iface_dir)
			--check vap switch
--			if(opwrt_iface_dir['disabled'] == '1') then
			if(get_safe_value('disabled', opwrt_iface_dir['disabled'], '0') == '1') then
				print(string.format("iface:%s disabled\n", op_name))
				break -- wifi switch disable 
			end
			--begin muilt ssid setting 
			vap_parameters(conf_file, opwrt_iface_dir, vap_name, dev_index, net_index)
			ap_parameters(conf_file, opwrt_device_dir, opwrt_iface_dir, op_name, vap_name)
			mbo_parameters(conf_file, opwrt_device_dir)
			rrm_parameters(conf_file, opwrt_device_dir)
			security_setting(conf_file, opwrt_iface_dir)
			wps_setting(conf_file, opwrt_iface_dir)
			break
		end
	end
	--end multi ssid setting
	conf_file:close()
	-- 0. Create runner_up_wlanX.sh
	up_script_name=string.format("%s/runner_up_%s.sh", wave_tmpdir, device_name)
	up_script=wave_FileStream:new(nil, up_script_name)
	cls_iwpriv=pantek_iwpriv:new(nil, up_script)

	-- 1. setting iwpriv configuration before hostapd
	cls_iwpriv:iwpriv_pre_hostapd(device_name, opwrt_device_dir)

	-- 2. start hostapd
--	up_script:write_command_script('\n### Start hostapd ###')
	up_script:write_command_script(string.format("/tmp/hostapd_%s -B %s", device_name, hostapd_conf))
--	os.execute(cmd)
	--cls_iwpriv:Start_hostapd(device_name, hostapd_conf)

	-- 3. setting iwpriv configuration after hostapd
	cls_iwpriv:iwpriv_after_hostapd(device_name, opwrt_device_dir)
	-- 4. setting vap iwpriv configuration after hostapd
	--os.execute('sleep 2')
	up_script:write_command_script('sleep 2')
    --[[
	for net_index, net in ipairs(dev:get_wifinets()) do
		local vap_name = get_vap_name(device_name, net_index)
		local opwrt_iface_dir = prase_wireless_uci(net:name())
		cls_iwpriv:vap_command_after_hostapd(opwrt_iface_dir, net:name(), vap_name)
	end
    ]]--
	up_script:close()
	up_script:execute_script()

end

