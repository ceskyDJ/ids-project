# Notes for automatic data generation

**Installation:** `curl -sSL https://getsynth.com/install | sh`\
**Manual:** https://www.getsynth.com/docs/content/index

## Phases

Process of generating is divided into more phases. This way is used for adding more
semantic meanings to the generation process. For example it allows generating
students and lecturers without collisions.

### Phase 1

In this phase, students (not doctoral ones) are generated.

### Phase 2

In this phase, only rooms are generated. They are needed for the phase 3 and 4.

### Phase 3

In this phase, lecturers (not doctoral students) are generated.

### Phase 4

In this phase, doctoral students are generated.

### Phase 5

This is the last phase, where results from previous phases are combined and
remaining data are generated.

## Dependencies

User identifiers (`user_id`) need to start at number of identifiers generated
in the previous phases + 1.

## Custom functions

There are some custom defined functions. Here is a complete list in this document.

### `lower(value)`

Converts string in `value` to lower case.

### `inc(value)`

Increments number in `value` (adds 1).
