#!/bin/bash
# Screenshot tour for review: every screen and interaction state, numbered in review order.
# Usage: scripts/screenshot-tour.sh <a|b|store|new> <path/to/LittleMenace.app> <out-dir>
# Part a and part b run on separate CI machines in parallel.
# Part store takes full-size 6.9" App Store screenshots with a clean status bar.
# Part new shoots the newest screens for review.
set -euo pipefail
PART=$1 APP=$2 OUT=$3
BID=com.belevate.littlemenace
mkdir -p "$OUT"

udid() { xcrun simctl list devices available | grep -F "$1 (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'; }
boot() { xcrun simctl boot "$1" || true; xcrun simctl bootstatus "$1" -b >/dev/null; xcrun simctl install "$1" "$APP"; }
shot() { # udid name [launch args...]; every shot starts from a fresh gremlin
  local U=$1 N=$2; shift 2
  xcrun simctl launch --terminate-running-process "$U" $BID -LMReset YES "$@" >/dev/null
  sleep 3
  xcrun simctl io "$U" screenshot "$OUT/$N.png" >/dev/null 2>&1
}

PM=$(udid "iPhone 16 Pro Max")
# Runner images differ: fall back to the newest Pro Max available.
[ -n "$PM" ] || PM=$(xcrun simctl list devices available | grep -E "iPhone [0-9]+ Pro Max \(" | tail -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
boot "$PM"
if [ "$PART" = store ]; then
  xcrun simctl status_bar "$PM" override --time 9:41 --dataNetwork wifi --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
  shot "$PM" 01-petting -LMScreen touch
  shot "$PM" 02-home -LMScreen home
  shot "$PM" 03-feeding -LMScreen feed
  shot "$PM" 04-snack-toss -LMScreen snackToss
  shot "$PM" 05-round-won -LMScreen snackToss -LMResult win
  shot "$PM" 06-mischief -LMScreen mischief
  shot "$PM" 07-wardrobe -LMScreen wardrobe
  shot "$PM" 08-stamps -LMScreen stamps
  shot "$PM" 09-poked -LMScreen annoyed -LMLoss 1
  shot "$PM" 10-points -LMScreen points
  shot "$PM" 11-share -LMScreen share
elif [ "$PART" = new ]; then
  # Feedback fixes.
  shot "$PM" n01-stamps-points-to-next -LMScreen stamps
  shot "$PM" n02-share-points -LMScreen share
  # Midnight Snack: collection page, looks, all items.
  shot "$PM" n03-collection-look1 -LMScreen collection
  shot "$PM" n04-collection-look2 -LMScreen collection -LMLook 1
  shot "$PM" n05-collection-look3 -LMScreen collection -LMLook 2
  shot "$PM" n06-collection-items -LMScreen collection -LMPage 1
  # Wardrobe tabs with the new items (locked, sparkle badge) and a paid preview.
  shot "$PM" n07-wardrobe-fur -LMScreen wardrobe -LMSlot fur
  shot "$PM" n08-wardrobe-hats -LMScreen wardrobe
  shot "$PM" n09-wardrobe-neck -LMScreen wardrobe -LMSlot neck
  shot "$PM" n10-wardrobe-backgrounds -LMScreen wardrobe -LMSlot theme
  shot "$PM" n11-wardrobe-socks -LMScreen wardrobe -LMSlot sock
  shot "$PM" n12-wardrobe-preview-fur -LMScreen wardrobe -LMPreview plum
  # Owned and worn: home, share card, a game.
  shot "$PM" n13-home-galaxy-brain -LMScreen home -LMOwned YES -LMTheme galaxy -LMHat starclip -LMNeck glowstick -LMFur plum
  shot "$PM" n14-home-aurora-raid -LMScreen home -LMOwned YES -LMTheme aurora -LMHat sleepmask -LMNeck cookiebib -LMFur moss
  shot "$PM" n15-home-neon-cocoa -LMScreen home -LMOwned YES -LMTheme neon -LMFur cocoa
  shot "$PM" n16-share-night-owl -LMScreen share -LMOwned YES -LMTheme midnight -LMHat nightcap -LMNeck moon -LMFur deepsea
  xcrun simctl ui "$PM" appearance dark
  shot "$PM" n17-dark-name-prompt -LMScreen namePrompt
  shot "$PM" n18-dark-home-galaxy -LMScreen home -LMOwned YES -LMTheme galaxy -LMFur plum
  xcrun simctl ui "$PM" appearance light
elif [ "$PART" = a ]; then
  shot "$PM" 01-home -LMScreen home
  shot "$PM" 02-name-prompt -LMScreen namePrompt
  shot "$PM" 03-touch -LMScreen touch
  shot "$PM" 04-feed -LMScreen feed
  shot "$PM" 05-refuse-food -LMScreen refuse
  shot "$PM" 06-dialogue -LMScreen dialogue
  shot "$PM" 07-play-picker -LMScreen playPicker
  shot "$PM" 08-snack-toss -LMScreen snackToss
  shot "$PM" 09-sock-tug -LMScreen sockTug -LMFreeze YES
  shot "$PM" 10-cushion-hunt -LMScreen cushionHunt
  shot "$PM" 11-result-win -LMScreen snackToss -LMResult win
  shot "$PM" 12-result-lose -LMScreen sockTug -LMFreeze YES -LMResult lose
  shot "$PM" 13-mischief -LMScreen mischief
else
  shot "$PM" 14-mischief-choice -LMScreen mischiefSheet
  shot "$PM" 15-asleep -LMScreen asleep
  shot "$PM" 16-grumpy-wake -LMScreen grumpy
  shot "$PM" 17-reminder-offer -LMScreen reminderOffer
  shot "$PM" 18-wardrobe-hats -LMScreen wardrobe
  shot "$PM" 19-wardrobe-neck -LMScreen wardrobe -LMSlot neck
  shot "$PM" 20-wardrobe-backgrounds -LMScreen wardrobe -LMSlot theme
  shot "$PM" 21-wardrobe-socks -LMScreen wardrobe -LMSlot sock
  shot "$PM" 22-wardrobe-preview-paid -LMScreen wardrobe -LMPreview nightcap
  shot "$PM" 23-midnight-snack -LMScreen collection
  shot "$PM" 24-stamps -LMScreen stamps
  shot "$PM" 25-share -LMScreen share
  shot "$PM" 26-settings -LMScreen settings
  shot "$PM" 27-settings-reminders -LMScreen reminders
  xcrun simctl ui "$PM" appearance dark
  shot "$PM" 28-dark-grape -LMScreen touch -LMTheme grape -LMHat leaf
  shot "$PM" 29-dark-settings -LMScreen settings
  xcrun simctl shutdown "$PM"
  SE=$(udid "iPhone SE (3rd generation)")
  if [ -n "$SE" ]; then
    boot "$SE"
    shot "$SE" 30-se-home -LMScreen home
    xcrun simctl ui "$SE" content_size accessibility-extra-extra-extra-large
    shot "$SE" 31-se-home-largest-text -LMScreen home
    shot "$SE" 32-se-stamps-largest-text -LMScreen stamps
  fi
fi

# JPEGs for the repo: full size for the store, small for review.
for f in "$OUT"/*.png; do
  if [ "$PART" = store ]; then
    sips -s format jpeg -s formatOptions 90 "$f" --out "${f%.png}.jpg" >/dev/null && rm "$f"
  else
    sips -s format jpeg -s formatOptions 70 --resampleWidth 430 "$f" --out "${f%.png}.jpg" >/dev/null && rm "$f"
  fi
done
ls "$OUT"
