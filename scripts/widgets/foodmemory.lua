local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local UIAnim = require "widgets/uianim"
local UIAnimButton = require "widgets/uianimbutton"
local cooking = require ("cooking")
local spicedfoods = require ("spicedfoods")
local scrn_x, scrn_z,h_x,h_z
local update_time = 0
local temp_foodtiles = {}
local temp_foodtile_identifiers = {}
local temp_spice_identifiers = {}
local temp_timers = {}
local temp_spice_timers = {}
local temp_buff_timers = {}
local save_name

local food_name_text_size, timer_text_size, num_eaten_text_size, stat_text_size,bufftimer_text_size,spice_timer_text_size
food_name_text_size = 28
timer_text_size = 36
num_eaten_text_size = 36
stat_text_size = 28
bufftimer_text_size = 24
spice_timer_text_size = 24


local food_name_pos, timer_text_pos, num_eaten_text_pos, stats_pos, stat_num_pos, food_img_pos, bufftimer_text_pos,spice_timer_text_pos
food_name_pos = {x = 0, y = 30}
timer_text_pos = {x = 4, y = 20}
num_eaten_text_pos = {x = 4, y = -20}
stat_num_pos = {x = 2, y = -25}
food_img_pos = {x = -4, y = 5}
bufftimer_text_pos = {x = 4, y = 0}
spice_timer_text_pos = {x = 0, y = 16}


local timer_text_colour,bufftimer_text_colour,spice_timer_text_colour
timer_text_colour = {1,1,0,1}
bufftimer_text_colour = {0,1,0,1}
spice_timer_text_colour = {1,1,0,1}

local stats_size,obj_size,spicebuff_size
obj_size = {x = 64, y = 64}
stats_size = {x = 32, y = 32}
spicebuff_size = {x = 40, y = 40}


local food_img_scale
food_img_scale = {0.65,0.65,0.65}

local preset_spicebuff_positionscales
preset_spicebuff_positionscales = {
    {x = -6/16, y = 0},
    {x = -4/16, y = 0},
    {x = 4/16, y = 0},
    {x = 6/16, y = 0},
    }

local ontogglemenu_press_fn = function() end

--TODO: Make food timers respect rollbacks.

local function LoadConfig(name)
    local mod = "Warly Memory"
    return GetModConfigData(name,mod) or GetModConfigData(name,KnownModIndex:GetModActualName(mod))
end

local time_format_type = LoadConfig("time_format")
local do_sort = LoadConfig("do_sort")
local sort_type = LoadConfig("sort_type")
local items_row = LoadConfig("itemsperrow") or 6
local toggle_menu_key = LoadConfig("toggle_menu")
local added_sound = LoadConfig("unique_add")
local removed_sound = LoadConfig("unique_remove")
local infinitetime = LoadConfig("infinitetime")
local foodtime = LoadConfig("foodtime")

if foodtime == "Default" then
    foodtime = TUNING.WARLY_SAME_OLD_COOLDOWN
end



local function GetFoodsAndTimers(self)
    if true then
        local foods = {}
        foods.spices = {}
        foods.buffs = {}
        for name,identifier in pairs((self and self.foodtile_identifiers) or temp_foodtile_identifiers) do 
			local data = (self and self.foodtiles and self.foodtiles[identifier]) or temp_foodtiles[identifier]
			local food_name = data.name
			local food_time = (self and self.GetTimerForFood and self:GetTimerForFood(food_name)) or temp_timers[food_name]
			local food_num = data.widget.food.num_eaten_value or 1
            if food_time > 0 then
                foods[food_name] = {
                    food_name = food_name,
                    food_time = food_time,
                    food_num = food_num,
                }
            end
        end
        for name,identifier in pairs((self and self.spices) or temp_spice_identifiers) do
            if identifier.name and identifier.name ~= "undefined" then
                local name = string.match(identifier.name,"spice_(%w+).tex")
                local time = (self and self.GetTimerForBuff and self:GetTimerForBuff(name)) or temp_spice_timers[name]
                if time > 0 then
                    foods.spices[name] = time
                end
            end
        end
        for name,time in pairs((self and self.buff_timers) or temp_buff_timers) do
            if time > 0 then
                foods.buffs[name] = time
                print(name,time)
            end
        end
        return foods
    else
        return nil
    end
end

local function ConvertPersistentDataFromSeedToSessionId(data,persistdata,session_id)
    if not data then return persistdata end
    local world_seed = TheWorld.meta.seed
    print("Converted old method data to session id for world seed",world_seed)
    persistdata[tostring(world_seed)] = nil
    persistdata[tostring(session_id)] = data
    return persistdata
end

local function SavePersistentData(self)-- Great thing about the class this time is that it has all its data in one place and isn't spread around a few entities.
    --That means we don't have to use ThePlayer to sync data up.
    if not TheWorld then print("Error: No Seed") return nil end
    local seed = save_name
    local world_seed = TheWorld.meta.seed
    -- Seeds may sometimes differ from other effects, but the mastersessionid should stay the same whichever shard you're in at the same server.
    if seed then
        local foods = GetFoodsAndTimers(self)
        --local id = KnownModIndex:GetModActualName("Warly Memory").."-"..seed--I mean it's not a bad way of saving data, but it's really spammy in client_save if you played in lots of worlds with different seeds such as public servers.
        local id = KnownModIndex:GetModActualName("Warly Memory")
        local data = {}
        TheSim:GetPersistentString(id,function(success,_data) if success then data = json.decode(_data) end end,false)
        if type(data) ~= "table" then data = {} end
        
        local old_method_data = data[tostring(world_seed)]
        data = ConvertPersistentDataFromSeedToSessionId(old_method_data,data,seed)
        data[tostring(seed)] = foods
		--print("Bout to save")
		--for k,v in pairs(data[tostring(seed)]) do for i,d in pairs(v) do print(i,d) end end
        local encoded_var = json.encode(data)
		--print("Encoded")
        SavePersistentString(id,encoded_var,ENCODE_SAVES)--We shouldn't worry about overwriting anything else, because the previous data should already be loaded in.
		--print("Saved")
        --And any other data can be overwritten because some timers can run out and some new ones can start.
    else--What? How did we have TheWorld, but not have a seed?
        print("Error: World Exists, but seed is a nil value")
    end
    
end

local function GetPersistantData(self)
    if not TheWorld then print("Error: No Seed") return nil end
    local persistdata = {}
    local seed = save_name
    
    --local id = KnownModIndex:GetModActualName("Warly Memory").."-"..seed
    local id = KnownModIndex:GetModActualName("Warly Memory")
    if seed then
        TheSim:GetPersistentString(id,function(success,data) --TheSim should exist in all cases?
            if success and type(data) == "string" and string.len(string.gsub(data," ","")) > 1 then
                persistdata = json.decode(data)
            end 
        end,false)
		--print("Got back persistent data",type(persistdata),type(persistdata[tostring(seed)]))
		--for k,v in pairs(persistdata[tostring(seed)] or {}) do for i,d in pairs(v) do print(i,d) end end--Persistant Data table isn't generated for all seeds,yet.
        return type(persistdata) == "table" and persistdata[tostring(seed)]
    else
        print("Error loading: World Exists, but seed is a nil value")
        return nil
    end
end

local function AddFoodNumToStats(food)
	local id = KnownModIndex:GetModActualName("Warly Memory")
    local str = id.." stats"
    local persistdata = {}
    food = _G.STRINGS.NAMES[string.upper(food)]
    TheSim:GetPersistentString(str,function(success,data)
            if success then
                persistdata = json.decode(data)
            end
        end,false)
    --for k,v in pairs(persistdata) do print(k,v) end
    --print("^----^")
    if persistdata[food] then
        persistdata[food] = persistdata[food] + 1
    else
        persistdata[food] = 1
    end
    --print("v----v")
    --for k,v in pairs(persistdata) do print(k,v) end
    local encoded_data = json.encode(persistdata)    
    SavePersistentString(str,encoded_data,ENCODE_SAVES)
end

local function ConvertNumberToRowColumnPositions(num)
	local row = math.ceil(num/items_row)
	local column = num-(row-1)*items_row
	if row == 0 then column = 0 end
	return row,column
end

local function ConvertRowColumnToNumberPosition(row,column)
	local num = (row-1)*items_row+column
	return num
end



local FoodMemory = Class(Widget,function(self,owner)
        Widget._ctor(self,"FoodMemory")
		
        scrn_x,scrn_z = TheSim:GetScreenSize()
        h_x = scrn_x/2
        h_z = scrn_z/2
        if TheWorld.net then
            save_name = TheWorld.net.components.shardstate:GetMasterSessionId()
            -- Our UI gets added once the player HUD exists. The cave shard SHOULD exist by then.
        end
        
        self.owner = owner
        if not owner.components.timer then
            owner:AddComponent("timer")
        end
		
        self.memoryshown = false
		
        self.rows = 0
        self.rowitems = 0 --Keep track of the last modified row.
		self.foodtiles = {}-- {widget = widget, row = row, column = column, name = name}
		--Adding food tiles to the self.foodtiles table should be handled by the AddFoodTimer function.
		--Removing food tiles from the self.foodtiles table should be handled by the RemoveFoodTimer function
		--No other function should have privilege to add/remove anything from that table.
        
		self.foodtile_identifiers = {}--[name] = num
		--For an easy way to identify the number to the tile.
		--This table will need to be updated everytime a new foodtile is added and removed.
        
		self.food_timers = {} -- Possible issue with timers is that it turns into an empty table an it doesn't have time to grab all the timers again as the player disconnects from the current shard. This should fix that issue.
        
        self.spices = {} -- For keeping track of spice buff widgets
        --Format:  {widget = widget, slot = slot, name = name}
        --Display up to 4 spice buffs, because I have no idea where spice timers would fit or look good in the current UI.
        
        self.spice_timers = {}
        
        self.buff_timers = {}
		
        self.size_x = 1/10*h_x+56*items_row
        self.size_z = 1/10*h_z+56*self.rows
        --Each 10 items should use up a total space of around 40x40 space.
        --Or 64x64
        
        
        self.togglebutton = self:AddChild(ImageButton("images/frontend.xml", "button_square_halfshadow.tex"))
        self.ontogglebuttonfn = function() self:ToggleMemoryDisplay() end
        ontogglemenu_press_fn = self.ontogglebuttonfn
        self.togglebutton:SetOnClick(self.ontogglebuttonfn)
        self.togglebutton:SetNormalScale(1,0.5,1)
        self.togglebutton:SetFocusScale(1,0.5,1)
        self.togglebutton:SetImageNormalColour(0.7,0.7,0.7,0.7)
        self.togglebutton:SetImageFocusColour(1,1,1,1)
        
        self.togglebutton_icon = self.togglebutton:AddChild(Image("images/inventoryimages1.xml","meatballs.tex"))
        self.togglebutton_icon:SetPosition(-7,1)
        self.togglebutton_icon:SetScale(.5,.5,.5)
        
        self.togglebutton_icon_alt = self.togglebutton:AddChild(Image("images/inventoryimages1.xml","deerclops_eyeball.tex"))
        self.togglebutton_icon_alt:SetPosition(-7,1)
        self.togglebutton_icon_alt:SetScale(.5,.5,.5)
        self.togglebutton_icon_alt:Hide()
        
        self.memorydisplay_bg = self:AddChild(Image("images/global.xml", "square.tex","square.tex","square.tex"))
        self.memorydisplay_bg:SetTint(0,0,0,.8)
        self.memorydisplay_bg:MoveToBack()
        self.memorydisplay_bg:Hide()
        self.memorydisplay_bg:SetSize(self.size_x,self.size_z)
        self.memorydisplay_bg:SetPosition(-7,0.01*scrn_z-(1/20*h_z*self.rows))
        self.memorydisplay_bg:SetClickable(true) -- Background kinda blocks a lot of stuff if you can click it for no reason.
        --But clickable background appears to be required for its children to be clickable.
        
        
        for k,pos in pairs(preset_spicebuff_positionscales) do
           local box = self.memorydisplay_bg:AddChild(Image("images/hud.xml","inv_slot.tex"))
--         box:SetPosition(self.size_x*pos.x,self.size_z*pos.y+1.5*spicebuff_size.y)
           box:SetSize(spicebuff_size.x,spicebuff_size.y)
           box:Show()
           box.item = box:AddChild(Image("images/quagmire_recipebook.xml","coin_unknown.tex"))
           box.item:SetScale(.75)
           box.item:Hide()
           box.timer = box.item:AddChild(Text(NUMBERFONT,spice_timer_text_size))
           box.timer:SetColour(unpack(spice_timer_text_colour))
           box.timer:SetPosition(spice_timer_text_pos.x,spice_timer_text_pos.y)
           table.insert(self.spices,k,{widget = box, slot = k, name = "undefined"})
        end

        self:SetPosition(h_x*0,-0.014*scrn_z)--From h_x,scrn_z-0.01*scrn_z because we now add a child to the top root for the widget to get hidden with the rest of the screen widgets.
        self:Show()
        self.oneatfoodfn = function(src,data) self:AddFoodTimer(data) end
        owner:ListenForEvent("MOD_WarlyMemory_successful_eat",self.oneatfoodfn)
        self.ontimerdonefn = function(src,data) if string.sub(data.name,-7,-1) == "_memory" then self:RemoveFoodTimer(string.sub(data.name,1,-8)) end end--Probably our timer.
        owner:ListenForEvent("timerdone",self.ontimerdonefn)
        self.onsortfn = function(src,fn) self:SortFoodTilesByFunction(fn) end
        owner:ListenForEvent("MOD_WarlyMemory_sort",self.onsortfn)
        --Persistant data loading:--
        local persistent_foods = GetPersistantData(self)
        if persistent_foods then
            for num,info in pairs(persistent_foods) do 
                if num ~= "spices" and num ~= "buffs" then
                    --print("info: ",info.food_name,info.food_time,info.food_num)
                    self:AddFoodTimer(info.food_name,info.food_time,true,info.food_num)
                end
            end
            for num,info in pairs(persistent_foods.spices or {}) do
                --print("info: ",num,info)
               self:AddSpiceTimer(num)
               self:StartTimerComponentForBuff(num,info)
            end
            for num,info in pairs(persistent_foods.buffs or {}) do
               self:StartTimerComponentForBuff(num,info)
            end
			self:SortFoodTilesByFunction()
        end
        ----------------------------
        --Persistant data saving:--
        if TheWorld then--It should exist because this widget gets added after the player has loaded in, but just in case.
            TheWorld:RemoveEventCallback("seasontick",SavePersistentData)
            TheWorld:RemoveEventCallback("playerdeactivated",SavePersistentData)
            TheWorld:RemoveEventCallback("MOD_FoodMemory_player_restarting",SavePersistentData)
            TheWorld:ListenForEvent("seasontick",SavePersistentData)
            TheWorld:ListenForEvent("playerdeactivated",SavePersistentData)
            TheWorld:ListenForEvent("MOD_FoodMemory_player_restarting",SavePersistentData)
        end
        ---------------------------
        self:StartUpdating()
    end
    )
    
function FoodMemory:ToggleMemoryDisplay() 
    if self.memoryshown then
        self.memoryshown = false
        self.memorydisplay_bg:Hide()
        self.togglebutton_icon:Show()
        self.togglebutton_icon_alt:Hide()
    else
        self.memoryshown = true
        self.memorydisplay_bg:Show()
        self.memorydisplay_bg:MoveToFront()
        self.togglebutton:MoveToFront()
        self.togglebutton_icon:Hide()
        self.togglebutton_icon_alt:Show()
    end
    
end

function FoodMemory:UpdateSize()
    self.size_x = 1/10*h_x+56*items_row
    self.size_z = 1/10*h_z+64*self.rows
    self.memorydisplay_bg:SetSize(self.size_x,self.size_z)
    self.memorydisplay_bg:SetPosition(-7,0.01*scrn_z-(64*0.5*self.rows))
end

function FoodMemory:CheckForDuplicateFood(foodname,foodtype)
    if foodname and foodname ~= "" then
		local tile = {}
       for num,info in pairs(self.foodtiles) do
          if info.name == foodname then
			  tile = self.foodtiles[num].widget
              tile.food.num_eaten_value = tile.food.num_eaten_value+1
              tile.food.num_eaten:SetString(tostring(tile.food.num_eaten_value))
			--print("Food: ",foodname,"is a duplicate")  
              return true
          end
       end
    end
    return false
end

local function GetFormatedBuff(buff,temperature_duration,foodname) -- Return a table which tells me the name and duration.
	if not buff then return nil end
	local special_buff_durations = {
	["wormlight_light_greater"] = TUNING.WORMLIGHT_DURATION * 4,
	["buff_sleepresistance"] = TUNING.SLEEPRESISTBUFF_TIME,
    ["healthregenbuff"] = TUNING.JELLYBEAN_DURATION,
    ["sweettea_buff"] = TUNING.SWEETTEA_DURATION,
	}
	local buff_time = temperature_duration or TUNING[string.upper(buff).."_DURATION"] or special_buff_durations[buff]
    if foodname then
        buff = foodname.."_buff"
    end
	return {name = buff, buff_time = buff_time}
end

local function GetFoodPropertyForFood(foodname)
    local recipes = cooking.recipes
	local data = {}
	local non_spiced_name
	for cooker,food_table in pairs(recipes) do
		if food_table[foodname] then
			data = food_table[foodname]
			break
		end
	end
    if data.hunger or data.sanity or data.health then --I don't care about foodtype anymore because food triggers are handled in modmain.lua. I only care if the food is actually a food(And it should have hunger,sanity,health then)
        local atlas = GetInventoryItemAtlas(foodname..".tex")
		local buffs = {}
		if data.prefabs then
			for k,buff_name in pairs(data.prefabs) do
				table.insert(buffs,#buffs+1,GetFormatedBuff(buff_name)) -- Time handled at the same function
			end
		end
		if data.temperature then
			table.insert(buffs,#buffs+1,GetFormatedBuff(data.temperature,data.temperatureduration,foodname))
		end
		--print(atlas,foodname..".tex",foodname,data.foodtype,data.hunger,data.sanity,data.health)
        return {atlas = atlas, tex = foodname..".tex", prefab = foodname, foodtype = data.foodtype ,stats = {hunger = data.hunger, sanity = data.sanity, health = data.health}, buffs = buffs}
    else
       return nil 
    end
end

function FoodMemory:StartTimerComponent(foodname,time)
	if not foodname then return nil end
    local Memory_CD = time or foodtime
    if not ThePlayer.components.timer then print("Error, Player has no timer component") return nil end
    local timer = ThePlayer.components.timer
    if not timer:TimerExists(foodname.."_memory") then
        timer:StartTimer(foodname.."_memory",Memory_CD)
    else
        timer:StopTimer(foodname.."_memory")
        timer:StartTimer(foodname.."_memory",Memory_CD)
    end
    if infinitetime and not (self.owner.prefab == "warly") then
        timer:PauseTimer(foodname.."_memory")
    end
end

function FoodMemory:StartTimerComponentForBuff(buff,time)
	if not buff then return nil end
	local buff_time = time or 240
    self.buff_timers[buff] = buff_time
	if not ThePlayer.components.timer then print("Error, Player has no timer component, buff will not be timed") return nil end
	local timer = ThePlayer.components.timer
	if not timer:TimerExists(buff.."_memory_buff") then
		timer:StartTimer(buff.."_memory_buff",buff_time)
	else
		timer:StopTimer(buff.."_memory_buff",buff_time)
		timer:StartTimer(buff.."_memory_buff",buff_time)
	end
end

function FoodMemory:GetTimerForFood(foodname,time_format)
    if not foodname then return "" end
    local timer = ThePlayer.components.timer
    local time_left = timer:GetTimeLeft(foodname.."_memory")
    if not time_left then 
		--print("Error, Food Timer has ended, but dish is still here: ",foodname) 
		return "" 
	end--Timer ended, tile should've been gone ages ago.
    if time_format == "s" then
        return string.format("%.0f",time_left)
    elseif time_format == "min" then
        local min = math.floor((time_left+0.5)/60)
        if min < 10 then
            min = string.format("0%s",min)
        end
        
        local s = string.format("%.0f",time_left%60) ~= "60" and string.format("%.0f",time_left%60) or "0"
        if tonumber(s) < 10 then
            s = string.format("0%s",s)
        end
        return string.format("%s:%s",min,s)
    elseif time_format == "day" then
        return string.format("%.1f",(time_left+24)/480)
    end
    return time_left -- Non-specified time_format implies I want the precise time in the number format.
    --return string.format("%.0f",time_left)
end

function FoodMemory:GetTimerForBuff(buffname,time_format)
    if not buffname then return "" end
    local timer = ThePlayer.components.timer
    local time_left = timer:GetTimeLeft(buffname.."_memory_buff")
    if not time_left then 
		--print("Error, Food Timer has ended, but dish is still here: ",foodname) 
		return "" 
	end--Timer ended, tile should've been gone ages ago.
    if time_format == "s" then
        return string.format("%.0f",time_left)
    elseif time_format == "min" then
        local min = math.floor((time_left+0.5)/60)
        if min < 10 then
            min = string.format("0%s",min)
        end
        
        local s = string.format("%.0f",time_left%60) ~= "60" and string.format("%.0f",time_left%60) or "0"
        if tonumber(s) < 10 then
            s = string.format("0%s",s)
        end
        return string.format("%s:%s",min,s)
    elseif time_format == "day" then
        return string.format("%.1f",(time_left+24)/480)
    end
    return time_left -- Non-specified time_format implies I want the precise time in the number format.
    --return string.format("%.0f",time_left)
end

function FoodMemory:AssessWidgetInfo()
	for k,data in pairs(self.foodtiles) do
		local widget = data.widget
		local row = data.row
		local column = data.column
		local name = data.name
		print("widget:",widget,"row:",row,"column:",column,"name:",name)
		if self.foodtile_identifiers[name] == k then
			print("self.foodtile_identifiers number matches self.foodtiles number: ",k)
		else
			print("BAD MATCH self.foodtile_identifiers:",self.foodtile_identifiers[name],"self.foodtiles:",k)
			return false
		end
	end
end

function FoodMemory:AddBuffsFromFoodName(name,time)
    if not name then return nil end
    
    local spiced_buffs,spice_name
    if string.match(name,"%w+_spice_%w+") then
		local spiced_dish = GetFoodPropertyForFood(name)
		spiced_buffs = spiced_dish.buffs
        spice_name = string.match(name,"%w+_spice_(%w+)")
        name = string.match(name,"(%w+)_spice_%w+")
    end
    local dish = GetFoodPropertyForFood(name)
    local non_spiced_buffs = dish.buffs
    local timed_buffs = {} --Non-spice
    local max_time = 0
    for k,buff_info in pairs(non_spiced_buffs) do
        max_time = math.max(buff_info.buff_time,max_time)
        local saved_buff_time = time and max_time and max_time-(foodtime-time) or max_time
        self:StartTimerComponentForBuff(buff_info.name,saved_buff_time)
        timed_buffs[buff_info.name] = true	
    end
    for k,buff_info in pairs(spiced_buffs or {}) do
        if not timed_buffs[buff_info.name] then -- It's a spice!
            self:StartTimerComponentForBuff(spice_name,buff_info.buff_time)
            self:AddSpiceTimer(spice_name)
            break
        end
    end
end

function FoodMemory:AddSpiceTimer(spice) -- Timer already starts from the food. Just add the tile.
    if not spice then return nil end
    local next_slot = 1
    for k,info in pairs(self.spices) do
       if string.match(info.name,spice) then
          return 
       end
    end
    for k,info in pairs(self.spices) do
        if not info.widget.active then
            next_slot = k
            break
        end
    end
    local widget_info = self.spices[next_slot]
    local spice_tex = type(spice) == "string" and "spice_"..spice..".tex"
    local atlas = GetInventoryItemAtlas(spice_tex,false)
    widget_info.name = spice_tex or "undefined"
    local widget = widget_info.widget
    widget.active = true
    local item = widget.item
    item:SetTexture(atlas,spice_tex)
    item:Show()
    widget:Show()
    
end

function FoodMemory:AddFoodTimer(foodname,time,nosound,value)
    if not((foodname and foodname ~= "") or (type(time) == "number" and time < 0)) then 
        --print("no food name or time is negative") 
        return nil 
    end
    local spiced_buffs,spice_name,spiced_dish,spiced_name
    if string.match(foodname,"%w+_spice_%w+") then
		spiced_dish = GetFoodPropertyForFood(foodname)
        spiced_name = foodname
		spiced_buffs = spiced_dish.buffs
        spice_name = string.match(foodname,"%w+_spice_(%w+)")
        foodname = string.match(foodname,"(%w+)_spice_%w+")
        --print(foodname)
    end
	
	
    local dish = GetFoodPropertyForFood(foodname)
	
    if self:CheckForDuplicateFood(foodname) then 
        self.togglebutton_icon:SetTexture(dish.atlas,dish.tex)
        self:StartTimerComponent(foodname) -- Restart, we don't need to input our time.
        self:AddBuffsFromFoodName(spiced_name or foodname,time)
        if (not nosound) and do_sort then --The function is laggy and it would be even laggier if we triggered it everytime we loaded in all the food.
            self:SortFoodTilesByFunction()
            AddFoodNumToStats(foodname)
        elseif not nosound then
            AddFoodNumToStats(foodname)
        end
        return true 
    end
    
	
    if dish and self.rowitems == items_row or self.rowitems == 0 then --We filled up a row or we don't even have a single row yet!
		--Add to a new row:
        self.rows = self.rows+1
        self.rowitems = 1--If dish exists, then we will definitely have a tile.
        self:UpdateSize()
        self:UpdateFoodTiles()
	elseif dish and self.rowitems >= 1 then
		--Add into a row already containing widgets:
		self.rowitems = self.rowitems + 1
	elseif not dish then
		print("Unable to add tile: Dish info could not be found for",foodname)
		return nil
    end
	
	
    if dish then
		self:AddBuffsFromFoodName(spiced_name or foodname,time)
        if not nosound then
            TheFocalPoint.SoundEmitter:PlaySound(added_sound)
            AddFoodNumToStats(foodname)
        end
        self.togglebutton_icon:SetTexture(dish.atlas,dish.tex)
		
		
		local obj = self.memorydisplay_bg:AddChild(Image("images/frontend.xml","button_square_halfshadow.tex"))
		table.insert(self.foodtiles,#self.foodtiles+1,{widget = obj, row = self.rows, column = self.rowitems, name = "undefined"})
		
		
		local obj_num = #self.foodtiles
		self.foodtile_identifiers[dish.prefab] = obj_num
		
        obj:Show()
        obj:SetSize(obj_size.x,obj_size.y)--If you're gonna use the inv_slot.tex from imagesu/hud.xml, then you should set the size to around 48
        --X:
        local min_vx = -16 -- Min distance it has to be from the vertical edges
        local u_x = self.size_x-2*min_vx
        local d_x = u_x/(items_row+1)
        --Z:
        local min_tz = 32 -- Min top
        local min_bz = 0 -- Min bot
        local u_z = self.size_z-min_tz-min_bz
        local d_z = u_z/(self.rows+1)
        obj:SetPosition((-0.5)*u_x+d_x*self.rowitems,(0.5)*u_z-min_tz-d_z*self.rows)
        
		
        ------Adding the food icon and all of the other things the tile needs------
        obj.food = obj:AddChild(Image(dish.atlas,dish.tex))
		
		
        local food = obj.food
        food.text = food:AddChild(Text(BODYTEXTFONT,food_name_text_size))
		
		
		local dish_realname = STRINGS.NAMES[string.upper(dish.prefab)]
        food.text:SetString(dish_realname)
        self.foodtiles[obj_num].name = dish.prefab
		
        self:StartTimerComponent(dish.prefab,time)
		
        food.text:SetPosition(food_name_pos.x,food_name_pos.y)
        food.text:MoveToFront()
        food.text:Hide()
		
		
        food.timer = food:AddChild(Text(NUMBERFONT,timer_text_size))
        food.timer:SetString("No timer")
        food.timer:SetPosition(timer_text_pos.x,timer_text_pos.y)
        food.timer:SetColour(unpack(timer_text_colour))
        food.timer:Show()
		
		food.bufftimer = food:AddChild(Text(NUMBERFONT,bufftimer_text_size))
		food.bufftimer:SetString("")
		food.bufftimer:SetPosition(bufftimer_text_pos.x,bufftimer_text_pos.y)
		food.bufftimer:SetColour(unpack(bufftimer_text_colour))
		food.bufftimer:Show()
		
		
        food.num_eaten = food:AddChild(Text(NUMBERFONT,num_eaten_text_size))--The text widget
        food.num_eaten_value = value or 1--Not sure if you can grab a string from a widget, so this variable tracks the number.
		
		
		local num_eaten_str = tostring(food.num_eaten_value ~= 0 and food.num_eaten_value or "")
        food.num_eaten:SetString(num_eaten_str)
        food.num_eaten:SetPosition(num_eaten_text_pos.x,num_eaten_text_pos.y)
        food.num_eaten:Show()
		
        
        local statsize_x = stats_size.x
		local statsize_y = stats_size.y
        local stats = {"hunger","sanity","health"}
        for k,statname in ipairs(stats) do 
            local tex = dish.stats[statname] and dish.stats[statname] >= 0 and "status_"..statname..".tex" or (dish.stats[statname] and "status_"..statname.."_bad.tex") or "coin_unknown.tex"
            local atlas = tex ~= "coin_unknown.tex" and "images/global_redux.xml" or "images/quagmire_recipebook.xml"
            food[statname] = food.text:AddChild(Image(atlas,tex))
            local stat = food[statname]
            stat:SetSize(statsize_x,statsize_y)
            stat:SetPosition(-38+38*(k-1),-30)--I do not think the position needs to be defined as a variable.
            stat:Show()
            food[statname].text = food[statname]:AddChild(Text(NUMBERFONT,stat_text_size))
			
			
            local statvar = food[statname].text
			local statvar_str = tostring(dish.stats[statname])
            statvar:SetString(statvar_str)
            statvar:SetPosition(stat_num_pos.x,stat_num_pos.y)
        end
		
		
        local on_gainfocus_fn = function() food.text:Show() food.num_eaten:Hide() food.timer:Hide() food.bufftimer:Hide() obj:MoveToFront() end
        local on_losefocus_fn = function() food.text:Hide() food.num_eaten:Show() food.timer:Show() food.bufftimer:Show() end
		
		
        food.OnMouseButton = function(_, button, down) 
            if button == MOUSEBUTTON_LEFT and down then 
                local num_eaten = food.num_eaten_value or 0
                local time = tonumber(self:GetTimerForFood(dish.prefab,"s"))
                local min = math.floor((time+0.5)/60)
                local s = string.format("%.0f",time%60) ~= "60" and tonumber(string.format("%.0f",time%60)) or 0
                --TheNet:Say(STRINGS.LMB.." I have eaten "..num_eaten.." "..STRINGS.NAMES[string.upper(dish.prefab)].." and my food memory will be over in "..((min>1 and min.." minutes") or (min>=1 and min.." minute") or (s.." seconds."))..((s>0 and min>0 and " and "..s.." seconds.") or ((min == 0 or s==0) and ".") or "")) 
                --Any fun things we could do/show when the food gets clicked?
                --To be added...
            end 
        end
		
		
        food:SetOnGainFocus(on_gainfocus_fn)
        food:SetOnLoseFocus(on_losefocus_fn)
		
		
        food:SetScale(food_img_scale[1],food_img_scale[2],food_img_scale[3])
        food:SetPosition(food_img_pos.x,food_img_pos.y)-- Sadly, the center of our tile isn't (0,0)
        ------///////////////////////////////////////////////////////////////------
    end
	
	
    self:UpdateFoodTiles()
    self:UpdateSize()
	
	
    if (not nosound) and do_sort then --The function is laggy and it would be even laggier if we triggered it everytime we loaded in all the food.
        self:SortFoodTilesByFunction()
    end
	
	
end

function FoodMemory:RemoveFoodTimer(foodname)
    if not foodname then return nil end
    TheFocalPoint.SoundEmitter:PlaySound(removed_sound)
	
	local identifier = self.foodtile_identifiers[foodname]
	if not identifier then print("Food does not exist on an identifier list, something went wrong!") return end
	
	local data = self.foodtiles[identifier]
	local row = data.row
	local column = data.column
	local num = ConvertRowColumnToNumberPosition(row,column)
	local food_positions = {}
	for num,info in pairs(self.foodtiles) do
		local pos = ConvertRowColumnToNumberPosition(info.row,info.column)
		food_positions[pos] = info.name
	end
	table.remove(food_positions,num)
	for pos,food in pairs(food_positions) do 
		local row,column = ConvertNumberToRowColumnPositions(pos)
		local tile = self.foodtiles[self.foodtile_identifiers[food]]
		tile.row = row
		tile.column = column
	end
	self.foodtiles[identifier].widget:Kill()
	table.remove(self.foodtiles,identifier)
	self.foodtile_identifiers[data.name] = nil
	for index,info in pairs(self.foodtiles) do
		self.foodtile_identifiers[info.name] = index
	end
	local new_row,new_column = ConvertNumberToRowColumnPositions(#food_positions)
	self.rows = new_row
	self.rowitems = new_column
	self:UpdateFoodTiles()
end

function FoodMemory:UpdateFoodTiles()
    self:UpdateSize()
    for _,widget_info in pairs(self.foodtiles) do 
		local tile = widget_info.widget
		local num = widget_info.column
		local row = widget_info.row
            local min_vx = -16 -- Min distance it has to be from the vertical edges
            local u_x = self.size_x-2*min_vx
            local d_x = u_x/(items_row+1)
            --Z:
            local min_tz = 32 -- Min top
            local min_bz = 0 -- Min bot
            local u_z = self.size_z-min_tz-min_bz
            local d_z = u_z/(self.rows+1)
            tile:SetPosition((-0.5)*u_x+d_x*num,(0.5)*u_z-min_tz-d_z*row)
    end
    for k,widget_info in pairs(self.spices) do
       local widget = widget_info.widget 
       local pos = preset_spicebuff_positionscales[k]
       
        local min_tz = -16 -- Min top
        local min_bz = 0 -- Min bot
        local u_z = self.size_z-min_tz-min_bz
        local d_z = u_z/(self.rows+1)
        
       widget:SetPosition(pos.x*self.size_x,(0.5)*u_z-min_tz-d_z*1)
    end
end



local sort_fns = {
    shorttime = function(a,b) return FoodMemory:GetTimerForFood(a)<FoodMemory:GetTimerForFood(b) end,
    longtime = function(a,b) return FoodMemory:GetTimerForFood(a)>FoodMemory:GetTimerForFood(b) end,
    AZ = function(a,b) return STRINGS.NAMES[string.upper(a)]<STRINGS.NAMES[string.upper(b)] end,
    ZA = function(a,b) return STRINGS.NAMES[string.upper(a)]>STRINGS.NAMES[string.upper(b)] end,
    --Should we check the existence of the food property table such that we don't index a nil value?
    hunger_asc = function(a,b) return GetFoodPropertyForFood(a).stats.hunger<GetFoodPropertyForFood(b).stats.hunger end,
    hunger_desc = function(a,b) return GetFoodPropertyForFood(a).stats.hunger>GetFoodPropertyForFood(b).stats.hunger end,
    health_asc = function(a,b) return GetFoodPropertyForFood(a).stats.health<GetFoodPropertyForFood(b).stats.health end,
    health_desc = function(a,b) return GetFoodPropertyForFood(a).stats.health>GetFoodPropertyForFood(b).stats.health end,
}



function FoodMemory:SortFoodTilesByFunction(fn)
    if not (type(fn) == "function") then 
        --print("Error: no function; Sorting by shortest time...")
        --fn = function(a,b) return self:GetTimerForFood(a)<self:GetTimerForFood(b) end
        fn = sort_fns[fn] or sort_fns[sort_type] or nil
    end
    if not fn then return nil end
	
	local food_prefabs = {}
	for _,info in pairs(self.foodtiles) do
		table.insert(food_prefabs,#food_prefabs+1,info.name)
	end
	
    table.sort(food_prefabs,fn)
	
	local food_numbers = {}
	for k,name in pairs(food_prefabs) do--Make a reverse one: food - number
		food_numbers[name] = k
	end
	
	local row,column
	for food,num in pairs(self.foodtile_identifiers) do
		row,column = ConvertNumberToRowColumnPositions(food_numbers[food])
		self.foodtiles[num].column = column
		self.foodtiles[num].row = row
	end

    self:UpdateFoodTiles()
    
    return true
end

function FoodMemory:OnUpdate(dt)
		for food,identifier in pairs(self.foodtile_identifiers) do
			local time = self:GetTimerForFood(food)
			local buff = GetFoodPropertyForFood(food).buffs
            buff = buff[1] and buff[1].name
			local buff_time
			if buff then
				buff_time = self:GetTimerForBuff(buff,time_format_type)
			end
			self.food_timers[food] = time
			local time_str = self:GetTimerForFood(food,time_format_type)
			self.foodtiles[identifier].widget.food.timer:SetString(time_str)
			self.foodtiles[identifier].widget.food.bufftimer:SetString(buff_time)
            if type(time) == "number" and time < -1 then --Enough time has passed for the event to remove it!
                self:RemoveFoodTimer(food)
            end
		end
		
        for k,_ in pairs(self.buff_timers) do
           local time = self:GetTimerForBuff(k)
           self.buff_timers[k] = time == "" and 0 or time
        end
        
        for k,info in pairs(self.spices) do
          local name = info.name
           if not name then break end
           local spice = string.match(name,"spice_(%w+).tex")
           local time = self:GetTimerForBuff(spice)
           local widget = info.widget
           if time and type(time) == "number" and (time > 0) and widget.active then
                local time_str = self:GetTimerForBuff(spice,time_format_type)
                local time = self:GetTimerForBuff(spice)
                self.spice_timers[spice] = time
                widget.timer:SetString(time_str)
            else
                self.spices[k].name = "undefined"
                widget.active = nil
                widget.item:SetTexture("images/inventoryimages1.xml","meatballs.tex")
                widget.item:Hide()
                widget:Hide()
            end
        end
        
		temp_timers = self.food_timers or temp_timers
		temp_foodtiles = self.foodtiles or temp_foodtiles
		temp_foodtile_identifiers = self.foodtile_identifiers or temp_foodtile_identifiers
        temp_spice_identifiers = self.spices or temp_spice_identifiers
        temp_spice_timers = self.spice_timers or temp_spice_timers
        temp_buff_timers = self.buff_timers or temp_buff_timers
        

end

if toggle_menu_key and toggle_menu_key ~= 0 then
    TheInput:AddKeyUpHandler(toggle_menu_key, function() 
        if ThePlayer and ThePlayer.HUD and not ThePlayer.HUD:HasInputFocus() then 
            ontogglemenu_press_fn() 
        end 
    end)
end


return FoodMemory
    