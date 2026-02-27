# Recon Checklist

## 1. Protection Triage

- Confirm architecture and bitness.
- Confirm NX, PIE, RELRO, canary, and fortify status.
- Confirm dynamic loader and linked libc details.

## 2. Attack Surface Mapping

- Locate externally reachable input functions.
- Locate output/format functions and uncontrolled format strings.
- Locate heap management paths (`malloc`, `free`, `realloc`).
- Locate parser/state-machine logic around attacker input.

## 3. Primitive Discovery

- Search for overflow boundaries (stack/heap/global buffers).
- Search for integer truncation/sign conversion paths.
- Search for arbitrary read/write candidates.
- Search for info leak opportunities (pointers, GOT, libc, stack).

## 4. Exploitability Rating

- Identify minimum required primitives (leak, write, control flow).
- Identify mitigation bypass requirements.
- Estimate exploit chain complexity and stability.

## 5. Reporting Shape

- Evidence: exact function names, addresses, and command outputs.
- Hypothesis: vulnerability class + trigger condition.
- Next step: concrete exploit objective for `solve.py`.
