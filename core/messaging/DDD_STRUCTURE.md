# Domain-Driven Design Structure

This messaging system is organized according to DDD principles with clear separation of concerns:

## Layer Architecture

```
core/messaging/
├── domain/              # Domain Layer - Pure business concepts
│   ├── message.gd       # Core domain value object (base concept)
│   ├── command.gd       # Command domain concept (extends Message)
│   └── event.gd         # Event domain concept (extends Message)
│
├── infrastructure/      # Infrastructure Layer - Technical implementation
│   └── message_bus.gd   # Routing/subscription infrastructure (uses Message)
│
└── application/         # Application Layer - Use cases/application services
    ├── command_bus.gd   # Command application service (uses Command + MessageBus)
    └── event_bus.gd     # Event application service (uses Event + MessageBus)
```

## Layer Responsibilities

### Domain Layer (`domain/`)
**Purpose**: Core business concepts - what the system is about

- **Independent**: No dependencies on other layers
- **Pure domain models**: Value objects representing messaging concepts
- Contains: `Message`, `Command`, `Event`
- These are immutable data carriers with domain behavior

### Infrastructure Layer (`infrastructure/`)
**Purpose**: Technical implementation - how it works

- **Depends on**: Domain layer (uses `Message`)
- **Technical concerns**: Routing, subscription management, lifecycle handling
- Contains: `MessageBus` (with internal `Subscription` class)
- Provides generic message routing capabilities

### Application Layer (`application/`)
**Purpose**: Application services - use cases and orchestration

- **Depends on**: Domain layer (uses `Command`, `Event`) and Infrastructure (uses `MessageBus`)
- **Orchestration**: Coordinates domain concepts with infrastructure
- Contains: `CommandBus`, `EventBus`
- Application services that provide specific messaging patterns

## Dependency Flow

```
Application → Infrastructure → Domain
     ↓             ↓              ↓
CommandBus    MessageBus     Message
EventBus                   Command
                          Event
```

**Rule**: Dependencies only flow inward (toward Domain). Domain has no dependencies.

## Benefits of This Structure

1. **Clear Separation**: Business logic (domain) is independent of technical details (infrastructure)
2. **Testability**: Domain can be tested without infrastructure concerns
3. **Maintainability**: Changes to infrastructure don't affect domain models
4. **Extensibility**: New application services can be added without touching domain/infrastructure
5. **Clarity**: Developers can immediately understand what belongs where

## Usage

The `class_name` declarations in GDScript allow these classes to be used globally regardless of their file location. The folder structure is for organization and clarity, not a technical requirement.
