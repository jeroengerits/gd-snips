# Developer Diary: Code Review & Quality Improvements

**Date:** January 3, 2026  
**Entry #:** 004  
**Focus:** Comprehensive code review, critical bug fixes, and performance optimizations

---

## Context

Today I did something I should do more often: I asked an AI assistant to review my codebase as if it were going to production. Not a quick glance, but a deep, critical review from a senior developer's perspective. The result? A comprehensive code review document that identified real issues - some critical bugs, some performance problems, some documentation inconsistencies.

Then I fixed them. All of them. Well, all the critical ones anyway.

This was a **code quality day** - no new features, just making the codebase better, faster, and more reliable. The kind of work that doesn't show up in feature lists but makes everything else easier.

---

## Technical Observations

### The Metrics Bug That Wasn't Obvious

The review found a metrics recording bug in EventBus. We were recording metrics twice - once per listener and once for the overall operation. This is the kind of bug that's subtle because:

1. It doesn't crash anything
2. It doesn't produce wrong results immediately
3. The metrics still "work" - they're just wrong
4. You might not notice until you're trying to optimize and the numbers don't make sense

```gdscript
# Before (WRONG):
for sub in subs_snapshot:
    # ... call listener ...
    var listener_elapsed: float = (Time.get_ticks_msec() - listener_start_time) / 1000.0
    super._record_metrics(key, listener_elapsed)  # Records per-listener

# Later...
var elapsed: float = (Time.get_ticks_msec() - start_time) / 1000.0
super._record_metrics(key, elapsed)  # Overwrites with overall time
```

The fix was simple: just record the overall operation time. But finding it required someone to actually read the code carefully and think about what it does.

**Lesson:** Metrics bugs are insidious. They give you numbers, just not the right ones. Always validate your metrics logic, even if it "works".

### Type Resolution: The Collision Risk

This one was interesting. The type resolution system could produce different keys depending on how you passed a type:

- Pass the class: `MovePlayerCommand` → resolves via script path → `"move_player_command"`
- Pass an instance: `MovePlayerCommand.new(...)` → resolves via `get_class()` → `"MovePlayerCommand"`

Same type, different keys. Handlers wouldn't match. This is the kind of bug that works in testing (where you always use the same pattern) but breaks in production (where patterns vary).

The fix: prioritize `class_name` consistently across all resolution paths. Now both the class reference and instance resolve to the same key.

```gdscript
# Now consistently prioritizes class_name
if message_or_type is Object:
    var class_name_str: String = message_or_type.get_class()
    if class_name_str != "" and class_name_str != "Object":
        return StringName(class_name_str)  # Consistent!
```

**Lesson:** Type systems are only as good as their consistency. Edge cases matter.

### The "Fire-and-Forget" Lie

The documentation said `EventBus.publish()` was "fire-and-forget", but the implementation awaited async listeners to prevent memory leaks. This was contradictory and confusing.

The review called it out: "This is misleading. Either it's fire-and-forget or it's not."

I fixed it by removing the misleading terminology entirely. Now the docs say what it actually does: publishes sequentially, awaits async listeners to prevent leaks, may block briefly. Clear and honest.

**Lesson:** Documentation that contradicts implementation is worse than no documentation. Be honest about behavior, even if it's less convenient.

### Subscription Sorting: The O(n log n) to O(n) Win

This one made me smile. We were sorting the entire subscription array every time we added a subscriber. O(n log n) for what should be O(n).

The fix: insert in sorted position directly. Since subscriptions are already sorted, we just need to find the right spot and insert. O(n) insertion instead of O(n log n) sort.

```gdscript
# Before: O(n log n)
_subscriptions[key].append(sub)
SubscriptionRules.sort_by_priority(_subscriptions[key])

# After: O(n)
var insert_pos: int = subs.size()
for i in range(subs.size() - 1, -1, -1):
    if subs[i].priority >= priority:
        insert_pos = i + 1
        break
subs.insert(insert_pos, sub)
```

For small arrays, this doesn't matter much. But for high-frequency subscription/unsubscription patterns, this is a real win.

**Lesson:** Don't sort when you can insert. Maintain sorted order instead of sorting repeatedly.

### The SignalEventAdapter Memory Leak

SignalEventAdapter is a RefCounted utility that bridges Node signals to EventBus events. When it's freed, signal connections weren't being cleaned up. This causes memory leaks and crashes when source objects try to emit to dead callables.

The fix: Add `_notification(NOTIFICATION_PREDELETE)` to automatically disconnect all connections when the adapter is freed.

```gdscript
func _notification(what: int) -> void:
    if what == NOTIFICATION_PREDELETE:
        disconnect_all()
```

Simple fix, but important. Resource cleanup is one of those things that's easy to forget until you have a memory leak.

**Lesson:** Always think about cleanup. RefCounted objects don't automatically cleanup connections like Node objects do.

---

## Personal Insights

### The Value of External Review

Having someone (even an AI) review your code with fresh eyes is incredibly valuable. I found bugs I wouldn't have found myself because:

1. **I know what I meant** - I know the code is supposed to do, so I see what I expect
2. **I'm too close** - After writing code, you're mentally tired and miss things
3. **I have blind spots** - Every developer has patterns they repeat without questioning

The review found 7 critical issues. I probably would have found 2-3 of them eventually. The rest would have stayed hidden until they caused problems.

### The "Good Enough" Trap

Some of these bugs existed because the code "worked". It didn't crash, it produced results, it passed tests. So why fix it?

But "good enough" code accumulates technical debt. The metrics bug would have caused confusion later. The type resolution bug would have broken in edge cases. The memory leak would have caused crashes in long-running applications.

Fixing bugs before they cause problems is cheaper than fixing them after.

### The Joy of Clean Code

Fixing these bugs felt good. Not just because the code is better, but because:

1. **The code is more honest** - It does what it says, no contradictions
2. **The code is faster** - The sorting optimization is a real improvement
3. **The code is safer** - No memory leaks, consistent type resolution

Clean code is its own reward. It's easier to read, easier to maintain, easier to extend.

### Type Annotations: The Unsung Hero

Adding explicit `Variant` type annotations to Collection methods doesn't seem like a big deal. But it:

1. Improves IDE support (better autocomplete, error detection)
2. Makes the code self-documenting (you can see types without reading docs)
3. Helps catch bugs at development time

This is the kind of improvement that pays dividends every time you use the code.

---

## Future Considerations

### Message Class Over-Engineering

The review pointed out that the `Message` class includes identity generation and value object equality that might be over-engineered for a base class. This is worth considering - do we really need `_id`, `equals()`, and custom `hash()` for every message?

**Thought:** If subclasses need identity, they can implement it. Keep the base class simple.

### Command/Event Base Classes

The review questioned whether `Command` and `Event` base classes add enough value. They mostly just wrap `Message` without adding meaningful functionality.

**Options:**
1. Remove them and use `Message` directly with type checking
2. Make them useful by adding validation logic
3. Keep them for semantic clarity (commands vs events)

I'm leaning toward option 3 for now - the semantic distinction is valuable even if the implementation is simple. But it's worth revisiting.

### Unit Testing

The review suggested adding proper unit tests. Currently, we have integration tests but no unit tests. This would be valuable for:

- Testing type resolution edge cases
- Testing subscription lifecycle
- Testing metrics accuracy
- Testing error handling

**Next step:** Set up a proper testing framework and add unit tests for critical paths.

### Performance Profiling

The review suggested adding built-in performance warnings (e.g., warn if a handler takes > 1 frame). This would help catch performance issues during development.

**Idea:** Add a `set_slow_handler_threshold()` method that warns when handlers exceed a time threshold.

---

## Human Touch

### The Review Process

Going through the code review was like having a senior developer look over my shoulder. Some comments were "ouch, yeah, that's a bug." Others were "hmm, that's a design decision, let me think about it."

But all of it was valuable. Even the design critiques made me think harder about the architecture.

### The "Aha!" Moments

Some fixes were obvious once pointed out (the metrics bug). Others required thinking (the type resolution fix). The sorting optimization was a "why didn't I think of that?" moment.

Those moments are what make code reviews valuable - not just finding bugs, but learning better ways to write code.

### The Satisfaction of Cleanup

There's something satisfying about fixing bugs and improving code quality. It's like cleaning your room - it doesn't add new stuff, but everything is easier to find and use.

After this work, the codebase feels more solid. More reliable. More maintainable. That's worth the effort.

### The Documentation Honesty

Removing "fire-and-forget" from the documentation felt good. It was honest. The code does what it does, and now the docs reflect that accurately. No marketing speak, no misleading promises - just clear, accurate documentation.

This is the kind of honesty that builds trust with users (and future developers, including myself).

---

## Questions for Future Me

1. **How often should we do code reviews?** This one was comprehensive and found real issues. Should we do this quarterly? After major features? Continuously?

2. **Should we automate any of these checks?** Some of the issues (type annotations, cleanup patterns) could be caught by linters or static analysis tools.

3. **When is "good enough" actually good enough?** We fixed all critical bugs, but left some design decisions unchanged. Where's the line between perfectionism and pragmatism?

4. **How do we maintain code quality as the codebase grows?** This review was manageable because the codebase is still relatively small. Will we be able to do this when it's larger?

5. **Should we require code reviews for all changes?** Even for small fixes? Or only for major features?

---

## Closing Thoughts

Today was a quality improvement day. No new features, just making the codebase better. And it feels good.

The code review process was eye-opening. It found real bugs, real performance issues, real documentation problems. And fixing them made the codebase more solid, more reliable, more maintainable.

This is the kind of work that doesn't show up in feature lists, but makes everything else easier. It's the foundation work that lets you build confidently.

The codebase is better today than it was yesterday. And that's enough.

---

**Related Commits:**
- `8d796f2` - fix: resolve critical bugs and improve code quality
- `98dffeb` - docs: remove remaining 'fire-and-forget' terminology from inline comments

**Files Changed:** 8 files, 157 insertions(+), 70 deletions(-)

**Time Invested:** Worth it. ✅

