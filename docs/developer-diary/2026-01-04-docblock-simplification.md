# Developer Diary: Docblock Simplification

**Date:** January 4, 2026  
**Entry #:** 006  
**Focus:** Radically simplifying docblocks across the messaging package

---

## Context

Yesterday I enhanced all the documentation. Today I simplified it. That might seem contradictory, but it's not - yesterday I added *good* documentation. Today I removed *bad* documentation.

The docblocks had become verbose. Multi-paragraph explanations, multiple examples, detailed parameter descriptions, architecture notes, usage patterns - it was all there. And honestly? It was too much. When you have to scroll through 20 lines of documentation to find out what a method does, something's wrong.

So I went through every file and cut the fat. Removed the verbose explanations. Removed the multiple examples. Removed the detailed parameter docs. Kept only the essential one-liners that tell you what you need to know.

**The Numbers:**
- 13 files modified
- 827 lines removed
- 100 lines added
- Net: -727 lines of documentation

That's a lot of words that weren't saying much.

---

## Technical Observations

### The Verbosity Problem

Here's what the docblocks looked like before:

```gdscript
## Register a handler for a command type.
##
## Registers a handler function for the specified command type. If a handler
## already exists for this command type, it will be replaced. The handler will
## be called when [method dispatch] is invoked with a command of this type.
##
## **Handler Signature:** The handler should accept one parameter (the command
## instance) and return a [Variant] result. The handler can be async and return
## a [GDScriptFunctionState], which will be automatically awaited.
##
## @param command_type The command class (preferred) or [StringName] type identifier.
##   For best type resolution, use classes with [code]class_name[/code] defined.
## @param handler A [Callable] that takes the command instance and returns a result.
##   The handler signature should be: [code]func(cmd: CommandType) -> Variant[/code]
##
## @example Register handler:
##   bus.handle(MovePlayerCommand, func(cmd: MovePlayerCommand) -> bool:
##       player.position = cmd.target_position
##       return true
##   )
##
## @note This replaces any existing handler for the command type. To unregister,
##   use [method unregister].
func handle(command_type, handler: Callable) -> void:
```

And here's what it looks like now:

```gdscript
## Register handler for a command type (replaces existing).
func handle(command_type, handler: Callable) -> void:
```

The second version tells you everything you need to know: it registers a handler, and it replaces existing ones. The method signature tells you the rest.

**The Pattern:**

Good documentation answers three questions:
1. What does it do?
2. What are the important gotchas?
3. When would I use this?

The verbose version answered all three, but it also answered questions nobody was asking. The simplified version answers the essential questions and lets the code speak for itself.

### The Example Overload

I noticed something: we had multiple examples for almost every method. Basic usage, advanced usage, error handling, async patterns - it was all there. But here's the thing: if you need three examples to understand a method, maybe the method is too complex. Or maybe the examples are redundant.

**Before:**
```gdscript
## @example Basic usage:
##   const Messaging = preload("res://packages/messaging/messaging.gd")
##   var bus = Messaging.CommandBus.new()
##   bus.handle(MovePlayerCommand, func(cmd): ...)
##
## @example Async handler:
##   bus.handle(SaveGameCommand, func(cmd): await save_to_file(...))
##
## @example Error handling:
##   var result = bus.dispatch(UnknownCommand.new())
##   if result is CommandBus.CommandError: ...
```

**After:**
```gdscript
## Command bus: dispatches commands with exactly one handler.
```

The examples were helpful, but they belonged in the README or a tutorial, not in every method's docblock. The code itself is the best example.

### The Parameter Documentation Trap

We had detailed `@param` documentation for every parameter. But here's the thing: if your parameter names are good, you don't need to document them. `handler: Callable` is self-explanatory. `priority: int = 0` tells you what it is.

**Before:**
```gdscript
## @param event_type The event class (preferred) or [StringName] type identifier.
##   For best type resolution, use classes with [code]class_name[/code] defined.
## @param listener A [Callable] that receives the event instance.
##   Signature: [code]func(evt: EventType) -> void[/code]
## @param priority Priority for this listener. Higher values are called first. Default: [code]0[/code]
```

**After:**
```gdscript
## Subscribe to an event type.
```

The type system and parameter names tell the story. The docblock just needs to say what the method does.

---

## Personal Insights

### The Documentation Pendulum

I'm noticing a pattern in my work: I swing between verbose and concise documentation. Yesterday I added detail. Today I removed it. This isn't inconsistency - it's iteration. I'm finding the right balance.

**The Sweet Spot:**

Good documentation is like good code: it says what it needs to say, nothing more, nothing less. It's not about length - it's about clarity. A one-liner that's clear is better than a paragraph that's confusing.

### The Scannability Factor

When I was simplifying, I kept asking myself: "Can I scan this quickly and understand what it does?" If the answer was no, I simplified further. Documentation should be scannable. You should be able to glance at it and get the gist.

**Before:** You had to read through paragraphs to find the essential information.  
**After:** The essential information is right there, immediately.

This is especially important in an IDE where docblocks appear in tooltips. Nobody wants to read a novel in a tooltip.

### The "But What If?" Problem

I found myself hesitating to remove some documentation. "But what if someone doesn't understand async behavior?" "But what if they don't know about priority ordering?" "But what if..."

Here's the thing: if someone doesn't understand async behavior, they need to learn GDScript, not read my docblocks. If they don't understand priority ordering, they can look at the code or read the README. The docblock shouldn't be a tutorial.

**The Principle:**

Document the non-obvious. Don't document the obvious. If it's in the method name or parameter types, you probably don't need to document it.

### The Satisfaction of Deletion

There's something deeply satisfying about deleting 727 lines of documentation. Not because I hate documentation (I don't), but because I'm making it better. Less is more. Fewer words, more clarity.

It's like editing a novel - the first draft has everything. The final draft has only what's necessary. Today I edited the documentation.

---

## Future Considerations

### Documentation Standards

I should probably write down some documentation standards. Not rules, but guidelines:

1. **One line for simple methods** - If the method name and signature are clear, one line is enough
2. **One paragraph for complex methods** - If there's a non-obvious gotcha, explain it briefly
3. **Examples in README** - Keep examples out of docblocks, put them in tutorials
4. **Trust the type system** - If types are clear, don't document them
5. **Document the "why" not the "what"** - The code shows what it does, docs explain why

### The README as Documentation

I'm realizing that the README should be the primary documentation. Docblocks should be quick references. If someone needs to understand how the system works, they should read the README. If they just need to know what a method does, the docblock should tell them.

This is a shift in thinking: docblocks aren't tutorials, they're reference material.

### Documentation Maintenance

Now that the docblocks are simpler, they're easier to maintain. Less to update when code changes. Less to get out of sync. Less cognitive load.

But I still need to keep them in sync. When I change a method, I need to update its docblock. The difference is that updating a one-liner is easier than updating a paragraph.

### The Tooltip Test

I'm going to start testing docblocks in tooltips. If a docblock doesn't fit in a tooltip without scrolling, it's too long. IDE tooltips are where most developers see documentation, so they should be optimized for that context.

---

## Human Touch

### The "Wait, That's It?" Moment

When I finished simplifying, I looked at some of the docblocks and thought: "Wait, that's it? Just one line?" But then I realized: yes, that's it. That's all you need. The method name, the signature, and one line of explanation. Everything else is noise.

### The Fear of Under-Documentation

I had a moment of doubt: "Am I under-documenting now?" But then I remembered: the code is the documentation. The type system is the documentation. The method names are the documentation. The docblock is just a quick summary.

If someone needs more, they can:
- Read the code (it's well-written)
- Read the README (it has examples)
- Ask questions (I'm available)

The docblock doesn't need to be everything to everyone.

### The Clarity Paradox

Here's something interesting: verbose documentation can actually make things less clear. When you have to read through paragraphs to find the essential information, you're working harder, not smarter. Concise documentation forces you to be clear about what's important.

**The Test:**

If you can't explain what a method does in one sentence, maybe the method is too complex. Or maybe you're overthinking it.

### The Iteration Mindset

I'm learning that documentation, like code, benefits from iteration. Write it verbose first (get everything down), then simplify (remove what's not needed). Yesterday I wrote. Today I edited. Both steps were necessary.

---

## Code Snippets That Tell a Story

### Before: Verbose
```gdscript
## Publish an event to all subscribers.
##
## Publishes the event to all registered listeners sequentially in priority order
## (higher priority listeners are called first). All listeners are called, even
## if some throw errors (GDScript has no try/catch, so errors will propagate).
##
## **Async Behavior:** Async listeners are automatically awaited to prevent
## [GDScriptFunctionState] memory leaks. This means this method may block briefly
## if listeners are async, even though it doesn't return a value. If you need
## to wait for async listeners to complete and handle their results, use
## [method publish_async] instead.
##
## **Non-Blocking:** For truly non-blocking behavior from a Node context, you
## can defer the publication:
##   [code]call_deferred("_publish_deferred", event_bus, evt)[/code]
##
## **One-Shot Subscriptions:** One-shot subscriptions are automatically removed
## after delivery, but removal happens after all listeners have been called.
##
## @param evt The [Event] instance to publish. Must not be [code]null[/code] and
##   must be an instance of an [Event] subclass.
##
## @note This method is async-safe and will await async listeners. Always use
##   [code]await[/code] when calling this method, even if all listeners are sync.
##
## @example Publish event:
##   var evt = EnemyDiedEvent.new(42, 100)
##   await bus.publish(evt)
##
## @example Non-blocking from Node:
##   func _on_button_pressed():
##       var evt = ButtonPressedEvent.new(button_id)
##       call_deferred("_publish_deferred", event_bus, evt)
##
##   func _publish_deferred(bus: EventBus, evt: Event):
##       await bus.publish(evt)
func publish(evt: Event) -> void:
```

### After: Concise
```gdscript
## Publish event to all subscribers.
func publish(evt: Event) -> void:
```

The second version is 20 lines shorter and tells you everything you need to know. The method name says "publish", the parameter says "event", the docblock says "to all subscribers". Done.

### The Class Documentation

**Before:**
```gdscript
## Base class for all messages in the messaging system.
##
## Messages are immutable value objects that carry data between systems. They
## represent both commands (imperative actions) and events (notifications).
## Messages are configured via their constructor and cannot be modified after
## creation, ensuring thread-safety and predictable behavior.
##
## **Key Features:**
## - Immutable data carrier
## - Content-based identity (value object pattern)
## - Unique ID generated from type and data
## - Type-safe routing support
## - Dictionary-based payload storage
##
## **Identity:** Messages use content-based identity - two messages with the
## same type and data will have the same identity (ID). This makes them suitable
## for value object patterns and allows for deduplication if needed.
##
## **Extensibility:** You can extend this class directly for generic messages,
## or extend [Command] or [Event] for domain-specific message types.
##
## @example Direct instantiation:
##   var msg = Message.new("damage", {"amount": 10, "target": player})
##   var msg2 = Message.create("heal", {"amount": 5}, "Heal message")
##
## @example Subclassing for type safety:
##   extends Message
##   class_name DamageMessage
##
##   var amount: int
##   var target: Node
##
##   func _init(damage_amount: int, target_node: Node) -> void:
##       amount = damage_amount
##       target = target_node
##       super._init("damage", {"amount": amount, "target": target})
##
## @note All messages extend [RefCounted] and are automatically memory-managed.
```

**After:**
```gdscript
## Base class for all messages.
```

The class name says "Message". The docblock says "base class for all messages". That's enough. The README can explain the details.

---

## Shower Thoughts

### The Documentation Lifecycle

I think documentation has a lifecycle:
1. **Write it verbose** - Get everything down, don't worry about length
2. **Use it** - See what questions people actually ask
3. **Simplify it** - Remove what nobody asks about
4. **Maintain it** - Keep it in sync with code changes

We're at step 3. Yesterday was step 1. Tomorrow will be step 4.

### The Information Hierarchy

I'm realizing there's a hierarchy of information:
1. **Method name** - Should tell you what it does
2. **Type signature** - Should tell you what it takes and returns
3. **Docblock** - Should tell you the non-obvious stuff
4. **Code** - Should show you how it works
5. **README** - Should explain the concepts

If information is at the wrong level, it's noise. Parameter details belong in the signature, not the docblock. Examples belong in the README, not the docblock.

### The Tooltip Optimization

IDE tooltips are where most developers see documentation. They're small, they're quick, they're contextual. Documentation should be optimized for tooltips, not for full-page reading.

If your docblock doesn't fit in a tooltip, it's too long.

### The "Good Enough" Principle

Perfect documentation doesn't exist. There's always more you could explain, more examples you could add, more edge cases you could cover. But at some point, you have to say "good enough" and move on.

Today I found "good enough" - one line that tells you what you need to know. Not everything you could know, just what you need.

---

## What I Learned

1. **Less is more** - Concise documentation is often clearer than verbose documentation
2. **Trust the code** - The code itself is documentation; docblocks are just summaries
3. **Scannability matters** - Documentation should be quick to scan, not deep to read
4. **Examples belong elsewhere** - Keep examples in READMEs and tutorials, not docblocks
5. **Iteration is key** - Write verbose, then simplify; both steps are necessary

---

## Next Steps

1. **Test in tooltips** - Make sure simplified docblocks work well in IDE tooltips
2. **Update README** - Ensure README has good examples since docblocks don't
3. **Documentation standards** - Write down guidelines for future documentation
4. **Monitor feedback** - See if simplified docs are actually helpful or if I went too far

---

## The Irony

Yesterday I spent hours adding documentation. Today I spent hours removing it. That might seem wasteful, but it's not - both steps were necessary. Yesterday I learned what needed to be documented. Today I learned what didn't.

The pendulum swings, but each swing gets you closer to the center.

---

**Final Thought:** Good documentation is like good code - it does exactly what it needs to do, nothing more, nothing less. Today I removed 727 lines of documentation and made the codebase clearer. Sometimes subtraction is addition.

