Config = {}

Config.Debug = false
Config.AllowedJobs = {
    police = true,
}
Config.RequireOnDuty = true
Config.RequireItem = false
Config.ItemName = 'spikestrip'
Config.ConsumeItem = false

Config.PlaceCommand = 'spikes'
Config.RemoveCommand = 'removespikes'
Config.ClearCommand = 'clearspikes'
Config.MaxPerOfficer = 4
Config.PlaceDistance = 2.0
Config.RemoveDistance = 4.0
Config.SpikeModel = `p_ld_stinger_s`
Config.GroundOffset = 0.02

-- GTA tire indexes. Each tire is tested against the strip independently.
Config.Tires = {
    { index = 0, bone = 'wheel_lf' },
    { index = 1, bone = 'wheel_rf' },
    { index = 4, bone = 'wheel_lr' },
    { index = 5, bone = 'wheel_rr' },
    { index = 2, bone = 'wheel_lm1' },
    { index = 3, bone = 'wheel_rm1' },
    { index = 45, bone = 'wheel_lm2' },
    { index = 47, bone = 'wheel_rm2' },
}

Config.PunctureDistance = 0.65
Config.CheckInterval = 80
Config.PickupAnimation = {
    dict = 'pickup_object',
    name = 'pickup_low',
    duration = 900,
}
