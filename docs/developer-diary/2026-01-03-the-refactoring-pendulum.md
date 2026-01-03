# Developer Diary: The Refactoring Pendulum

**Date:** January 3, 2026  
**Entry #:** 014  
**Focus:** Reflecting on the addon extraction and simplification journey

---

## Context

Today has been... interesting. I spent hours carefully extracting all packages from `src/` into standalone Godot addons with `plugin.cfg` files, documenting dependencies, creating a beautiful dependency graph, writing comprehensive installation instructions. And then, a few hours later, I moved everything back to `src/` and deleted all the `plugin.cfg` files.

This isn't a failure. This is a lesson.

## The Journey

### Morning: The Extraction

I woke up with a plan. The codebase had all packages in `src/`, but they *should* be proper Godot addons. That's the "right" way, right? So I:

1. Extracted packages in phases (Level 0 → Level 1 → Level 2)
2. Created `plugin.cfg` files for each addon
3. Updated all paths meticulously
4. Wrote documentation explaining dependency levels
5. Created troubleshooting guides
6. Committed with a detailed message

It was beautiful. Clean. Professional. Each addon was self-contained. The dependency graph was clear. Users could install individual addons. It checked all the "best practices" boxes.

### Afternoon: The Realization

Then I looked at what I'd built and asked: "Do I actually need this?"

The answer was no.

This isn't a library for the Godot Asset Library. It's not distributed as separate packages. It's a collection of reusable code I copy into my projects. The `plugin.cfg` files? They do nothing for me. The addon structure? Adds complexity without value.

So I reversed it. Moved everything back. Deleted the config files. Simplified the README. And you know what? It's better.

## Technical Observations

### The Sed Command That Saved Hours

When moving packages back, I used:
```bash
find src -name "*.gd" -type f -exec sed -i '' 's|res://addons/|res://src/|g' {} \;
```

One command. Updated 47+ files. Git tracked it perfectly. Sometimes the simplest tools are the best.

### Git History Preservation

Using `git mv` instead of `mv` + `git add` preserved file history. When I look at `git log --follow src/command/command.gd`, I can see its entire journey:
- Started in `src/`
- Moved to `addons/`
- Moved back to `src/`

The history tells a story. That's valuable.

### The Barrel File Pattern

The `Engine` barrel file (`src/engine.gd`) is the hero of this story. It provides a stable API regardless of where packages live:

```gdscript
const Engine = preload("res://src/engine.gd")
var command_bus = Engine.Command.Bus.new()
```

Whether packages are in `addons/` or `src/`, users write the same code. The barrel file abstracts away the structure. This is why architectural patterns matter - they provide stability during refactoring.

## Personal Insights

### The YAGNI Wake-Up Call

"You Aren't Gonna Need It" - I've read this principle a hundred times. Today I lived it.

I built an addon system because it seemed "right." But I wasn't solving a real problem. I was solving a theoretical problem. The addon structure would be valuable if:
- I was distributing via Asset Library (I'm not)
- I needed editor plugins (I don't)
- Multiple projects needed different versions (they don't)
- Users needed to enable/disable addons (they don't)

None of these apply. So the structure was solving problems I didn't have.

### The Courage to Simplify

It's harder to simplify than to add. Adding structure feels like progress. Removing structure feels like regression. But sometimes the best refactoring is the one you undo.

I'm not embarrassed about reversing the work. I'm proud of it. Recognizing over-engineering and having the courage to simplify is a mark of good judgment.

### Documentation as a Mirror

Writing documentation forced me to confront the complexity. When I tried to explain the addon installation process, I realized how convoluted it was:

"Copy `addons/` and `src/` folders. Understand dependency levels. Install Level 0 packages first, then Level 1, then Level 2. Make sure plugin.cfg files are present..."

Compare that to:
"Copy `src/` folder."

The simpler documentation revealed the simpler solution.

## Future Considerations

### When Would Addons Make Sense?

I'm not saying addons are always wrong. They'd make perfect sense if:
- **Asset Library distribution**: Publishing individual packages
- **Editor plugins**: Creating Godot editor tools
- **Version management**: Different projects need different versions
- **Selective installation**: Users only want specific packages

For my use case? None of these apply. So `src/` it is.

### The Lesson for Future Me

Don't add structure until you need it. Start simple. Add complexity only when it solves an actual problem. "Best practices" are contextual - what's best for a library might be wrong for a personal project collection.

### The Barrel File Strategy

The `Engine` barrel file is brilliant. It provides:
- **Stability**: Users don't care where packages live
- **Simplicity**: One import, access to everything
- **Flexibility**: Can reorganize without breaking user code

This pattern is worth keeping regardless of structure.

## Human Touch

### The Refactoring Pendulum

I've heard of "refactoring pendulum" - swinging between extremes before finding balance. Today I lived it:

1. **Too simple**: Everything in `src/` (original state)
2. **Too complex**: Addons with dependencies and configs (this morning)
3. **Just right**: Everything in `src/` but with better organization (now)

The difference between #1 and #3? Experience. I learned about addons, dependencies, and structure. Then I learned when not to use them.

### What Made Me Smile

When I ran `git status` after moving everything back, Git showed:
```
RM addons/command/command.gd -> src/command/command.gd
```

Git understood. It knew these were the same files, just moved. The tooling is good. That made me smile.

### The Shower Thought

Structure is a tool, not a goal. The goal is code that's easy to understand, maintain, and use. Sometimes that means more structure. Sometimes it means less. The skill is knowing which.

### The Analogy

Building an addon system for this project was like buying a commercial kitchen for a home cook. It's impressive. It's "professional." But you're making pasta for two. A simple pot works better.

## Code Quality Reflection

The code itself is good. The packages are well-organized. The barrel file pattern works. The structure change didn't affect code quality - it just changed where files live.

What changed was **developer experience**. The simpler structure is easier to:
- Understand (one folder, not two)
- Install (copy one folder, not two)
- Navigate (everything in `src/`)
- Document (less to explain)

Code quality stayed the same. Developer experience improved.

## The Meta-Lesson

Today I learned that learning sometimes looks like backtracking. The addon extraction wasn't wasted effort - it taught me:
- How Godot addons work
- How to manage dependencies
- How to structure documentation
- When not to use these tools

Sometimes the best way to learn what you need is to build what you don't.

---

**Post-script:** The refactoring pendulum swung, and I'm better for it. The codebase is simpler, and I understand when complexity is worth it. That's progress, even if it looks like going backwards.

