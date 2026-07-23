# PeaversBestInSlot

[![AddonSentry](https://addonsentry.io/api/public/repos/peavers-warcraft/PeaversBestInSlot/badge.svg)](https://addonsentry.io/dashboard/peavers-warcraft/PeaversBestInSlot)

A World of Warcraft addon that displays Best-in-Slot item information in tooltips, sourced from wowcompare.io.

## Features

<!-- peavers:features -->
- Shows BiS status directly on item tooltips
- Supports both Raid and Mythic+ content
- Displays drop source (boss/dungeon name)
- Shows if items are BiS for other specs
- Easy toggle between Raid and M+ BiS views
- Fully configurable display options
<!-- /peavers:features -->

## Usage

<!-- peavers:usage -->
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
<!-- /peavers:usage -->

<!-- peavers:custom -->
## Screenshots

When you hover over an item, you'll see:
- Green text for primary BiS items
- Gold text for alternative BiS items
- The boss or dungeon where the item drops
- Optional info about other specs that use this item
<!-- /peavers:custom -->


## Installation

PeaversBestInSlot is released exclusively through [addons.peavers.io](https://addons.peavers.io) and is no longer published to CurseForge.

### Recommended: PeaversUpdater

Download and install [PeaversUpdater](https://github.com/peavers-warcraft/PeaversUpdater/releases/latest), the desktop updater for the whole Peavers collection. It installs PeaversBestInSlot together with its required dependencies and keeps everything up to date automatically.

### Alternative: manual install

1. Download the latest zip from [Releases](https://github.com/peavers-warcraft/PeaversBestInSlot/releases/latest)
2. Extract it into `World of Warcraft/_retail_/Interface/AddOns/`
3. Ensure [PeaversCommons](https://github.com/peavers-warcraft/PeaversCommons) is also installed
4. Ensure [PeaversConfig](https://github.com/peavers-warcraft/PeaversConfig) is also installed
5. Enable the addon on the character selection screen

---

*Part of the [Peavers](https://peavers.io) addon collection · [Report an issue](https://github.com/peavers-warcraft/PeaversBestInSlot/issues) · [Support development on Patreon](https://www.patreon.com/Peavers)*
