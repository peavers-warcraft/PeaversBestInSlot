# PeaversBestInSlot

A World of Warcraft addon that shows Best in Slot gear information directly in item tooltips.

**Website:** [peavers.io](https://peavers.io) | **Addon Backup:** [vault.peavers.io](https://vault.peavers.io) | **Issues:** [GitHub](https://github.com/peavers-warcraft/PeaversBestInSlot/issues)

## Features

- Shows BiS status directly on item tooltips
- Supports both Raid and Mythic+ content
- Displays drop source (boss/dungeon name)
- Shows if items are BiS for other specs
- Easy toggle between Raid and M+ BiS views
- Fully configurable display options

## Installation

1. Download from [CurseForge](https://www.curseforge.com/wow/addons/peaversbestinslot)
2. Also install [PeaversBestInSlotData](https://www.curseforge.com/wow/addons/peaversbestinslotdata) (required)
3. Also install [PeaversCommons](https://www.curseforge.com/wow/addons/peaverscommons) (required)

## Usage

### Slash Commands

- `/pbs` - Open configuration panel
- `/pbs raid` - Switch to Raid BiS view
- `/pbs dungeon` - Switch to Mythic+ BiS view
- `/pbs toggle` - Toggle BiS tooltips on/off
- `/pbs debug` - Toggle debug mode

### Configuration Options

- **Content Type**: Choose between Raid or Mythic+ BiS
- **Show Drop Source**: Display where items drop from
- **Show Priority**: Indicate if item is primary BiS or alternative
- **Show Other Specs**: Display if items are BiS for other specs
- **Compact Mode**: Use shorter text for less tooltip clutter

## Screenshots

When you hover over an item, you'll see:
- Green text for primary BiS items
- Gold text for alternative BiS items
- The boss or dungeon where the item drops
- Optional info about other specs that use this item

## Dependencies

- [PeaversBestInSlotData](https://github.com/peavers-warcraft/PeaversBestInSlotData) - Required data library
- [PeaversCommons](https://github.com/peavers-warcraft/PeaversCommons) - Required core library
