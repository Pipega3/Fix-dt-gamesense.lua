
 
local ffi = require('ffi')
local client = client
local entity = entity
local ui = ui
local renderer = renderer
local globals = globals
local bit = bit
 
local function toticks(seconds)
    return math.floor(seconds / globals.tickinterval() + 0.5)
end

local clamp = function(value, min, max) 
    return math.min(math.max(value, min), max) 
end
 
local clases = {}
function class(name)
    return function(tab)
        if not tab then return clases[name] end
        tab.__index, tab.__classname = tab, name
        if tab.call then tab.__call = tab.call end
        setmetatable(tab, tab)
        clases[name], _G[name] = tab, tab
        return tab
    end
end

 
local g_ctx = {
    local_player = nil, 
    weapon = nil,
    aimbot = ui.reference("RAGE", "Aimbot", "Enabled"), 
    doubletap = {ui.reference("RAGE", "Aimbot", 'Double tap')}, 
    hideshots = {ui.reference("AA", 'Other', 'On shot anti-aim')}, 
    fakeduck = ui.reference("RAGE", "Other", "Duck peek assist")
}

 
local dt_fix_enable = ui.new_checkbox("Rage", "Other", "Enable DT Fix")
local dt_speed = ui.new_slider("Rage", "Other", "DT Speed %", 0, 100, 100, true, "%", 1)
local dt_teleport = ui.new_combobox("Rage", "Other", "Teleport Mode", "Off", "On Last Tick", "Always")
local dt_charge_mode = ui.new_combobox("Rage", "Other", "Charge Mode", "Auto", "Manual")
local dt_show_indicator = ui.new_checkbox("Rage", "Other", "Show DT Indicator")

 
class "exploits" {
    max_process_ticks = math.abs(client.get_cvar("sv_maxusrcmdprocessticks")) - 1,
    tickbase_difference = 0,
    ticks_processed = 0,
    command_number = 0,
    choked_commands = 0,
    need_force_defensive = false,
    current_shift_amount = 0,

    reset_vars = function(self)
        self.ticks_processed = 0
        self.tickbase_difference = 0
        self.choked_commands = 0
        self.command_number = 0
    end,

     
}


local exploits = {
    max_process_ticks = math.abs(client.get_cvar("sv_maxusrcmdprocessticks")) - 1,
    tickbase_difference = 0,
    ticks_processed = 0,
    command_number = 0,
    choked_commands = 0,
    need_force_defensive = false,
    current_shift_amount = 0
}

-- Методы
function exploits:reset_vars()
    self.ticks_processed = 0
    self.tickbase_difference = 0
    self.choked_commands = 0
    self.command_number = 0
end

  

local ref = {
    aimbot = ui.reference('RAGE', 'Aimbot', 'Enabled'),
    doubletap = {
        main = { ui.reference('RAGE', 'Aimbot', 'Double tap') },
        fakelag_limit = ui.reference('RAGE', 'Aimbot', 'Double tap fake lag limit')
    }
}

local local_player, callback_reg, dt_charged = nil, false, false

 
local function toticks(seconds)
    return math.floor(seconds / globals.tickinterval() + 0.2)
end

local function check_charge()
    if not local_player or not entity.is_alive(local_player) then return end

    local m_nTickBase = entity.get_prop(local_player, 'm_nTickBase')
    local client_latency = client.latency()
    local server_tickrate = 128   
    local latency_ticks = math.max(1, math.floor(client_latency / globals.tickinterval() + 0.5))
 
    local shift = math.floor(m_nTickBase - globals.tickcount() - 3 - toticks(client_latency) * 0.3 + 0.3 * (client_latency * 9))

 
    local fakelag_limit = ui.get(ref.doubletap.fakelag_limit) or 1
    local wanted = -15 + (fakelag_limit - 1) + 3   

  
    dt_charged = shift <= wanted + 1  

    
    if shift > wanted + 3 then
        dt_charged = false
    end
end

local function rage_teleport(cmd)
    if not dt_charged then return end   

    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return end

 
    local teleport_tick = globals.tickcount() + 1   

     
    cmd.tick_count = teleport_tick

   
end
 
local function check_charge_aggressive()
    local lp = entity.get_local_player()
    if not lp or not entity.is_alive(lp) then return false end

    local tickbase = entity.get_prop(lp, "m_nTickBase")
    local shift = m_nTickBase - globals.tickcount()
 
    local fakelag_limit = ui.get(ref.doubletap.fakelag_limit) or 1
    local wanted = -14 + (fakelag_limit - 1) + 2
 
    dt_charged = shift <= wanted + 1
end

 

client.set_event_callback('setup_command', function()
    local_player = entity.get_local_player()
    if not local_player or not entity.is_alive(local_player) then return end

   
    if not ui.get(ref.doubletap.main[2]) or not ui.get(ref.doubletap.main[1]) then
        ui.set(ref.aimbot, true)
        if callback_reg then
            client.unset_event_callback('run_command', check_charge)
            callback_reg = false
        end
        return
    end


        if not ui.get(ref.doubletap.main[2]) or not ui.get(ref.doubletap.main[1]) then
        ui.set(ref.aimbot, true)
        if callback_reg then
            client.unset_event_callback('run_command', check_charge_aggressive)
            callback_reg = false
        end
        return
    end
 
      if not ui.get(ref.doubletap.main[2]) or not ui.get(ref.doubletap.main[1]) then
        ui.set(ref.aimbot, true)
        if callback_reg then
            client.unset_event_callback('run_command', rage_teleport)
            callback_reg = false
        end
        return
    end

    if not callback_reg then
        client.set_event_callback('run_command', check_charge)
        callback_reg = true
    end

    
    if not dt_charged then
        ui.set(ref.aimbot, false)
    else
        ui.set(ref.aimbot, true)
    end
end)

client.set_event_callback('shutdown', function()
    ui.set(ref.aimbot, true)
end)

 
local aimbot_ref = ui.reference("RAGE", "Aimbot", "Enabled")
local doubletap_ref = ui.reference("RAGE", "Aimbot", "Double tap")
local fakeduck_ref = ui.reference("RAGE", "Other", "Duck peek assist")

 
local was_dt_disabled_by_fakeduck = false

 
local function force_aimbot_on_fakeduck(cmd)
    local local_player = entity.get_local_player()

    if not local_player or not entity.is_alive(local_player) then
        return
    end

 
    local is_fakeduck_enabled = ui.get(fakeduck_ref)

    
    local is_ducking = bit.band(cmd.buttons, 1) ~= 0   

 
    local is_fakeducking = is_fakeduck_enabled and is_ducking

    if is_fakeducking then
    
        if ui.get(doubletap_ref) and not was_dt_disabled_by_fakeduck then
            ui.set(doubletap_ref, false)
            was_dt_disabled_by_fakeduck = true
        end

      
        ui.set(aimbot_ref, true)

    else
     

        if was_dt_disabled_by_fakeduck then
            ui.set(doubletap_ref, true)
            was_dt_disabled_by_fakeduck = false
        end

   
    end
end

 
client.set_event_callback("setup_command", force_aimbot_on_fakeduck)



 
local dt_ref = ui.reference("Rage", "Aimbot", "Double tap")

 
local Bind_for_fd = ui.new_hotkey("Rage", "Other", "Bind_for_fd")       
local Test = ui.new_hotkey("Rage", "Other", "Not working ")  

-- я тупой в бинд системе не разобрался по этому юзайте первый hotkey(Bind_for_fd)
 --I'm not good at the bind system, so use the first hotkey (Bind_for_fd)
local dt_toggled = false
local was_toggle_down = false

  
client.set_event_callback("setup_command", function()
    local hold_down = ui.get(Bind_for_fd)         
    local toggle_down = ui.get(Test)     
    local toggle_pressed = toggle_down and not was_toggle_down   

     
    local dt_active = false

   
    if hold_down then
        dt_active = false
    else
    
        dt_active = true
    end
 
    if toggle_pressed then
        dt_toggled = not dt_toggled
    end
 
    ui.set(dt_ref, dt_active)
 
    was_toggle_down = toggle_down
end)
