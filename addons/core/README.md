# Core

Unified entry point for all gd-snips addons. Load all addons with a single import.

## Installation

1. Copy the `addons/core` directory into your Godot project's `addons/` folder
2. Open your project in Godot
3. Go to **Project → Project Settings → Plugins**
4. Enable the "Core" plugin

**Note:** The Core addon requires the other addons (Transport, Support) to be installed as well.

**Requirements:** Godot 4.5.1 or later

## Usage

Load all addons with a single import:

```gdscript
const Core = preload("res://addons/core/core.gd")

# Access Transport addon
var command_bus = Core.Transport.CommandBus.new()
var event_bus = Core.Transport.EventBus.new()

# Access Support addon
Core.Support.ArrayUtils.remove_indices(arr, [1, 3])
Core.Support.StringUtils.is_blank("   ")
```

## Available Addons

### Transport

Type-safe command/event transport framework.

Access via `Core.Transport`:
- `Core.Transport.CommandBus`
- `Core.Transport.EventBus`
- `Core.Transport.Message`
- `Core.Transport.Command`
- `Core.Transport.Event`
- And all other Transport classes

**[Full Transport Documentation →](../transport/README.md)**

### Support

Utility functions for array and string operations.

Access via `Core.Support`:
- `Core.Support.ArrayUtils`
- `Core.Support.StringUtils`

**[Full Support Documentation →](../support/README.md)**

## Alternative Usage

You can still import addons individually if you prefer:

```gdscript
# Individual imports
const Transport = preload("res://addons/transport/transport.gd")
const Support = preload("res://addons/support/support.gd")
```

## License

[Add license information here]

