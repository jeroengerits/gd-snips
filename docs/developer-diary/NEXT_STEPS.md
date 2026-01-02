# Next Steps Analysis

**Generated:** January 3, 2026  
**Based on:** Developer Diary Entries #001 & #002

---

## Current Status

✅ **Completed Work:**
- Naming refactoring (shorter, clearer method names)
- Architecture deep dive and documentation
- Utility extraction refactoring (generic vs messaging-specific)
- All changes committed and pushed to main

✅ **Codebase Health:**
- Clean working tree (no uncommitted changes)
- Well-organized structure (rules, utilities, internal, types)
- Comprehensive documentation
- No TODOs or FIXMEs found
- Production-ready code quality

---

## Priority Recommendations

### 🔴 High Priority (Address Soon)

#### 1. **Error Collection Feature Completion**
**From Diary Entry #001:**
- `EventBus` has `_errors` array declared but never used
- `set_collect_errors()` method exists but errors aren't actually collected
- This is planned functionality that was never implemented

**Action Items:**
- [ ] Investigate why error collection was never implemented (GDScript limitations?)
- [ ] Either implement error collection or remove dead code
- [ ] Update documentation to reflect decision
- [ ] Consider using `call_deferred` for error isolation if needed

**Estimated Effort:** 2-4 hours

#### 2. **Fire-and-Forget Documentation Clarification**
**From Diary Entry #001:**
- `EventBus.publish()` claims to be "fire-and-forget" but still awaits async listeners
- Comment acknowledges limitation: "this will still block, but it's the best we can do"
- Documentation could be clearer about this behavior

**Action Items:**
- [ ] Update README to clarify that `publish()` may block briefly for async listeners
- [ ] Document the difference between `publish()` and `publish_async()` more clearly
- [ ] Consider renaming or adding `publish_deferred()` for truly non-blocking events
- [ ] Add examples showing when to use each method

**Estimated Effort:** 1-2 hours

---

### 🟡 Medium Priority (Consider When Time Permits)

#### 3. **Unit Tests for Utilities**
**From Diary Entry #002:**
- Utilities are simple pure functions, easy to test
- Currently no test file for utilities
- Integration tests exist but unit tests would be valuable

**Action Items:**
- [ ] Create `utilities/test_collection_utils.gd`
- [ ] Create `messaging/utilities/test_metrics_utils.gd`
- [ ] Test edge cases (empty arrays, zero counts, etc.)
- [ ] Add to test suite documentation

**Estimated Effort:** 2-3 hours

#### 4. **Type Resolution Edge Case Documentation**
**From Diary Entry #001:**
- `MessageTypeResolver` handles various Godot type system quirks
- Fallback behavior might surprise users
- Should document edge cases and limitations

**Action Items:**
- [ ] Document type resolution behavior in README
- [ ] Add examples showing different type inputs
- [ ] Warn about edge cases (StringName vs String, script paths, etc.)
- [ ] Consider adding validation warnings for unexpected types

**Estimated Effort:** 1-2 hours

---

### 🟢 Low Priority (Future Enhancements)

#### 5. **True Fire-and-Forget Implementation**
**From Diary Entry #001:**
- Current "fire-and-forget" still blocks for async listeners
- Could implement `publish_deferred()` using `call_deferred`
- Question: Is the complexity worth it?

**Action Items:**
- [ ] Research if users actually need true fire-and-forget
- [ ] If needed, implement `publish_deferred()` method
- [ ] Document use cases and trade-offs
- [ ] Add performance considerations

**Estimated Effort:** 3-4 hours

#### 6. **Performance at Scale Analysis**
**From Diary Entry #001:**
- System works great for typical games
- Question: What about massive multiplayer games with thousands of events/second?
- Would we need batching? Queueing?

**Action Items:**
- [ ] Create performance benchmark tests
- [ ] Document performance characteristics
- [ ] Research if batching/queueing would be beneficial
- [ ] Add performance tips to README

**Estimated Effort:** 4-6 hours

#### 7. **Time Conversion Utility Reconsideration**
**From Diary Entry #002:**
- Three occurrences of `(Time.get_ticks_msec() - start_time) / 1000.0`
- Decided to skip extraction (too simple)
- Reconsider if more timing code is added

**Action Items:**
- [ ] Monitor for more timing-related code
- [ ] Extract if pattern appears 3+ more times
- [ ] Create `utilities/time_utils.gd` if needed

**Estimated Effort:** 1 hour (if needed)

---

## Questions to Resolve

### From Diary Entry #001:
1. **Should we implement true fire-and-forget?** 
   - Need user feedback or use case analysis
   - Current implementation might be sufficient

2. **Error collection in EventBus** 
   - Finish feature or remove dead code?
   - Investigate GDScript limitations first

3. **Type resolution fallback behavior**
   - Document edge cases or add warnings?
   - Current "best effort" approach might be fine

4. **Performance at scale**
   - Benchmark current performance
   - Research if optimizations needed

### From Diary Entry #002:
1. **Should we extract time conversion after all?**
   - Monitor for more occurrences
   - Extract if pattern grows

2. **Do we need unit tests for utilities?**
   - Yes, but low priority
   - Simple functions, integration tests might suffice for now

3. **How do we decide when to extract a new utility?**
   - Current heuristic (3+ occurrences, clear pattern) works
   - Consider extracting complex patterns earlier (2 occurrences)

4. **Should generic utilities be exported?**
   - Currently internal
   - Keep internal unless other packages need them
   - Can always refactor later

---

## Suggested Workflow

### Immediate Next Steps (This Week):
1. ✅ Review this analysis
2. 🔴 Address error collection feature (implement or remove)
3. 🔴 Clarify fire-and-forget documentation
4. 📝 Update developer diary with decisions made

### Short Term (This Month):
1. 🟡 Add unit tests for utilities
2. 🟡 Document type resolution edge cases
3. 📊 Gather user feedback on fire-and-forget needs

### Long Term (Future):
1. 🟢 Implement true fire-and-forget if needed
2. 🟢 Performance benchmarking and optimization
3. 🟢 Monitor utility extraction opportunities

---

## Code Quality Observations

### Strengths:
- ✅ Clean architecture with clear separation of concerns
- ✅ Well-documented with honest comments
- ✅ Domain rules made explicit (Rules classes)
- ✅ Good naming (after refactoring)
- ✅ Type-safe with comprehensive annotations
- ✅ No technical debt markers (TODOs/FIXMEs)

### Areas for Improvement:
- ⚠️ Incomplete features (error collection)
- ⚠️ Documentation gaps (fire-and-forget behavior)
- ⚠️ Missing unit tests for utilities
- ⚠️ No performance benchmarks

---

## Notes

- The codebase is in excellent shape overall
- Most recommendations are about documentation and completeness, not fixing problems
- The developer diary shows thoughtful consideration of trade-offs
- "Good enough" principle is being applied appropriately
- No urgent issues or technical debt

---

*This analysis should be reviewed and updated as work progresses. Consider creating a new developer diary entry when addressing these items.*

