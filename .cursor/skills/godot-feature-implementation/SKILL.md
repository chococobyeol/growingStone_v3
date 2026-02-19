---
name: godot-feature-implementation
description: Implements and reviews Godot gameplay features with scene/node/script safety checks. Use when adding or modifying scenes, nodes, signals, resources, autoloads, or gameplay logic in this Godot project.
---

# Godot Feature Implementation

## Use This Skill When

- User asks to add or modify Godot features.
- Work touches `.tscn`, GDScript/C#, autoloads, input mapping, or resource loading.
- Need safe change flow for scene-tree and signal updates.

## Default Workflow

1. Identify impacted scenes/scripts/autoloads first.
2. Apply minimal scene-tree changes required for the feature.
3. Wire signals explicitly and verify sender/receiver paths.
4. Validate load paths and exported properties.
5. Run a quick gameplay smoke check for touched loop.

## Scene and Node Rules

- Keep node names stable when possible to avoid broken paths.
- Prefer explicit node path checks before runtime-dependent logic.
- Avoid hidden side effects in `_ready()` that depend on uncertain order.
- If feature state is global, define ownership in one autoload only.

## Signal Safety

- Document what emits and what handles each new signal.
- Prevent duplicate connections on repeated scene entry.
- Handle null targets and missing nodes gracefully.

## Feature Completion Checklist

- [ ] Scene loads without missing resource or node path errors.
- [ ] Signal connections are deterministic and non-duplicated.
- [ ] Save/load or state restore logic remains valid after change.
- [ ] Core interaction path is tested manually once.
- [ ] Any new config/input is reflected in project settings if needed.

