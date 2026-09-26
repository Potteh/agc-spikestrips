# agc-spikestrips

QBCore police spike strips.

## Install
1. Copy `agc-spikestrips` into your resources folder, e.g. `[agc]/agc-spikestrips`.
2. Add `ensure agc-spikestrips` after `qb-core` in `server.cfg`.
3. Restart the resource/server.

## Commands
- `/spikes` - enter placement mode (police/on-duty by default).
- `/removespikes` - pick up the closest strip.
- `/clearspikes` - remove all strips you deployed.

## Placement controls
- E: place
- Left/Right arrows: rotate
- Backspace: cancel

## Optional inventory mode
Set `Config.RequireItem = true`. Set `Config.ConsumeItem = true` if deploying should remove the item and picking it up should return it.

Example qb-core shared item:

```lua
spikestrip = { name = 'spikestrip', label = 'Spike Strip', weight = 2500, type = 'item', image = 'spikestrip.png', unique = false, useable = false, shouldClose = true, description = 'Police tire deflation device' },
```

No inventory item is required with the default configuration.
