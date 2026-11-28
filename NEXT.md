S0.5 task 1 done and merged (#12). Next: S0.5 task 2, the coastStartsFromHowTheGlobeWasMoving test. Open question: a ×2 zoom from a point off the globe swings the camera 48.6° at zoom 1; judge it on the phone once double-tap exists, then add a test.

## S0.5 task 2: checkpoints (stop after each and show)
Task 2 has not started and `s0.5-coast` does not exist yet. Same commit rule as task 1 (local commits, no push or merge, stop early if a test needs a spec change). Plan mode and an OK on the test list come first.

| # | Stop after | Show |
| --- | --- | --- |
| A | `coastStartsFromHowTheGlobeWasMoving`, `coastSlowsLikeAScrollView`, `coastIsTheSameInOneStepOrMany` | Failing and passing output, `git log --oneline`; total turn against ω × 0.4995 s |
| B | `slowReleaseDoesNotCoast`, `restingBeforeLiftDoesNotCoast`, `coastStopsBelowMinimumSpeed`, `fastFlingIsCapped`, `coastStopsTiltingAtThePole` | Failing and passing output, `git log --oneline`; measured speeds at each limit |
| C | UIKit drag and pinch, coast on screen, touch to stop, fingers landing or lifting, Reduce Motion for the coast | `check.sh` output, then the phone test |
| D | Double-tap, two-finger tap, double-tap-hold-slide, Reduce Motion for zooms, `NEXT.md` | `check.sh` output, then the phone test, including the off-globe zoom question |

## Gaps to settle before D: proposed, not decided
The numbers wait for the Project doc. Do not build them until they are there.
1. **Slide-zoom rate** (16.1 gives none): proposed ×2 per 100 pt slid, [tune].
2. **Ease-out curve** for the 0.3 s double-tap zoom (16.1 only says "easing out"): proposed cubic.
3. **Two JBGeo tests**, not in issue #11: `slideZoomDoublesEveryHundredPoints`, `doubleTapZoomEasesOutToTwice`.
