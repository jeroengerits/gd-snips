# Folder Structure Proposals for Messaging System

> **Note**: The current implementation uses a DDD-aligned structure. See [DDD_STRUCTURE.md](core/messaging/DDD_STRUCTURE.md) for details.

## Current Structure (DDD-Aligned) ✅

```
core/messaging/
├── domain/              # Domain Layer - Pure business concepts
│   ├── message.gd       # Base Message class
│   ├── command.gd       # Command base class
│   └── event.gd         # Event base class
│
├── infrastructure/      # Infrastructure Layer - Technical implementation
│   └── message_bus.gd   # Base MessageBus class
│
└── application/         # Application Layer - Use cases/application services
    ├── command_bus.gd   # CommandBus
    └── event_bus.gd     # EventBus
```

This structure follows Domain-Driven Design principles with clear layer separation.

---

## Previous Structures (Historical)

## Option 1: Pattern-Based Grouping (RECOMMENDED) ⭐

Groups related bus and message classes together, which aligns with how they're used.

```
core/messaging/
├── core/                    # Foundation/base classes
│   ├── message.gd          # Base Message class
│   └── message_bus.gd      # Base MessageBus class
├── command/                 # Command pattern
│   ├── command.gd          # Command message type
│   └── command_bus.gd      # Command bus implementation
└── event/                   # Event pattern
    ├── event.gd            # Event message type
    └── event_bus.gd        # Event bus implementation
```

**Pros:**
- ✅ Related components are co-located (Command + CommandBus together)
- ✅ Clear separation by pattern (Command vs Event)
- ✅ Easy to understand: "I need commands? Go to command/"
- ✅ Scales well if you add QueryBus later
- ✅ Matches how developers think about features

**Cons:**
- ❌ Base classes are separated from their extensions
- ❌ Slightly more folders

---

## Option 2: Type-Based Separation (Historical)

Previous structure that grouped files by their type (buses vs messages).

```
core/messaging/
├── buses/                   # All bus implementations
│   ├── message_bus.gd      # Base bus
│   ├── command_bus.gd
│   └── event_bus.gd
└── messages/                # All message types
    ├── message.gd          # Base message
    ├── command.gd
    └── event.gd
```

**Pros:**
- ✅ Clear separation: infrastructure vs data types
- ✅ Simple two-folder structure
- ✅ All buses in one place, all messages in one place

**Cons:**
- ❌ Unrelated components (CommandBus, EventBus) grouped together
- ❌ Command and CommandBus are separated (conceptual coupling lost)

---

## Option 3: Flat Structure

Everything at the root level with clear naming.

```
core/messaging/
├── message.gd
├── message_bus.gd
├── command.gd
├── command_bus.gd
├── event.gd
└── event_bus.gd
```

**Pros:**
- ✅ Simplest structure
- ✅ Easy to find files
- ✅ No folder navigation needed

**Cons:**
- ❌ Can get cluttered as system grows
- ❌ No logical grouping
- ❌ Harder to understand relationships

---

## Option 4: Layer-Based with Core

Separate base/core from implementations.

```
core/messaging/
├── core/                    # Foundation
│   ├── message.gd
│   └── message_bus.gd
├── implementations/
│   ├── command/
│   │   ├── command.gd
│   │   └── command_bus.gd
│   └── event/
│       ├── event.gd
│       └── event_bus.gd
```

**Pros:**
- ✅ Clear core vs implementation separation
- ✅ Related components grouped

**Cons:**
- ❌ Deeper nesting (3 levels)
- ❌ More complex to navigate

---

## Previous Implementation: Option 2 (Type-Based Separation)

**Status**: Replaced by DDD-aligned structure (see Current Structure above).

**Why Option 2 was chosen:**
1. **Clear separation**: Infrastructure (buses) vs data types (messages) is immediately obvious
2. **Simple structure**: Only two folders, easy to navigate
3. **Logical grouping**: All buses together, all messages together
4. **GDScript compatibility**: Since classes use `class_name` for global registration, physical location doesn't matter for usage

**Note**: Option 1 (Pattern-Based) remains a valid alternative for future consideration, offering better conceptual coupling between related components.

---

## Alternative Recommendation: Option 1 (Pattern-Based)

**Why this could be better:**
1. **Conceptual alignment**: When using commands, you work with both Command and CommandBus - they belong together
2. **Feature-focused**: Developers think "I need commands" not "I need a bus and a message type separately"
3. **Scalability**: Easy to add new patterns (QueryBus) without restructuring
4. **Intuitive navigation**: Clear mental model matches actual usage patterns

### Implementation
```
core/messaging/
├── core/
│   ├── message.gd          # Foundation: base message class
│   └── message_bus.gd      # Foundation: base bus infrastructure
├── command/
│   ├── command.gd          # Command pattern: message type
│   └── command_bus.gd      # Command pattern: bus implementation
└── event/
    ├── event.gd            # Event pattern: message type
    └── event_bus.gd        # Event pattern: bus implementation
```

This structure makes it immediately clear:
- **core/** = foundational classes everything builds on
- **command/** = everything related to the command pattern
- **event/** = everything related to the event pattern

