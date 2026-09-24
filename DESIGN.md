# Little Menace — design

Rebuilt from the owner brief. The original `DESIGN.md` and the generated raster mascot were not in this repository. The character here is a **vector placeholder** drawn in SwiftUI. The palette and character are provisional.

## Composition (home)

- One bold full-bleed colour, with a soft radial glow behind Crumb. Midnight adds stars.
- Crumb is centred, a little above the middle, at 72 % of the screen width (max 300 pt).
- Bottom row: three round buttons, 66 pt with 28 pt gaps:
  - **Feed** (cookie; drag it to Crumb or tap)
  - **Play** (opens a three-toy picker)
  - **Nap/Wake**

  A thin white ring on each button shows fullness, joy or energy.
- Top right: one `…` menu (Wardrobe, Stamps, Share, Settings). There are no labels, cards, badges or shop on the home screen.
- Transient only:
  - a speech bubble (≤ 32 characters, shown now and then, always on refusals)
  - a toast chip (icon + number) for level, stamp, gift or discovery
  - the mischief prop
  - the one-time reminder offer
- Asleep: the background dims 35 % and "z"s drift up.

## Tokens (`App/Style/Theme.swift`)

| Theme | Day | Night (dark mode) | Source |
|---|---|---|---|
| Tangerine (default) | `#FF7A2F` | `#B9480F` | starter |
| Grape | `#7B4DFF` | `#3F1FA6` | starter |
| Pool | `#14B0E0` | `#0A5F80` | starter |
| Bubblegum | `#FF6FB5` | `#A33570` | level 5 |
| Midnight | `#1D2560` | `#0D1236` + stars | Midnight Snack |

Ink:
- body `#241F33`
- belly `#3B3452`
- eye/cream `#FFF7EA`
- pupil `#120F1C`
- blush `#FF8FA3`

Type is SF Rounded heavy, used only in bubbles, toasts and numbers.

## Character rig (`App/Crumb`)

Crumb is drawn in a 200×220 design space from separate parts:
- tail, ears (with inner blush), arms, body, belly, feet
- eyes (white, pupil, highlight, lid arcs), brows, blush
- mouth (an animatable open/smile shape) with one fang
- wearables layered on top

`CrumbPose` holds 17 parameters: eye openness and happiness, brow tilt/lift/asymmetry, mouth open and smile, fang, blush, ear droop, squash/stretch, lean, hop, arms, tail wag, look direction, and sleeping.

Poses are values. SwiftUI springs between any two of them (response 0.38, damping 0.55), so reactions interrupt each other without snapping. A 30 fps timeline drives breathing, blinking (a double blink every third cycle) and tail wag.

| State | Pose |
|---|---|
| idle | relaxed half-grin, fang, slow breathing |
| attention | wide eyes, perked ears, stretch up, pupils follow the finger or snack |
| touch | ^ ^ squint, blush, big grin, squash, fast tail |
| feed | wide chomp, happy eyes |
| play | raised arms, lean, big eyes |
| sleepy | heavy lids, drooped ears, slow tail (automatic below 30 energy) |
| asleep | closed ‿ lids, squashed, ears flat, z's |
| wake / grumpy wake | stretch and yawn / cross brows, frown |
| mischief | one cocked brow, narrowed eyes, fang grin, lean |
| refuse food / nap, too sleepy, win, lose | dedicated poses |

Drag: the body stretches toward the finger through a rubber-band curve (limit 70 pt), and on release it springs back with overshoot. Collection reactions are sequences of poses (beats) plus a prop.

## Motion and accessibility

- **Reduce Motion**:
  - breathing and tail wag stop
  - pose changes cross-fade in 0.2 s instead of springing
  - the snack-toss sway is halved and slowed
  - cushion swaps are fewer and slower
  - the mischief prop doesn't bob
- **VoiceOver**:
  - Crumb is one element. Its value speaks its state (hungry, sleepy, bored, level). Its actions are pet (default), Feed, Nap/Wake and Tickle.
  - Speech lines and toasts are announced.
  - Every icon-only control has a label.
  - Each toy has an accessible path: throw action, pull action with a "Now!" cue, and cushions as labelled buttons.
- **Large text**: the little text there is uses Dynamic Type styles, so it grows and wraps.
- **Dark mode**: deeper night variants of each theme.

## Visual acceptance checks

1. Home shows exactly: background, Crumb, three buttons, `…`. No words at rest.
2. Crumb reads clearly on every theme, in light and dark mode, on iPhone SE and on Pro Max.
3. Tapping, dragging, feeding, refusing, napping and waking each look different, even with the sound off.
4. No layout clipping at the largest accessibility text size in the sheets.
5. With Reduce Motion on, nothing loops except the sleep z's.
