# PR: Image Lightbox UI, Composer Remove Button & OpenCode Agent Improvements

**Date**: 2026-04-09
**Status**: Complete
**Components**: Image Preview Modal, Message Input, OpenCode/Antigravity Agent Provider

## Summary

Fixed attachment image preview modal (lightbox) to be properly centered on screen with larger display size, improved the remove button UX in the message composer attachment thumbnails, and refactored the OpenCode agent provider to use non-blocking prompt calls for consistency with CLI behavior.

---

## Changes Made

### 1. **attachment-image-preview-modal.tsx**

#### Issues Fixed
- Modal content appeared at top of screen instead of centered
- Image preview was too small (240px minimum, no maximum constraint)
- Overlay was too light (72% opacity instead of 88%)
- Close button wasn't positioned at corner edge

#### Solutions Implemented

**A. Fixed Centering Using Window Dimensions**
- Added `useWindowDimensions` hook to get viewport dimensions
- Changed from percentage-based height (`height: "70%"`) to pixel-based height: `Math.round(Math.min(winH * 0.75, 820))`
- **Why**: React Native Web's flexbox centering breaks when `position: absolute` elements lack explicit pixel dimensions. Percentage heights don't resolve correctly in the portal context.

**B. Increased Image Display Size**
- `imageCard.maxWidth`: `980px` → `900px` (responsive width)
- `imageCard.height`: Now dynamically set to 75% of window height (max 820px)
- Image scales to fit card dimensions with `resizeMode: "contain"`

**C. Redesigned Layout Structure**
- Removed broken `SafeAreaView` → `overlayRoot flex:1` chain
- Created new `fullScreen` style with explicit `position: absolute` + pixel dimensions
- `fullScreen` receives `width` and `height` from `useWindowDimensions` as inline styles
- This guarantees the flex container has a defined size for `alignItems: "center"` + `justifyContent: "center"` to work

**D. Darkened Overlay**
- `backdrop.backgroundColor`: `rgba(0, 0, 0, 0.72)` → `rgba(0, 0, 0, 0.88)`
- Stronger modal feel, better contrast with content

**E. Refined Close Button**
- Position: `top: 10` → `top: 12`, `right: 10` → `right: 12` (slight adjustment for better visual corner placement)
- `backgroundColor`: slightly more opaque (`0.85`)

### 2. **message-input.tsx**

#### Issue
- Remove button on attachment thumbnail appeared "too centered" in the thumbnail
- Button was positioned inside overflow-hidden container, making it appear too close to center visually

#### Solution: Allow Button to Overflow Thumbnail Edge
**Structural Change**:
- Wrapped `ImageAttachmentThumbnail` in a new `imageThumbnailWrapper` View
- Moved `overflow: "hidden"` + `borderRadius` from `imagePill` to `imageThumbnailWrapper`
- Removed `overflow: "hidden"` from `imagePill` to allow the remove button to overflow

**Button Repositioning**:
- `removeImageButton.top`: `4px` → `-7px` (outside container, top-right corner edge)
- `removeImageButton.right`: `4px` → `-7px` (outside container, top-right corner edge)
- Added border styling for polish: `borderWidth: 1, borderColor: rgba(255,255,255,0.15)`
- Adjusted hover scale: `scale(0.92)` → `scale(0.85)` for visual feedback

**Why This Works**:
The negative offsets position the button at the actual corner edge of the 48×48 thumbnail, creating a modern "badge" effect that sits just outside the pill boundary. The wrapper ensures the image itself stays properly rounded while the button can overflow.

### 3. **overlay-root.ts**

#### Enhancement
- Added `el.style.zIndex = "9999"` to the overlay-root element
- Ensures modals render above all other app elements (app components go up to zIndex 1000)
- Prevents titlebar, tabs, or other UI from appearing above the modal

### 4. **packages/server/src/server/agent/providers/opencode-agent.ts**

#### Issue
- OpenCode agent was using `promptAsync()` which awaits the full async response path
- This created inconsistencies with OpenCode CLI behavior and caused provider pipeline issues

#### Solution: Non-Blocking Prompt Pattern
**Changed from**:
```typescript
const promptResponse = await this.client.session.promptAsync({...});
if (promptResponse.error) {
  // handle error synchronously
  throw new Error(errorMsg);
}
```

**Changed to**:
```typescript
// Use fire-and-forget with callback handling
void this.client.session.prompt({...}).then((response) => {
  if (response.error) {
    const errorMsg = normalizeTurnFailureError(response.error);
    this.finishForegroundTurn(
      { type: "turn_failed", provider: "opencode", error: errorMsg },
      turnId,
    );
  }
});
```

**Why**:
- Aligns with OpenCode CLI's non-blocking prompt behavior
- Avoids async-path provider inconsistencies in the agent pipeline
- Uses `finishForegroundTurn` callback instead of throwing errors synchronously
- Fire-and-forget pattern (`void`) indicates intentional async side effect

---

## Technical Details

### Component File Changes

| File | Changes | Lines |
|------|---------|-------|
| `attachment-image-preview-modal.tsx` | Refactored layout, added window dimensions, increased image size, darkened overlay | 1-169 |
| `message-input.tsx` | Restructured thumbnail wrapper, repositioned remove button, added new styles | 955-981, 1247-1281 |
| `message.tsx` | Minor style adjustments for consistency | - |
| `lib/overlay-root.ts` | Added z-index to overlay container | 14 |
| `server/src/server/agent/providers/opencode-agent.ts` | Refactored prompt call from async/await to fire-and-forget callback | 1526-1555 |

### Style Changes Summary

**Modal Card**:
- `height`: Now pixel-based (75% viewport, max 820px)
- `maxWidth`: 900px
- `backgroundColor`: More transparent background with stronger border

**Backdrop**:
- `backgroundColor`: `rgba(0, 0, 0, 0.88)` (darker)

**Close Button**:
- Position: slightly adjusted (top: 12, right: 12)
- Background: slightly more opaque

**Remove Button (Composer)**:
- Position: `-7px` top and right (outside thumbnail bounds)
- Size: 18×18 with border
- Hover effect: smooth opacity and scale transition

---

## Testing Checklist

- [x] Lightbox opens on image thumbnail click
- [x] Modal is centered both horizontally and vertically
- [x] Image displays at large size (75% of viewport height, max 820px)
- [x] Close button positioned at top-right corner with good spacing
- [x] Backdrop click closes modal
- [x] Esc key closes modal (web)
- [x] File name caption displays below image
- [x] Remove button on composer thumbnails positioned at corner
- [x] Remove button has visual hover effect
- [x] Modal appears above titlebar and all other UI elements
- [x] Typecheck passes (no TS errors)

---

## Key Fixes

1. **Centering**: Now uses explicit window pixel dimensions instead of percentage-based layout that breaks in portal context
2. **Image Size**: Dynamic sizing (75% viewport height, constrained to 820px max) vs fixed 240px minimum
3. **Overlay Strength**: Darker semi-transparent backdrop (88% vs 72% opacity)
4. **Z-Index**: Modal guaranteed above all UI with `zIndex: 9999`
5. **Remove Button UX**: Now clearly positioned at thumbnail corner edge, not center

---

## Files Modified

```
packages/app/src/components/attachment-image-preview-modal.tsx
packages/app/src/components/message-input.tsx
packages/app/src/components/message.tsx
packages/app/src/lib/overlay-root.ts
packages/server/src/server/agent/providers/opencode-agent.ts
```

---

## Build & Deploy

```bash
# Build Expo web
cd packages/app && /paseo/node_modules/.bin/expo export --platform web

# Deploy to installed app
rm -rf "/Applications/Paseo.app/Contents/Resources/app-dist"
cp -r dist "/Applications/Paseo.app/Contents/Resources/app-dist"

# Verify
npm run typecheck
```

**Status**: ✅ Typecheck passes, build successful, deployed to installed app
