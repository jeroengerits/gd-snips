# Developer Diary: The Folder Structure Evolution

**Date:** January 3, 2026  
**Entry #:** 008  
**Focus:** Multiple folder structure refactorings - finding the right organization

---

## Context

Today was... interesting. I restructured the transport package folder structure *three times*. Not because I made mistakes. Not because I didn't plan. But because each iteration revealed something better.

It started simple: rename messaging to transport. Then flatten the nested folders. Then reorganize into a cleaner structure. Each step felt right at the time. Each step made the codebase better. But looking back, it's a lot of churn for one day.

The final structure:
```
packages/transport/
  types/      # Message, Command, Event, MessageTypeResolver
  utils/      # MetricsUtils
  events/     # broadcaster, registry, validator, bridge
  commands/   # router, validator
```

Four folders. Twelve files. Maximum one level deep. Clean. Simple. Done.

---

## Technical Observations

### The Three Iterations

**Iteration 1: The Semantic Rename**
```
messages/     # Instead of types/
pubsub/      # Instead of buses/
routing/     # Instead of routers/
validation/  # Instead of rules/
observability/ # Instead of utilities/
```

This was good. More semantic. But still had nested `internal/` folders. That felt wrong.

**Iteration 2: The Flattening**
Moved `messages/internal/message_type_resolver.gd` → `messages/message_type_resolver.gd`
Moved `pubsub/internal/subscription_registry.gd` → `pubsub/subscription_registry.gd`

Better. Flatter. But the folder names still didn't feel quite right.

**Iteration 3: The Final Structure**
```
types/    # Clear: these are types
utils/    # Clear: these are utilities
events/   # Clear: event-related stuff
commands/ # Clear: command-related stuff
```

And the files got shorter names:
- `event_broadcaster.gd` → `broadcaster.gd`
- `command_router.gd` → `router.gd`
- `subscription_registry.gd` → `registry.gd`
- `signal_event_adapter.gd` → `bridge.gd`

Why? Because when you're in the `events/` folder, you know it's about events. The file name doesn't need to repeat that.

### The Barrel File Pattern

The barrel file (`transport.gd`) saved us. Every time we moved files, every time we renamed folders, the public API stayed the same. External code never broke because they use `Transport.CommandRouter`, not `preload("res://packages/transport/routing/command_router.gd")`.

This is why barrel files exist. Not just convenience. Change isolation.

### The File Naming Thing

Short file names are better. `broadcaster.gd` is clearer than `event_broadcaster.gd` when it's already in `events/`. Context matters. The folder provides the context. The file name just needs to be specific enough.

It's like naming variables. `user` is fine if you're in a `UserService` class. You don't need `userServiceUser`. Same principle.

### The Validator Split

This was interesting. We had one `validation/` folder with two validators. Then we split them:
- `events/validator.gd` (SubscriptionValidator)
- `commands/validator.gd` (CommandValidator)

Why? Because validators belong with what they validate. `SubscriptionValidator` validates subscriptions, which are part of the event system. `CommandValidator` validates commands, which are part of the command system.

Co-location matters. If you're working on events, all the event-related code should be together.

---

## Personal Insights

### The "Just One More Refactor" Trap

I fell into it. "Just flatten the folders." "Just reorganize by domain." "Just rename the files." Each one made sense. Each one was an improvement. But three refactors in one day? That's... a lot.

The lesson: sometimes the first refactor isn't the last. And that's okay. But maybe next time, I'll think harder about the final structure before starting.

### The Naming Struggle

I spent way too long thinking about folder names. `events/` vs `pubsub/` vs `broadcasting/`. `commands/` vs `routing/` vs `handlers/`. 

The answer: pick one and move on. `events/` and `commands/` are fine. They're clear. They're short. They work. Perfect is the enemy of good.

### The Documentation Update

Updating documentation after refactoring is... necessary. But tedious. CLAUDE.md, README.md, examples, developer diary entries. All need updates. All need to reflect the new structure.

But here's the thing: if the documentation doesn't match the code, it's worse than no documentation. Misleading documentation is actively harmful. So you update it. Every time. Even when it's the third refactor of the day.

### The Git History

My git history today looks like chaos:
- Rename messaging → transport
- Move files to new folders
- Flatten nested folders
- Reorganize again
- Update all paths
- Update documentation

But from a user's perspective? They just see `Transport.CommandRouter.new()`. They don't care about the folder structure. They care about the API. And the API never changed.

That's the power of good abstractions.

---

## Future Considerations

### The Structure Stability Question

How many times can you refactor the folder structure before it becomes a problem? Three times in one day is probably too many. But each one was an improvement. So when do you stop?

My answer: when it feels right. When you look at the structure and think "yes, this makes sense." When new files have an obvious place to go. When the structure tells a story.

We're there now. `types/`, `utils/`, `events/`, `commands/`. That's the story. That's the structure. Done.

### The File Naming Convention

We now have a pattern:
- Short, descriptive names
- Context provided by folder
- Class names unchanged (stability)

Should this be documented? Probably. But not today. Today we refactor. Tomorrow we document patterns.

### The Barrel File Enforcement

The barrel file pattern works. Should we enforce it more strictly? Should we make it harder to import internal files directly?

My gut says: no. The current "soft enforcement" (just don't do it) is enough. If someone really needs to import an internal file, they can. But they'll know they're doing something unusual.

Trust developers. But make the right thing easy.

---

## Human Touch

### The Satisfaction of Simplicity

There's something deeply satisfying about a simple structure. Four folders. Twelve files. Everything has a place. Nothing is nested too deep. It's... clean.

It's like organizing a toolbox. You could have one big drawer with everything mixed together. Or you could have four drawers: "types", "utils", "events", "commands". The second is better. Not because it's more organized (though it is). But because it's easier to find things.

### The Refactoring Fatigue

Three refactors in one day is exhausting. Not physically. Mentally. Each one requires:
- Moving files
- Updating paths
- Verifying nothing broke
- Updating documentation
- Testing (if you have tests)

It's a lot. But each one made things better. So you keep going. Even when you're tired.

### The "Is This The Last One?" Question

After the second refactor, I asked myself: "Is this it? Or will I want to change it again tomorrow?"

The answer: probably not. But maybe? The structure feels right now. But structures evolve. And that's okay.

The goal isn't perfection. The goal is "good enough that I don't want to change it again for a while." And we're there.

### The Analogies

Folder structure is like city planning. You can organize by function (residential, commercial, industrial). You can organize by geography (north, south, east, west). You can organize by purpose (types, utils, events, commands).

The best organization depends on what you're trying to achieve. For code, organization by purpose (what it does) is usually better than organization by type (what it is).

`events/` tells you "this is about events." `pubsub/` tells you "this is about pub/sub." Both are true, but `events/` is clearer. It's the user-facing concept, not the implementation pattern.

---

## The Numbers

- **Refactors today:** 3
- **Files moved:** 12
- **Path updates:** 23+
- **Documentation files updated:** 3
- **Time spent:** Too much, but worth it
- **Regrets:** Zero

Sometimes you just have to iterate. Sometimes the first solution isn't the final solution. Sometimes you need to refactor three times to get it right.

And you know what? That's okay. The codebase is better for it. The structure is cleaner. The navigation is easier. The mental model is clearer.

Three refactors. One day. One better codebase.

That's a win.

