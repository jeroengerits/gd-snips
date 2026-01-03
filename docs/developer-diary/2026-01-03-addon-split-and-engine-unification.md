# Developer Diary: Addon Split and Engine Unification

**Date:** January 3, 2026  
**Entry #:** 012  
**Focus:** Splitting transport addon into separate addons and establishing Engine as the unified entry point

---

## Context

Today I completed a major refactoring: splitting the monolithic "transport" addon into separate, focused addons (event, command, message, middleware, utils) and renaming "core" to "engine" to establish it as the single, unified entry point for all gd-snips functionality.

This was a decision that had been brewing for a while. The transport addon was doing too much—it contained command handling, event broadcasting, message infrastructure, middleware, and utilities all in one place. While it worked, it violated the single responsibility principle and made the codebase harder to navigate.

## Technical Observations

### The Split Decision

The split wasn't just organizational—it was architectural. Each addon now has a clear, focused purpose:

- **event/** - Event broadcasting (one-to-many)
- **command/** - Command dispatching (one-to-one)
- **message/** - Base message infrastructure
- **middleware/** - Middleware infrastructure
- **utils/** - Generic utilities (metrics, signal tracking)
- **support/** - Array and string utilities (already separate)
- **engine/** - The unified entry point (meta-addon)

This separation makes dependencies explicit. Event and Command addons depend on Message and Middleware. Engine depends on everything. But now you can see those dependencies clearly in the structure.

### The Naming Conundrum

I spent way too much time debating "core" vs "engine" vs "snips" vs "main". 

"Core" felt generic and ambiguous—what does "core" even mean? It's the core of what? 

"Engine" clicked better. It's the engine that powers everything else. It's the entry point that makes all the parts work together. When you import Engine, you get access to all the functionality. It's like the engine of a car—you don't interact with each component individually, you start the engine and everything works.

I'm still not 100% sure "Engine" is perfect, but it's better than "Core". And honestly, at some point you have to stop debating and just pick something.

### Barrel File Constants: The Great Shortening

One of the more satisfying changes was shortening the barrel file constants:

- `EventBus` → `Bus`
- `CommandBus` → `Bus`
- `EventSignalBridge` → `SignalBridge`
- `CommandSignalBridge` → `SignalBridge`
- `CommandRoutingError` → `RoutingError`

This creates a cleaner API: `Engine.Event.Bus` instead of `Engine.Event.EventBus`. The context (`Engine.Event`) already tells you it's an event bus, so the extra "Event" prefix was redundant.

This follows the principle of removing redundancy. If the context makes something clear, don't repeat it in the name. It's like naming a function `get_user_name()` when you're already in a `User` class—just call it `name()`.

### Git's Rename Detection: A Miracle

Git's rename detection made this refactoring so much cleaner. I moved files around extensively, but Git tracked them as renames instead of "delete + add". The commit history is clean and readable. 

Watching Git correctly identify that `addons/transport/src/event/event_bus.gd` became `addons/event/src/event_bus.gd` felt like magic. It's these small things that make tooling good.

## Personal Insights

### The Documentation Paradox (Again)

Splitting the addons was straightforward. The code moves cleanly—just copy files, update imports, done. 

But updating the documentation? That's where the real work is.

I spent more time updating README.md and CLAUDE.md than I did on the actual code changes. Every code example needed updating. Every reference to "Transport" needed to become "Event" or "Command". Every import path needed checking.

And the worst part? Documentation updates aren't "done" in the same way code is. You can always find another example that needs updating, another explanation that could be clearer, another section that's slightly inconsistent.

At some point you have to say "good enough" and move on. But it's hard. The perfectionist in me wants to review every single line.

### Breaking Changes: The Necessary Evil

This refactoring introduced breaking changes. The transport addon no longer exists. Import paths changed. API structure changed.

I documented all the changes, but breaking changes always feel uncomfortable. You're disrupting people's workflows, even if it's for good reasons.

The saving grace is that this is still early in the project's lifecycle. Better to make these changes now when there are fewer users (if any) than later when the API is more established.

### The Joy of Clean Structure

After the split was complete, I opened the `addons/` directory and just... looked at it. It's beautiful. Each addon has its own folder, its own purpose, its own barrel file. The structure tells a story about how the code is organized.

Compare that to the old structure where everything was nested inside `transport/src/`. You'd open that directory and see a wall of subdirectories. Where does something belong? Where do I find what I need? It was overwhelming.

Now it's obvious. Need event handling? Look in `event/`. Need commands? Look in `command/`. Need utilities? Look in `utils/`. The structure is self-documenting.

## Future Considerations

### Should Individual Addons Be Usable Alone?

Right now, the addons are designed to work together through Engine. But could someone use just the Event addon without the others? 

Technically, yes—they'd need to also include Message and Middleware as dependencies. But is that a use case we want to support? 

For now, I'm saying "no". Engine is the supported entry point. Individual addon imports are an implementation detail. This keeps things simple and ensures consistency.

But I'm leaving the door open. If someone has a legitimate use case for using addons individually, we can document that path. For now, YAGNI applies.

### Versioning Strategy

With separate addons, versioning becomes more interesting. Should all addons version together? Or can they version independently?

For now, I'm keeping them in lockstep. All addons are at 0.0.1. When we hit 1.0.0, we'll version everything together.

But as the project grows, independent versioning might make sense. Event addon at 1.2.0, Command at 1.1.0, etc. That's a problem for future me.

### Documentation as Architecture

One thing this refactoring reinforced: documentation is architecture. 

When I split the addons, the README had to be completely restructured. The old structure (one big "Transport Addon" section) no longer made sense. I needed separate sections for Event and Command addons.

But more than that, the documentation structure *revealed* architectural decisions. Writing the documentation forced me to think about how users would discover and use the addons. That thinking improved the actual structure.

Documentation isn't just describing what exists—it's a design tool for understanding how things should be organized.

## Human Touch

### The Refactoring High

There's something deeply satisfying about a good refactoring. You start with something that works but feels messy. You move things around, rename things, reorganize. And at the end, you have something that's not just cleaner—it's *obviously* better.

The code does the same thing, but now it makes more sense. The structure tells a clearer story. Future developers (including future me) will have an easier time understanding it.

That feeling—the refactoring high—is what keeps me going. It's like cleaning your room. It's tedious work, but when you're done, you can't help but feel better about everything.

### The Naming Anxiety

I spent way too much time worrying about names. "Engine" vs "Core" vs "Main" vs "Snips". "EventBus" vs "Bus". "CommandRoutingError" vs "RoutingError".

Names matter. They're the primary way we communicate intent. A good name makes code self-documenting. A bad name creates confusion.

But at some point, you have to stop. You have to pick something and move on. Perfect is the enemy of good, and all that.

I chose "Engine" and "Bus" and "RoutingError". Are they perfect? Probably not. Are they good enough? Absolutely. And that's what matters.

### Git: The Unsung Hero

This refactoring involved moving dozens of files, renaming directories, updating hundreds of import statements. Without Git's rename detection, this would have been a nightmare. The commit would have shown everything as "deleted + added" instead of "renamed", making the history useless.

But Git figured it out. It tracked the moves. It showed a clean diff. It made the refactoring look intentional and organized, not chaotic.

Sometimes the best tool is the one that gets out of your way. Git just worked, and that's exactly what you want from a tool.

---

**Reflection:** This refactoring felt like the right thing to do, even though it was a lot of work. The structure is cleaner, the code is more organized, and the documentation is more accurate. Sometimes you have to do the hard work upfront to make things easier later. This was one of those times.

