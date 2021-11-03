_G = GLOBAL
require = _G.require
local FoodMemory = require "widgets/foodmemory"
local food,foodentity
--local is_stackchange = false
local frame_error = _G.FRAMES*1
local old_stacksize = 0
local d_stacksize = 0
local cd_time = 0
local GetTime = _G.GetTime
local queue = {}
local json = _G.json
local warly_only = GetModConfigData("warly_only")
local reset_on_change_character = GetModConfigData("reset_on_change_character")

local M_cd = 0.5-2*frame_error
local N_cd = 0.5-3*frame_error
local function nildeclaredvars()
	foodentity = nil
	food = nil
	old_stacksize = 0
	d_stacksize = 0
end


local function ClearFoodMemory(src)
	--That means we don't have to use ThePlayer to sync data up.
    if not src then print("Error: No Seed") return nil end
    local seed = src.net.components.shardstate:GetMasterSessionId() --We're gonna use the same seed, because Warly's food memory is the same both in surface and caves and you don't avoid it by switching shards.
    if seed then
        local id = _G.KnownModIndex:GetModActualName("Warly Memory")
        local data = {}
        _G.TheSim:GetPersistentString(id,function(success,_data) if success then data = json.decode(_data) end end,false)
        if type(data) ~= "table" then data = {} end
        data[tostring(seed)] = {}
        local encoded_var = json.encode(data)
        _G.SavePersistentString(id,encoded_var,ENCODE_SAVES)
    else
        print("Error: World Exists, but seed is a nil value")
    end
end

AddPlayerPostInit(function(inst) 
	inst:DoTaskInTime(0.5,function()
			if reset_on_change_character then
				_G.TheWorld:RemoveEventCallback("entercharacterselect",ClearFoodMemory)
				_G.TheWorld:ListenForEvent("entercharacterselect",ClearFoodMemory)
			end
			if inst == _G.ThePlayer and not (inst.prefab ~= "warly" and warly_only) then
				_G.ThePlayer.HUD.controls.top_root:AddChild(FoodMemory(inst))
				if _G.TheWorld.ismastersim then
					_G.ThePlayer:ListenForEvent("oneat",function(src,data) if data.food:HasTag("preparedfood") then _G.ThePlayer:PushEvent("MOD_WarlyMemory_successful_eat",data.food.prefab) end end)
				end
				--_G.ThePlayer:ListenForEvent("MOD_WarlyMemory_successful_eat",function(src,data) print(data,"Successful eat trigger") end)
			end
		end)
end)

local on_succesful_eat = function(f)
	if GetTime() - N_cd >= cd_time then
		_G.ThePlayer:PushEvent("MOD_WarlyMemory_successful_eat",f or food)
		--print("Event food trigger\n--------------")
		cd_time = GetTime()
	else
		--print("CD Time not up")
	end
end

local onremovefn = function(self)--The "onremove" event triggers when a food turns to rot or gets eaten with a stacksize of 1.
	if self:HasTag("INLIMBO") then--Is it in our inventory?
		on_succesful_eat(self.prefab)
	end
end

--[[local function onstackchange()
	is_stackchange = true
	_G.ThePlayer:DoTaskInTime(frame_error*2,function() is_stackchange = false end)
end--]]

local function stacksizechange(inst)
	if not foodentity then on_succesful_eat() return true end
	local d_stack = foodentity and foodentity.replica.stackable and ((d_stacksize-foodentity.replica.stackable:StackSize()) >= 1 or (d_stacksize-foodentity.replica.stackable:StackSize()) >= 1)
	--print("Stack size change trigger 2")
	--print(old_stacksize,foodentity and foodentity.replica.stackable and foodentity.replica.stackable:StackSize(),d_stacksize)
	if not foodentity then
		on_succesful_eat()
	elseif foodentity and (d_stack or (not foodentity.replica.stackable)) then
		on_succesful_eat()
	end
	--nildeclaredvars()
end

local function checkfor_stacksizechange(inst)--The problem of "Quick foods may not get registered" is cause by the fact that RPC triggers instantly, unlike the functions that check the food, which means that the food we're checking may get swapped for another one, which just gives us a false value.
	local is_eating = (_G.ThePlayer.AnimState:IsCurrentAnimation("eat") or _G.ThePlayer.AnimState:IsCurrentAnimation("quick_eat") or _G.ThePlayer.AnimState:IsCurrentAnimation("quick_eat_pre"))
	local d_stack = (foodentity and foodentity.replica.stackable and (((old_stacksize-foodentity.replica.stackable:StackSize()) == 1) or (d_stacksize-foodentity.replica.stackable:StackSize() == 1))) or not foodentity
	--for k,v in pairs(_G.ThePlayer.replica.inventory:GetItems()) do if v == foodentity then print("Slot",k) end end
	--print(foodentity,is_eating,d_stack, old_stacksize,foodentity and foodentity.replica.stackable and foodentity.replica.stackable:StackSize())
	if not foodentity and is_eating then
		on_succesful_eat()
		return true
	elseif foodentity and (d_stack or (not foodentity.replica.stackable)) and is_eating then
		on_succesful_eat()
		return true--To prevent double trigger
	elseif d_stack then
		on_succesful_eat()
		return true
	end
	if (not d_stack) or not is_eating then
		_G.ThePlayer:DoTaskInTime(frame_error*3,stacksizechange)
	end
	
end

--Player starts eating, ListenForEvent stacksizechange, after 0.5/1 s check if stacksize has changed, remove event listener; If item disappeared and player is in eating animation then assume it was eaten.
local eat_time = 1.0000000521541+2*frame_error--Slightest offset because stacksize may not have time to update
local quick_eat_time = 0.50000002607703+frame_error
local onremoveevent_duration = 1.2
--"onremove" event does trigger for the single items when they're eaten, try that perhaps? Be careful of stacking and item rotting though.
local function OnStartEating(rpc,act,...)
	

	if rpc == _G.RPC.LeftClick then
		local food_ent = _G.ThePlayer.replica.inventory:GetActiveItem()
		if not food_ent then on_succesful_eat() return end
		if food_ent:HasTag("preparedfood") then
			foodentity = food_ent
			food = food_ent.prefab
			old_stacksize = food_ent.replica.stackable and food_ent.replica.stackable:StackSize() or 0
			if not food_ent.islisteningforremove then
				food_ent:ListenForEvent("onremove",onremovefn)
				food_ent._islisteningforremove = true
				food_ent:DoTaskInTime(onremoveevent_duration,function() food_ent:RemoveEventCallback("onremove",onremovefn) food_ent.islisteningforremove = nil end)
			end
			_G.ThePlayer:DoTaskInTime(frame_error*3,function() d_stacksize = old_stacksize end)
			if food_ent:HasTag("edible_MEAT") then
				_G.ThePlayer:DoTaskInTime(eat_time,checkfor_stacksizechange)
			else
				_G.ThePlayer:DoTaskInTime(quick_eat_time,checkfor_stacksizechange)
			end
		end
	elseif rpc == _G.RPC.UseItemFromInvTile then
		local food_ent,placeholder = ...
		food_ent = type(food_ent) ~= "number" and food_ent or placeholder
		if food_ent:HasTag("preparedfood") then
			foodentity = food_ent
			food = food_ent.prefab
			if not food_ent.islisteningforremove then
				food_ent:ListenForEvent("onremove",onremovefn)
				food_ent._islisteningforremove = true
				food_ent:DoTaskInTime(onremoveevent_duration,function() food_ent:RemoveEventCallback("onremove",onremovefn) food_ent.islisteningforremove = nil end)
			end
			old_stacksize = food_ent.replica.stackable and food_ent.replica.stackable:StackSize() or 0
			_G.ThePlayer:DoTaskInTime(frame_error*3,function() d_stacksize = old_stacksize end)
			--OnDoneEating() --Listen for event "timerdone"
			if food_ent:HasTag("edible_MEAT") then
				_G.ThePlayer:DoTaskInTime(eat_time,checkfor_stacksizechange)
			else
				_G.ThePlayer:DoTaskInTime(quick_eat_time,checkfor_stacksizechange)
			end
			else

		end
	end
end


function _G.c_addtofoodmemory(foodname)--Don't forget to tell the user this has to be executed locally.
	_G.ThePlayer:PushEvent("MOD_WarlyMemory_successful_eat",foodname)
end

function _G.c_sortfoodmemorybyfn(fn)
	_G.ThePlayer:PushEvent("MOD_WarlyMemory_sort",fn)
end

--Stat related stuff--
local function GetFoodStatData()
	local id = _G.KnownModIndex:GetModActualName("Warly Memory")
    local str = id.." stats"
	local persistdata = {}
	_G.TheSim:GetPersistentString(str,function(success,data)
            if success then
                persistdata = _G.json.decode(data)
            end
        end,false)
	return persistdata
end

local function SaveFoodStatData(data)
	local id = _G.KnownModIndex:GetModActualName("Warly Memory")
    local str = id.." stats"
	_G.SavePersistentString(str,_G.json.encode(data),true)
end

function _G.c_getfoodstats()--Sort by count; Show percentage.
	local food_stats = GetFoodStatData()
	local total_count = 0
	for food,count in pairs(food_stats) do
		total_count = total_count + count
	end
	total_count = total_count ~= 0 and total_count or 1
	
	local sorted_table = {}
	for k,v in pairs(food_stats) do 
		table.insert(sorted_table,#sorted_table+1,k)
	end
	table.sort(sorted_table,function(a,b) return food_stats[a]>food_stats[b] end)
	
	for k,food in pairs(sorted_table) do 
		local num = _G.tostring(_G.tonumber(string.format("%.4f",food_stats[food]*100/total_count)))
		print(string.format("%s: %d (%s%%)",food,food_stats[food],num))
	end
end

function _G.c_setfoodnumberstat(food,num)
	local food_stats = GetFoodStatData()
	if not (type(food_stats) == "table") then
		food_stats = {}
	end
	
	if food and num then
		local food_name = _G.STRINGS.NAMES[string.upper(food)]
		if not food_name then
			print("Error: Food can't be found in strings. Please input the food prefab and not its name")
		else
			food_stats[food_name] = num
			print("Set "..food.." to "..num)
			SaveFoodStatData(food_stats)
		end
	else
		print("Error: Lacking an input for food prefab or num")
	end
end

function _G.c_resetfoodstats(t)
	if t == true then
		SaveFoodStatData({})
		print("Food stat data has been reset.")
	else
		print("Note: All food stats will be wiped. This cannot be undone. Type c_resetfoodstats(true) to confirm the data reset.")
	end
end
--\\End of Stat related stuff//--

local _SendRPCToServer = _G.SendRPCToServer
function _G.SendRPCToServer(rpc,act,...)
	if act == _G.ACTIONS.EAT.code then
		OnStartEating(rpc,act,...)
	end
	_SendRPCToServer(rpc,act,...)
end

local function ConsoleScreenPostInit(self)
	if self.console_edit.prediction_widget then
		local dictionaries = self.console_edit.prediction_widget.word_predictor and self.console_edit.prediction_widget.word_predictor.dictionaries or {}
		for _,list in pairs(dictionaries) do
			if list.delim == "c_" then
				table.insert(list.words,"addtofoodmemory")
				table.insert(list.words,"sortfoodmemorybyfn")
				table.insert(list.words,"getfoodstats")
				table.insert(list.words,"setfoodnumberstat")
				table.insert(list.words,"resetfoodstats")
			end
		end
	end
end

AddClassPostConstruct("screens/consolescreen", ConsoleScreenPostInit)


local old_DoRestart = _G.DoRestart
function _G.DoRestart(val)
	if val == true and _G.TheWorld then
		_G.TheWorld:PushEvent("MOD_FoodMemory_player_restarting")
	end
	old_DoRestart(val)
end
local old_MigrateToServer = _G.MigrateToServer
function _G.MigrateToServer(ip,port,...)
	if ip and port and _G.TheWorld then
		_G.TheWorld:PushEvent("MOD_FoodMemory_player_restarting")
	end
	old_MigrateToServer(ip,port,...)
end
