# ODefeat

## Ostim Defeat Mod

Adds defeat mechanics to the game.

## Requirements

* [OStim](https://www.nexusmods.com/skyrimspecialedition/mods/40725)
* [PO3 Papyrus Extender](https://www.nexusmods.com/skyrimspecialedition/mods/22854)
* [NL_MCM](https://www.nexusmods.com/skyrimspecialedition/mods/49127)
* [Nemesis or FNIS](https://github.com/ShikyoKira/Project-New-Reign---Nemesis-Main/releases)

## Contributing

Fork and make a PR, just make sure it's tested before you PR.

## Event System

Modular post-defeat events are pulled from json files stored in Data/Meshes/ODefeatData/Events/*.json

They are formatted like so:

```json
{
  "Simple Slavery Enslavement": {
    "Form": "__formData|SimpleSlavery.esp|0x00492E",
    "modEventName" : "SSLV Entry",
    "Weighting": 69,
    "Description" : "After a defeat, you wake up in the Simple Slavery auction house as the next item to be sold."
  }
}
```

Breaking this down, you can see:

* ``Event Name``: At the top, this is what will be displayed in the MCM.
* ``Form``: A formid that can be used to check if the relative mod is installed. This can be whatever you want really.
* ``modEventName``: The name of the modevent this post-defeat event should fire.
* ``Weighting``: Default weighting for this event to be shown on the MCM.
* ``Description``: Describes the event to the user, shown in the info section at the bottom of the MCM when moused over.
