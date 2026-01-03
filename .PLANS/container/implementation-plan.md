# Dependency Injection Container Implementation Plan

**Date:** January 2026  
**Status:** Planning  
**Addon:** `container` (new addon)

---

## Overview

Implement a dependency injection (DI) container addon for Godot 4.5.1+ that follows the design principles established in the gd-snips codebase. The container will provide explicit, type-safe dependency management that integrates seamlessly with the Command/Event bus system and other gd-snips addons.

### Goals

- **Explicit API** - Clear, explicit registration and resolution over "magic" reflection
- **Type Safety** - Leverage Godot's type system for compile-time safety
- **Debuggability** - Clear error messages, validation, and introspection capabilities
- **Godot-Native** - Works with RefCounted objects, Node lifecycle, and Godot conventions
- **Integration** - Seamless integration with Command/Event bus system and other addons
- **Lightweight** - Minimal overhead, focused feature set (YAGNI principle)

---

## Design Principles

The container addon will follow the same design principles established in the Command/Event addons:

1. **Explicitness over "magic"** - Explicit service registration, no automatic discovery
2. **Type safety** - Leverage Godot's type system and class_name declarations
3. **Debuggability first** - Clear error messages, validation, verbose logging
4. **Deterministic behavior** - Predictable resolution and lifecycle management
5. **Godot conventions** - Works with RefCounted, Node lifecycle, and Godot patterns

---

## Architecture

### Addon Structure

```
addons/container/
├── plugin.cfg                    # Addon configuration
├── container.gd                  # Barrel file (public API)
└── src/
    ├── container.gd              # Main Container class
    ├── service_descriptor.gd     # Service registration metadata
    ├── service_lifetime.gd       # Lifetime enumeration
    ├── container_error.gd        # Error types
    └── utils/
        └── type_resolver.gd      # Type resolution utilities
```

### Core Components

#### 1. Container (Main Class)

The central service container that manages service registrations and resolutions.

**Key Responsibilities:**
- Service registration (singleton, transient, scoped)
- Service resolution with dependency injection
- Service lifecycle management
- Validation and error handling
- Integration with Command/Event bus system (optional)

**Base Class:** `RefCounted` (scene-tree independent, like CommandBus/EventBus)

#### 2. ServiceDescriptor

Metadata for a registered service, containing:
- Service type (class reference or StringName)
- Implementation type/factory
- Lifetime (singleton, transient, scoped)
- Dependencies (for validation)
- Registration metadata (for debugging)

#### 3. ServiceLifetime (Enum)

Defines service lifetime scopes:
- `SINGLETON` - One instance shared across all resolutions
- `TRANSIENT` - New instance on every resolution
- `SCOPED` - One instance per container scope (future: scene/Node scope)

#### 4. ContainerError

Error types for container operations:
- `SERVICE_NOT_REGISTERED` - Service type not found
- `CIRCULAR_DEPENDENCY` - Circular dependency detected
- `CONSTRUCTION_FAILED` - Service instantiation failed
- `INVALID_REGISTRATION` - Invalid registration parameters

---

## Feature Set

### Core Features (Phase 1)

#### 1. Service Registration

```gdscript
# Register singleton service
container.register_singleton(MyService, MyServiceImpl)

# Register transient service (new instance each time)
container.register_transient(IRepository, DatabaseRepository)

# Register with factory function
container.register_singleton(ILogger, func(): return FileLogger.new("/path/to/log"))

# Register instance (already created)
container.register_instance(IEventBus, event_bus_instance)
```

#### 2. Service Resolution

```gdscript
# Resolve service (with dependency injection)
var service = container.resolve(MyService)

# Resolve required service (throws error if not found)
var service = container.resolve_required(MyService)

# Check if service is registered
if container.is_registered(MyService):
    var service = container.resolve(MyService)

# Resolve all services of a type (for multiple registrations - future)
var services = container.resolve_all(IHandler)
```

#### 3. Dependency Injection

Automatic constructor injection for services with dependencies:

```gdscript
class PlayerService:
    var _command_bus: CommandBus
    var _event_bus: EventBus
    
    func _init(command_bus: CommandBus, event_bus: EventBus):
        _command_bus = command_bus
        _event_bus = event_bus
```

Container automatically resolves constructor parameters from registered services.

#### 4. Service Lifetime Management

- **Singleton:** One instance, created on first resolution, reused for all subsequent resolutions
- **Transient:** New instance created for each resolution
- **Instance:** Pre-created instance registered with container (singleton behavior)

#### 5. Validation and Error Handling

- Validate service registrations at registration time
- Detect circular dependencies during resolution
- Clear error messages with service type information
- Verbose logging for debugging

### Advanced Features (Phase 2+)

1. **Scoped Services** - Services with scene/Node lifecycle scope
2. **Named Services** - Multiple registrations of same type with names
3. **Service Collections** - Resolve all services implementing an interface
4. **Decorator Pattern** - Wrap services with decorators (logging, caching, etc.)
5. **Container Hierarchy** - Child containers with fallback to parent
6. **Lazy Loading** - Defer service construction until first use

---

## Integration Points

### Command/Event Bus Integration

The container can integrate with the Command/Event bus system:

```gdscript
# Register buses as singletons
var container = Container.new()
container.register_singleton(CommandBus, CommandBus.new())
container.register_singleton(EventBus, EventBus.new())

# Resolve in command handlers
container.resolve(CommandBus).handle(MoveCommand, func(cmd): ...)

# Inject buses into services
class GameService:
    var _command_bus: CommandBus
    var _event_bus: EventBus
    
    func _init(command_bus: CommandBus, event_bus: EventBus):
        _command_bus = command_bus
        _event_bus = event_bus
```

### Engine Addon Integration

Add Container to Engine addon barrel file for unified access:

```gdscript
# addons/engine/engine.gd
const Container = preload("res://addons/container/container.gd")
```

---

## API Design

### Container Class

```gdscript
extends RefCounted
class_name Container

## Register singleton service.
## @param service_type: Service type (class with class_name or StringName)
## @param implementation: Implementation class or factory Callable
func register_singleton(service_type: Variant, implementation: Variant) -> void

## Register transient service.
## @param service_type: Service type
## @param implementation: Implementation class or factory Callable
func register_transient(service_type: Variant, implementation: Variant) -> void

## Register pre-created instance.
## @param service_type: Service type
## @param instance: Pre-created service instance
func register_instance(service_type: Variant, instance: Object) -> void

## Resolve service (returns null if not registered).
## @param service_type: Service type to resolve
## @return: Service instance or null if not registered
func resolve(service_type: Variant) -> Variant

## Resolve required service (throws error if not registered).
## @param service_type: Service type to resolve
## @return: Service instance
func resolve_required(service_type: Variant) -> Variant

## Check if service is registered.
## @param service_type: Service type to check
## @return: true if registered, false otherwise
func is_registered(service_type: Variant) -> bool

## Clear all registrations.
func clear() -> void

## Enable verbose logging.
func set_verbose(enabled: bool) -> void
```

### ServiceLifetime Enum

```gdscript
enum ServiceLifetime {
    SINGLETON,
    TRANSIENT
}
```

### ContainerError Class

```gdscript
extends RefCounted
class_name ContainerError

enum Code {
    SERVICE_NOT_REGISTERED,
    CIRCULAR_DEPENDENCY,
    CONSTRUCTION_FAILED,
    INVALID_REGISTRATION
}

var code: Code
var message: String
var service_type: Variant
```

---

## Implementation Phases

### Phase 1: Core Container (MVP)

**Goal:** Basic DI container with singleton and transient lifetimes

**Tasks:**
1. Create addon structure (`addons/container/`)
2. Implement `ServiceLifetime` enum
3. Implement `ServiceDescriptor` class
4. Implement `ContainerError` class
5. Implement `Container` class with:
   - Service registration (singleton, transient, instance)
   - Service resolution (resolve, resolve_required)
   - Constructor injection (automatic dependency resolution)
   - Circular dependency detection
   - Basic validation and error handling
6. Create barrel file (`container.gd`)
7. Add plugin.cfg configuration
8. Basic documentation and examples

**Deliverables:**
- Working DI container with core features
- Documentation and examples
- Integration with Core addon

### Phase 2: Enhanced Features

**Goal:** Advanced features and optimizations

**Tasks:**
1. Scoped services (Node/scene lifecycle)
2. Named services (multiple registrations)
3. Service collections (resolve_all)
4. Performance optimizations (caching, lazy loading)
5. Enhanced debugging (introspection, dependency graph)
6. Integration examples with Command/Event bus system

### Phase 3: Advanced Patterns

**Goal:** Advanced DI patterns and integrations

**Tasks:**
1. Container hierarchy (child containers)
2. Service decorators
3. Advanced factory patterns
4. Lifecycle hooks (on_create, on_destroy)
5. Integration with Godot autoload system

---

## Implementation Details

### Constructor Injection

GDScript doesn't support reflection for constructor parameters, so we need an alternative approach:

**Option 1: Annotation-based (explicit)**
```gdscript
class PlayerService:
    var _command_bus: CommandBus
    var _event_bus: EventBus
    
    # Annotations in comments (parsed at runtime)
    # @inject CommandBus _command_bus
    # @inject EventBus _event_bus
    func _init(command_bus: CommandBus, event_bus: EventBus):
        _command_bus = command_bus
        _event_bus = event_bus
```

**Option 2: Type inference from _init signature**
- Parse `_init()` method signature using GDScript introspection
- Resolve parameters by type
- Requires type hints in constructor

**Option 3: Manual registration (most explicit, recommended for MVP)**
```gdscript
# Explicit dependency specification
container.register_singleton(PlayerService, func(container):
    return PlayerService.new(
        container.resolve_required(CommandBus),
        container.resolve_required(EventBus)
    )
)
```

**Recommendation:** Start with Option 3 (explicit factory functions) for Phase 1, as it's:
- Most explicit (aligns with design principles)
- No reflection needed
- Clear and debuggable
- Works with all GDScript features

Consider Option 2 for Phase 2 if type introspection becomes feasible.

### Type Resolution

Reuse patterns from Command/Event addons:
- Use `class_name` when available (most deterministic)
- Fall back to script path for instances
- Consider creating `TypeResolver` utility (similar to `MessageTypeResolver`)

### Circular Dependency Detection

Track resolution stack during service construction:
- Maintain a stack of types currently being resolved
- Detect cycles when a type appears twice in stack
- Clear error messages showing the cycle

### Error Handling

Follow Command/Event addon patterns:
- Use `ContainerError` class for structured errors
- Clear, descriptive error messages
- Include service type information in errors
- Use `push_error()` for logging
- Return errors or throw via assertions (Godot convention)

---

## Testing Strategy

### Unit Tests

1. **Service Registration:**
   - Singleton registration
   - Transient registration
   - Instance registration
   - Factory function registration
   - Duplicate registration handling
   - Invalid registration handling

2. **Service Resolution:**
   - Resolve singleton (same instance)
   - Resolve transient (different instances)
   - Resolve required (error if not found)
   - Resolve optional (null if not found)
   - Type checking

3. **Dependency Injection:**
   - Constructor injection
   - Nested dependencies
   - Circular dependency detection
   - Missing dependency handling

4. **Error Handling:**
   - Service not registered
   - Circular dependency errors
   - Construction failure errors
   - Invalid registration errors

### Integration Tests

1. Integration with Command/Event bus system
2. Real-world service composition scenarios
3. Performance testing (resolution speed, memory usage)

---

## Examples

### Basic Usage

```gdscript
const Container = preload("res://addons/container/container.gd")

# Create container
var container = Container.new()
container.set_verbose(true)

# Register services
container.register_singleton(CommandBus, CommandBus.new())
container.register_singleton(EventBus, EventBus.new())

# Register with dependencies
container.register_singleton(PlayerService, func():
    return PlayerService.new(
        container.resolve_required(CommandBus),
        container.resolve_required(EventBus)
    )
)

# Resolve services
var player_service = container.resolve_required(PlayerService)
var command_bus = container.resolve_required(CommandBus)
```

### Integration with Command/Event Buses

```gdscript
const Engine = preload("res://addons/engine/engine.gd")

# Setup container with Command/Event buses
var container = Container.new()
container.register_singleton(CommandBus, Engine.Command.Bus.new())
container.register_singleton(EventBus, Engine.Event.Bus.new())

# Register command handlers as services
container.register_transient(MoveCommandHandler, MoveCommandHandler)

# Resolve and register handler
var handler = container.resolve_required(MoveCommandHandler)
container.resolve_required(CommandBus).handle(MoveCommand, handler.handle)
```

### Service with Dependencies

```gdscript
class GameService:
    var _player_service: PlayerService
    var _command_bus: CommandBus
    var _event_bus: EventBus
    
    func _init(player_service: PlayerService, command_bus: CommandBus, event_bus: EventBus):
        _player_service = player_service
        _command_bus = command_bus
        _event_bus = event_bus

# Registration with factory
container.register_singleton(GameService, func():
    return GameService.new(
        container.resolve_required(PlayerService),
        container.resolve_required(CommandBus),
        container.resolve_required(EventBus)
    )
)
```

---

## Documentation

### README Structure

Following the pattern established in Command/Event addons:

1. **Overview** - What is the container addon
2. **Quick Start** - Minimal working example
3. **Core Concepts** - Service lifetimes, dependency injection
4. **Usage Guide** - Detailed examples and patterns
5. **API Reference** - Complete API documentation
6. **Best Practices** - Service design, lifecycle management
7. **Integration** - Command/Event bus system integration
8. **Architecture** - Internal design and patterns

### Developer Documentation

1. Add to CLAUDE.md (architectural decisions)
2. Developer diary entries for design decisions
3. Code comments and docstrings (GDScript style)

---

## Open Questions

1. **Constructor Injection:** Explicit factories (Phase 1) vs. type introspection (Phase 2)?
2. **Scoped Services:** How to define scope boundaries (Node? Scene? Custom scope object)?
3. **Service Validation:** Validate at registration time or resolution time?
4. **Container Singleton:** Provide global container instance or always explicit instantiation?
5. **Lifecycle Hooks:** Support service lifecycle callbacks (on_create, on_destroy)?
6. **Performance:** Is resolution speed critical? Need caching/optimization strategies?

---

## Success Criteria

1. ✅ Core DI container functionality working
2. ✅ Type-safe service registration and resolution
3. ✅ Clear, explicit API (no "magic")
4. ✅ Integration with Command/Event bus system
5. ✅ Comprehensive documentation and examples
6. ✅ Follows gd-snips design principles
7. ✅ Error handling and debugging support
8. ✅ Performance acceptable for game development use cases

---

## References

- [CLAUDE.md](../../CLAUDE.md) - Architectural decisions and patterns
- [Godot Documentation](https://docs.godotengine.org/)
- Dependency Injection patterns (in general software engineering)

---

**Next Steps:**
1. Review and refine plan
2. Start Phase 1 implementation
3. Create initial addon structure
4. Implement core Container class

