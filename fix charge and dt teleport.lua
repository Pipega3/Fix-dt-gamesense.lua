
 
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
    return math.floor(seconds / globals.tickinterval() + 0.5)
end

local function check_charge()
    if not local_player or not entity.is_alive(local_player) then return end

    local m_nTickBase = entity.get_prop(local_player, 'm_nTickBase')
    local client_latency = client.latency()
 
    local shift = math.floor(m_nTickBase - globals.tickcount() - 3 - toticks(client_latency) * 0.5 + 0.5 * (client_latency * 10))

 
    local wanted = -14 + (ui.get(ref.doubletap.fakelag_limit) - 1) + 3  

    dt_charged = shift <= wanted
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
