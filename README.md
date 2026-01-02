# 🎮 Godot Snips

A personal collection of packages and utilities for tinkering with **Godot 4.5.1+**

## 📦 Packages

### 📨 Messaging

Lightweight, type-safe messaging system with commands and events for decoupling game components.

- ✨ **Command Bus** — Single-handler routing with result returns
- 🎯 **Event Bus** — Multi-subscriber support with priority ordering
- 🔒 **Type-Safe** — Compile-time message type checking with explicit type annotations
- ⚡ **Async Support** — Built-in async/await capabilities
- 🎚️ **Priority System** — Control subscriber execution order
- 🔌 **Middleware** — Intercept and transform messages before/after delivery
- 📊 **Performance Metrics** — Built-in timing and counting for profiling
- ✅ **Best Practices** — Follows Godot style guide and conventions

**[📖 Messaging Docs →](messaging/README.md)**

## 🛠️ Shared Utilities

The project includes shared utility functions that can be used across packages:

- **`utilities/collection_utils.gd`** — Generic array and dictionary manipulation utilities
  - Cleanup patterns for managing collections in dictionaries
  - Safe array removal with automatic key cleanup

These utilities are designed to be reusable across different packages in this collection.

**[📖 Utilities Docs →](utilities/README.md)**

## 📝 Developer Diary

Development insights and architectural decisions are documented in the [developer diary](docs/developer-diary/):

- [Naming Refactoring & Architecture Deep Dive](docs/developer-diary/2026-01-02-naming-and-architecture-deep-dive.md) — January 2, 2026
- [Utility Extraction Refactoring](docs/developer-diary/2026-01-03-utility-extraction-refactoring.md) — January 3, 2026

These entries document the thought process behind design decisions and refactoring work.