#!/usr/bin/lua
package.path='/opt/lantiq/wave/scripts/?.lua'
dofile ('/opt/lantiq/wave/scripts/wave_adaption.lua')
local wave_adaption = require("wave_adaption")
local nw = require("luci.model.network")

nw.init()

local function wave_hw_init()

	local cmd = string.format("mkdir -p /tmp/wlan_wave")
	os.execute(cmd)

	for _,v in pairs(wave_pre_module_list) do
		local cmd = string.format("insmod /lib/modules/3.10.104/%s", v)
		os.execute(cmd)
		print (cmd)
	end
	cmd = string.format("/bin/sh %s/%s ", wave_script_dir, 'runner_hw_init.sh');
	os.execute(cmd)
end
function restart()   

	if (false == file_exists(opwrt_wifi_tmp_wireless)) then
		print('there is nothing wifi configuration update\n')
		return -1
	end

	local file = io.open(opwrt_wifi_tmp_wireless, 'r')
	local dev_name = file:read()

	--reload wifi iface depend the setting of /tmp/wireless
	while(dev_name ~= nil) do


		for index, dev in ipairs(nw.get_wifidevs()) do
			if (dev_name == dev:name()) then
				wifi_reload(dev, index)
				break
			end
		end

		dev_name = file:read()
	end

	file:close()
	return 1; 
end

function reconfig(devname)   

	if(devname ~= nil) then
		for index, dev in ipairs(nw.get_wifidevs()) do
			if (devname == dev:name()) then
				print("config hostapd for "..devname)
                hostapd_reconfig(dev, index)
				break
			end
		end

	end

	return 1; 
end

function init()   

	if (false == file_exists(opwrt_wifi_file)) then
		local cmd = string.format("cp %s %s", opwrt_wifi_default_file, opwrt_wifi_file);
		os.execute(cmd)
	end
	wave_hw_init()
	for index, dev in ipairs(nw.get_wifidevs()) do
		os.execute(string.format("cp -s /opt/intel/bin/hostapd /tmp/hostapd_%s", dev:name()))
		os.execute(string.format("cp -s /opt/intel/bin/hostapd_cli /tmp/hostapd_cli_%s", dev:name()))

		--os.execute('sleep 2')
		--wifi_reload(dev, index)
	end
	return 1; 
end

function main(action,devname)
	
	--check param
	if(action == nil) then
		print("Usage: pantek_wifi <start|restart|stop|init|uninit>")
	end

	--select action
	if(action == 'start') then
		print(action)
	elseif (action == 'restart') then
		restart()
	elseif (action == 'reconfig') then
		reconfig(devname)
    elseif (action == 'stop') then
		print(action)
	elseif (action == 'init') then
		init()
	elseif (action == 'uninit') then
		print(action)
	else
		print("Usage: pantek_wifi <start|restart|stop|init|uninit>")
	end
end


main(arg[1],arg[2])
