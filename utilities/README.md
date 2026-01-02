# Shared Utilities

Generic utility functions for use across multiple packages in this collection.

These utilities are domain-agnostic and designed for reuse. Package-specific utilities live in their respective `utilities/` folders.

## Design Principles

- **Generic over specific:** These utilities work with any domain logic
- **Type-safe:** Explicit type annotations throughout
- **Godot conventions:** Follows `snake_case` and static method patterns

## See Also

- [Messaging Package](../messaging/README.md) - Uses Collection internally
- [Collection Package](../collection/README.md) - Fluent array wrapper
- [Developer Diary: Utility Extraction](../docs/developer-diary/2026-01-03-utility-extraction-refactoring.md) - Background on utility design
