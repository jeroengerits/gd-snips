# Developer Diary: Utility Extraction Refactoring

**Date:** January 3, 2026  
**Entry #:** 002  
**Focus:** Extracting utility functions to reduce code duplication and improve maintainability

---

## Context

Today I worked on refactoring the messaging package to extract common patterns into reusable utility functions. This was a classic case of "I keep writing the same code three times, let's fix that."

The work involved:
1. Analyzing the codebase for duplication patterns
2. Classifying utilities as generic (shared) vs messaging-specific
3. Creating utility files with appropriate organization
4. Refactoring existing code to use the utilities
5. Updating documentation

It's satisfying work - the kind that makes the codebase cleaner without changing functionality. Pure improvement.

---

## Technical Observations

### The Analysis Phase

Started by doing a systematic search for patterns. Found three main areas:
1. **Time conversion** - Converting milliseconds to seconds (3 occurrences)
2. **Average time calculation** - Calculating average from metrics dict (2 occurrences)
3. **Array cleanup pattern** - Remove items, clean up dictionary key if empty (4 occurrences)
4. **Metrics initialization** - Creating empty metrics structure (1 occurrence)

The time conversion one was interesting. It's so simple (`ms / 1000.0`) that extracting it felt like over-engineering. I decided to skip it - sometimes the simplest code is fine as-is. Not everything needs to be extracted.

### The Classification Decision

This was the interesting part: where should utilities live?

I initially thought "just put them in `messaging/utilities/`" but then I realized some patterns are truly generic (array cleanup) while others are messaging-specific (metrics structure).

The solution: two-tier structure:
- `utilities/` - Generic utilities that could be used by other packages
- `messaging/utilities/` - Messaging-specific utilities tied to this package's data structures

This feels right. It's about reusability, not just organization. If it's useful elsewhere, it goes in the shared location. If it's tied to messaging's internals, it stays in messaging.

### The Refactoring

The actual refactoring was straightforward. The pattern was clear:
- Extract the logic to a utility function
- Replace inline code with utility call
- Verify behavior is unchanged

What surprised me was how much cleaner the code became. The `message_bus.gd` file went from having duplicate average calculation logic in two places to just calling `MetricsUtils.calculate_average_time(m)`. The intent is clearer now.

### Code Organization Patterns

I noticed we're establishing a pattern here:
- **Rules** (`rules/`) - Domain rules made explicit (CommandRules, SubscriptionRules)
- **Utilities** (`utilities/`) - Reusable helper functions
- **Internal** (`internal/`) - Implementation details

This feels like a good organizational structure. Each folder has a clear purpose, and it's easy to find things.

---

## Personal Insights

### The "Good Enough" Principle

The time conversion decision was interesting. Three occurrences of `(Time.get_ticks_msec() - start_time) / 1000.0`. Technically, this is duplication. But it's so simple that extracting it might make the code harder to read, not easier.

I decided to skip it. This is one of those judgment calls where "perfect" isn't better than "good enough." Sometimes the cure is worse than the disease.

### Classification is Hard

Figuring out what's "generic" vs "messaging-specific" required actual thought. The metrics utilities are clearly messaging-specific (they work with messaging's metrics dictionary structure). But the array cleanup pattern? That could be useful anywhere you're managing collections in dictionaries.

I ended up putting it in the generic location, which feels right. But it required thinking about the future, not just the present. "Will other packages need this?" is a useful question.

### Documentation Matters

After the refactoring, I updated the README to document the new utilities structure. But I also created a detailed analysis document (`refactoring-opportunities.md`) to plan the work.

Then, after everything was done, I deleted that analysis document. It served its purpose - it helped me think through the problem - but it's not useful anymore. The knowledge is now in the code and the README.

This feels like good hygiene. Keep planning documents during planning, but clean them up afterward. Don't let the workspace get cluttered with obsolete analysis.

### The Joy of Clean Code

There's something satisfying about seeing duplicate code become a single function call. It's like watching puzzle pieces fit together. The code becomes:
- More maintainable (change in one place)
- More testable (utilities can be tested independently)
- More readable (function name conveys intent)

This is why I enjoy refactoring. It's not about adding features - it's about making what exists better.

---

## Future Considerations

### Utility Growth

As more packages are added, I wonder if we'll need more generic utilities. Things like:
- Time utilities (maybe we will need that conversion function after all?)
- String manipulation
- Data validation helpers
- Collection operations

But YAGNI applies here. We'll extract utilities when we actually need them, not preemptively.

### Testing Utilities

The utilities are simple, pure functions. They're easy to test. But currently, there's no test file for them. Should we add unit tests?

On one hand, they're used by the messaging system, which has tests. On the other hand, utilities are good candidates for unit tests - they're isolated and have clear inputs/outputs.

I'm leaning toward "maybe later." The utilities are simple enough that integration tests might be sufficient. But if they grow in complexity, unit tests would make sense.

### Documentation of Utilities

Currently, the utilities are documented as "internal implementation details" in the README. But they're also documented with GDScript doc comments.

Should we create a utilities README? Probably not yet. The utilities are simple and well-documented inline. A README would be overkill unless we get many more utilities.

---

## Human Touch

### What Made Me Think

The classification decision made me think about code organization philosophy. When do you create a shared utility vs keeping it package-specific?

I think the answer is: when you can see it being useful in another context. Not "maybe someday it could be useful" but "if I was building another package right now, would I want this?"

The array cleanup pattern? Yeah, I'd want that in any package dealing with collections. The metrics utilities? No, those are messaging-specific.

This feels like a practical heuristic.

### The Cleanup Phase

After the refactoring, I deleted the `refactoring-opportunities.md` file. It was useful for planning, but now it's obsolete. The knowledge lives in:
- The code itself (the utilities)
- The README (documentation of the structure)
- This diary (the thought process)

Keeping obsolete planning documents around creates clutter. It's like leaving scaffolding up after the building is done. Clean up after yourself.

### Shower Thoughts

Utility functions are like spices in cooking. You don't notice them when they're used well - the code just tastes better. But when they're overused or misused, everything becomes bland or confusing.

The key is knowing when to extract and when to leave things inline. Too much extraction creates indirection. Too little creates duplication.

I think we hit a good balance today. We extracted real patterns, not just "this code appears twice."

### Analogies That Help

**Generic vs Package-Specific Utilities:**
Think of it like tools in a workshop:
- **Generic utilities** are like hammers and screwdrivers - useful for many projects, live in the main toolbox
- **Package-specific utilities** are like specialty tools - only useful for specific projects, live in that project's toolbox

You could use a hammer on many projects. But you probably only need a pipe wrench for plumbing projects.

**The Refactoring Process:**
Refactoring is like editing a document. You're not changing what it says, just how clearly it says it. The meaning stays the same, but the expression improves.

---

## Questions for Future Me

1. **Should we extract time conversion after all?** If we add more timing-related code, the extraction might make sense. But for now, leaving it inline feels right.

2. **Do we need unit tests for utilities?** They're simple pure functions, but unit tests would be easy to write. Integration tests might be enough for now, but worth reconsidering if utilities grow.

3. **How do we decide when to extract a new utility?** The current heuristic (3+ occurrences, clear pattern) seems reasonable. But what if we have 2 occurrences of a complex pattern? Should we extract earlier?

4. **Should generic utilities be exported?** Currently they're internal. But if other packages want to use them, should we create a public API? Or keep them internal and let packages copy what they need?

---

## Closing Thoughts

Today was a good refactoring day. I improved code quality without changing functionality. The codebase is cleaner, more maintainable, and better organized.

The utility extraction followed a clear pattern:
1. Identify duplication
2. Classify as generic vs specific
3. Extract to appropriate location
4. Refactor to use utilities
5. Document the changes
6. Clean up obsolete artifacts

This process feels repeatable. When we add more packages, we'll likely do similar work. And having a clear structure (generic vs package-specific utilities) will make those decisions easier.

The codebase continues to be a pleasure to work with. It's well-organized, thoughtfully designed, and now even cleaner.

---

*Next time I work on this codebase, I should consider whether the utilities need unit tests, especially if we add more complex utilities in the future.*

