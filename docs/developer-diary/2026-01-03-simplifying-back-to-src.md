# Developer Diary: Simplifying Back to src/

**Date:** January 3, 2026  
**Entry #:** 013  
**Focus:** Moving packages back from addons/ to src/ and removing plugin.cfg files

---

## Context

Just a few hours ago, I completed a major refactoring: extracting all packages from `src/` into standalone Godot addons in `addons/` with `plugin.cfg` files. It was a well-thought-out plan, executed in phases, with proper dependency management. And now... I'm reversing it.

Why? Sometimes the simplest solution is the right one.

## The Realization

The addon structure was elegant in theory. Each package as a standalone addon with `plugin.cfg` files. Clear dependency levels. Proper Godot addon recognition. It checked all the boxes for "best practices."

But here's the thing: **this isn't a library meant for distribution through the Godot Asset Library.** It's a collection of reusable packages for my own projects. The overhead of managing addon configurations, the complexity of explaining dependency levels to users, the extra documentation needed... it was solving a problem I didn't have.

The `plugin.cfg` files? They were just sitting there, doing nothing useful. Godot doesn't need them for code that's just copied into a project. The addon structure? Overkill for a simple game project layout.

## Technical Observations

### The Simplicity Principle

Moving everything back to `src/` took about 5 minutes:
1. `git mv addons/* src/`
2. `git rm src/*/plugin.cfg`
3. `sed -i 's|res://addons/|res://src/|g' **/*.gd`
4. Update README

That's it. No complex dependency management. No plugin configuration. Just... code in folders.

### What We Lost (And Why It's Fine)

- **Addon recognition**: Not needed - users copy the `src/` folder, not installing via Godot's addon system
- **Plugin configuration**: Not needed - no editor plugins, no special configuration
- **Dependency documentation**: Simplified - everything is in `src/`, use `Engine` barrel file

### What We Gained

- **Simplicity**: One folder structure, clear and obvious
- **Less documentation**: No need to explain addon installation, plugin.cfg, dependency levels
- **Faster onboarding**: "Copy `src/` folder" is easier than "Copy `addons/` and `src/` folders, understand dependencies..."
- **Less cognitive load**: No need to think about "is this an addon or a package?"

## Personal Insights

### The YAGNI Principle Strikes Again

"You Aren't Gonna Need It" - one of the most valuable principles in software development. I built an addon system because it seemed like the "right" way to do things. But I wasn't actually going to need it. The packages work perfectly fine as regular folders in `src/`.

### The Cost of "Best Practices"

Sometimes "best practices" add complexity without adding value. The addon structure was more "correct" according to Godot conventions, but it made the project harder to understand and use. For a personal project collection, simplicity wins.

### The Courage to Reverse

It takes courage to undo work, especially work that was done well. But recognizing when you've over-engineered something is a valuable skill. The refactoring to addons was well-executed, well-documented, and completely unnecessary for my use case.

## Technical Details

The move was straightforward:
- All 7 packages moved from `addons/` to `src/`
- All `plugin.cfg` files removed (7 files)
- All preload paths updated: `res://addons/` → `res://src/`
- README simplified significantly
- `engine.gd` still works as the barrel file

The structure is now:
```
src/
├── command/
├── event/
├── message/
├── middleware/
├── subscribers/
├── support/
├── utils/
└── engine.gd
```

Clean. Simple. Obvious.

## Future Considerations

### When Would Addons Make Sense?

Addons would make sense if:
- Distributing via Godot Asset Library
- Creating editor plugins
- Need Godot's addon enable/disable system
- Multiple projects need different versions

None of these apply to my use case. So `src/` it is.

### The Lesson

Don't add structure until you need it. Start simple. Add complexity only when it solves an actual problem. The addon structure solved a problem I didn't have.

## Human Touch

I'm not embarrassed about reversing the refactoring. In fact, I'm proud of it. Recognizing when you've over-engineered something and having the courage to simplify is a mark of good engineering judgment.

The addon refactoring was good practice. I learned about Godot's addon system, dependency management, and plugin configuration. But sometimes the best learning is realizing what you don't need.

The codebase is now simpler, easier to understand, and perfectly suited to its purpose. That's a win.

---

**Post-script:** Sometimes the best refactoring is the one you undo. Simplicity is a feature.

