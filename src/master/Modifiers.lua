require('utils')
require('master.MasterBase')
require('gameSystem.ModifierSystem')

Master.Modifier = {}

Master.Modifier.TEST = {
    id = 'TEST',
    duration = -1,
    interval = 0.1,
    Effects = {{
        model = 'Abilities\\Spells\\Human\\ManaFlare\\ManaFlareTarget.mdl',
        attach_point = 'overhead'
    }},
    ---@param this Modifier
    Update = function(this)
        this.effects_scale = this.effects_scale + 0.1
    end
}