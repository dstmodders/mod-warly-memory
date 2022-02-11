name = "Warly Memory"
author = "sauktux"
version = "1.4.4"

forumthread = ""
description = "Remember what food you've eaten recently."

api_version = 10

dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
dst_compatible = true

all_clients_require_mod = false
client_only_mod = true
server_filter_tags = {}

icon_atlas = "modicon.xml"
icon = "modicon.tex"

local function AddConfig(name,label,hover,options,default)
    return  {
        name = name,
        label = label,
        hover = hover,
        options = options,
        default = default,
        }
end
local function AddEmptySeperator(seperator)
    return {
  name = "",
  label = seperator,
  hover = "",
  options = {
    {description = "", data = 0},
  },
  default = 0,
  
}
end

local bool_opt = {
    {description = "True", data = true},
    {description = "False", data = false},
}

local keys_opt = {
  {description = "None--", data = 0},
  {description = "A", data = 97},
  {description = "B", data = 98},
  {description = "C", data = 99},
  {description = "D", data = 100},
  {description = "E", data = 101},
  {description = "F", data = 102},
  {description = "G", data = 103},
  {description = "H", data = 104},
  {description = "I", data = 105},
  {description = "J", data = 106},
  {description = "K", data = 107},
  {description = "L", data = 108},
  {description = "M", data = 109},
  {description = "N", data = 110},
  {description = "O", data = 111},
  {description = "P", data = 112},
  {description = "Q", data = 113},
  {description = "R", data = 114},
  {description = "S", data = 115},
  {description = "T", data = 116},
  {description = "U", data = 117},
  {description = "V", data = 118},
  {description = "W", data = 119},
  {description = "X", data = 120},
  {description = "Y", data = 121},
  {description = "Z", data = 122},
  {description = "--None--", data = 0},
  {description = "Period", data = 46},
  {description = "Slash", data = 47},
  {description = "Semicolon", data = 59},
  {description = "LeftBracket", data = 91},
  {description = "RightBracket", data = 93},
  {description = "F1", data = 282},
  {description = "F2", data = 283},
  {description = "F3", data = 284},
  {description = "F4", data = 285},
  {description = "F5", data = 286},
  {description = "F6", data = 287},
  {description = "F7", data = 288},
  {description = "F8", data = 289},
  {description = "F9", data = 290},
  {description = "F10", data = 291},
  {description = "F11", data = 292},
  {description = "F12", data = 293},
  {description = "Up", data = 273},
  {description = "Down", data = 274},
  {description = "Right", data = 275},
  {description = "Left", data = 276},
  {description = "PageUp", data = 280},
  {description = "PageDown", data = 281},
  {description = "Home", data = 278},
  {description = "Insert", data = 277},
  {description = "Delete", data = 127},
  {description = "End", data = 279},
  {description = "--None", data = 0},
}

local special_buttons = {
    {description = "None--", data = 0},
    {description = "RShift", data = 303},
    {description = "LShift", data = 304},
    {description = "LCtrl", data = 306},
    {description = "RCtrl", data = 305},
    {description = "RAlt", data = 307},
    {description = "LAlt", data = 308},
    {description = "--None", data = 0},
  }
  
  local time_formats = {
      {description = "Seconds", data = "s", hover = "Show the time in seconds."},
      {description = "Minutes & seconds", data = "min", hover = "Show the time in a mm:ss format."},
      {description = "Days", data = "day", hover = "Show the time in days."},
  }
  
  local sort_type = {
     {description = "Shortest time", data = "shorttime", hover = "Sort in ascending time order(From low to high timers)"}, 
     {description = "Longest time", data = "longtime", hover = "Sort in descending time order(From high to low timers)"},
     {description = "Alphabetically A-Z", data = "AZ", hover = "Sort foods alphabetically (A-Z)."},
     {description = "Alphabetically Z-A", data = "ZA", hover = "Sort foods in reverse alphabetical order (A-Z)."},
     {description = "Lowest hunger", data = "hunger_asc", hover = "Sort foods in ascending order by hunger value."},
     {description = "Highest hunger", data = "hunger_desc", hover = "Sort foods in descending order by hunger value."},
     {description = "Lowest health", data = "health_asc", hover = "Sort foods in ascending order by health value."},
     {description = "Highest health", data = "health_desc", hover = "Sort foods in descending order by health value."},
  }
  
  local itemsperrow = {}
  for i = 1,14 do
      itemsperrow[i] = {description = ""..i, data = i}
  end
  
  local sounds = {
    {description = "None-", data = "", hover = "Don't play any sound"},
    {description = "Crock Pot Built", data = "dontstarve/common/cook_pot_craft", hover = "Crock Pot getting built/placed sound"}, 
    {description = "Crock Pot Cooked", data = "dontstarve/common/cookingpot_finish", hover = "Crock Pot finishing cooking a meal"},
    {description = "Dust Moth Sneeze", data = "grotto/creatures/dust_moth/sneeze", hover = "Dust Moth Sneezing sound"},
    {description = "Dust Moth Eat", data = "grotto/creatures/dust_moth/eat", hover = "Dust Moth Eat sound"},
    {description = "Woby Eat", data = "dontstarve/characters/walter/woby/small/eat", hover = "Woby Eat sound"},
    {description = "Portable Pot Collapse", data = "dontstarve/common/together/portable/cookpot/collapse", hover = "Portable Crock Pot getting dismantled sound"},
    {description = "Portable Pot Place", data = "dontstarve/common/together/portable/cookpot/place", hover = "Portable Crock Pot being placed sound"},
    {description = "Wickerbottom Yawn", data = "dontstarve/characters/wickerbottom/yawn", hover = "Wickerbottom's Yawn sound"},
    {description = "Willow Yawn", data = "dontstarve/characters/willow/yawn", hover = "Willow's Yawn sound"},
    {description = "Wilson Death", data = "dontstarve/characters/wilson/death_voice", hover = "Wilson's Death Voice sound"},
    {description = "-None", data = "", hover = "Don't play any sound"},
  }
  
    local times = {
        {description = "Default", data = "Default", hover = "The default time for Warly's food memory to expire."},
        --Can't have TUNING values in here, so let's convert it to the tuning value when it's called.
    }
    for i = 60*24,60*4,-60 do
       times[2+(24-i/60)] = {description = (i/60).."min", data = i, hover = "Non-default food memory time. \n Note: this time will likely not match Warly's food memory."}
    end
  
  

configuration_options = {
    AddConfig("time_format","Time format","How should the time format be displayed?",time_formats,"min"),
    AddConfig("itemsperrow","Items per row","How many items should be in a single row?",itemsperrow,7),
    AddConfig("do_sort","Sort Tiles","Should the food tiles be sorted everytime a new food is added?",bool_opt,true),
    AddConfig("sort_type","Sort Type","How should the food tiles be sorted?",sort_type,"shorttime"),
    AddConfig("unique_add","Food Add Sound","What sound should be played when a unique dish is added to the list?",sounds,"dontstarve/common/cookingpot_finish"),
    AddConfig("unique_remove","Food Remove Sound","What sound should be played when a dish is removed from the list",sounds,"dontstarve/common/cook_pot_craft"),
    AddConfig("toggle_menu","Toggle Food Menu","Use a button to open/close the food menu.",keys_opt,118),--V
    AddConfig("reset_on_change_character","Portal Delete Memory","Should using the portal to switch characters delete the food timers?",bool_opt,true),
    AddConfig("warly_only","Warly-Only","Should the widget only turn on when you're Warly?",bool_opt,false),
    AddConfig("infinitetime","Time Persistence","Should the food time not progress for non-Warly characters?",bool_opt,false),
    AddConfig("foodtime","Food Timer","The time the foods will be timed for when consumed.",times,"Default"),
    }
