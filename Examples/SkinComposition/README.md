# Skin composition public client

A native SpriteKit wardrobe on macOS and iOS. It imports `Spine` as a separate
module and uses public API exclusively. Requires Xcode and Python 3; no downloaded
packages, art, provisioning automation or sibling game project. The build copies
the repository's canonical `skin-composition` JSON/atlas/PNG into the app bundle.

From the repository root:

```sh
python3 Examples/SkinComposition/build.py --platform macos --output /tmp/skin-composition-mac
open /tmp/skin-composition-mac/SkinComposition.app
/tmp/skin-composition-mac/SkinComposition.app/Contents/MacOS/SkinComposition --validate-catalog
/tmp/skin-composition-mac/SkinComposition.app/Contents/MacOS/SkinComposition --smoke
```

The script builds an arm64 Release executable with macOS 10.15 deployment target.
`--smoke` exits after actual SKView frames successfully prepare both Skeletons;
it is a lifecycle smoke check, not image comparison or visual acceptance.
Run native smoke in an unlocked interactive desktop with the app window visible.
On a locked/occluded desktop SpriteKit may stop producing frames; smoke fails and
reports app/window visibility. Unlock and rerun instead of interpreting that failure
as a rendering pass or replacing native frames with manual/headless updates.

## iOS

Build for Apple Silicon simulator (iOS 13 deployment target), then install on an
already booted simulator and launch:

```sh
python3 Examples/SkinComposition/build.py --platform simulator --output /tmp/skin-composition-sim
xcrun simctl install booted /tmp/skin-composition-sim/SkinComposition.app
xcrun simctl launch booted dev.spine.skincomposition
```

For a physical iPhone, supply your existing signing identity and provisioning
profile authorizing the bundle identifier and device:

```sh
python3 Examples/SkinComposition/build.py --platform ios --output /tmp/skin-composition-phone \
  --identity "$SPINE_SIGNING_IDENTITY" --profile "$SPINE_PROVISIONING_PROFILE" \
  --bundle-id "$SPINE_PROBE_BUNDLE_ID"
xcrun devicectl device install app --device "$SPINE_DEVICE_ID" /tmp/skin-composition-phone/SkinComposition.app
xcrun devicectl device process launch --device "$SPINE_DEVICE_ID" "$SPINE_PROBE_BUNDLE_ID"
```

Omitting identity/profile on `--platform ios` produces an unsigned build for
compile verification only. That is not an installed or tested physical app.

## Controls and acceptance walkthrough

Click/tap **Character** to select the left or right owner. Both share one asset.
**Hat**, **Clothes**, **Earring**, **Team** change only that owner's entire descriptor.
Colored rectangular parts are intentionally simple authored diagnostic art.
**Base** restores empty layers at current requests. A subsequent item button reapplies
the selected outfit. Front/side/nil animation keys exercise attachment requests.

**Pause** pauses the selected owner while scene preparation continues. **Speed**
cycles 1/0.5/2. **Repeat** changes repetition and restarts the selected clip.
**Reset** stops/reset-to-setup while retaining the outfit; **Play** restarts with a
fresh action. **Event** toggles hat changes for both owners from their Spine callback.

Check each control during playback and pause, including independent owners and
team visibility. `didFinishUpdate` calls native prepare after all late changes.
Callbacks use weak owners. Content errors show in the status line and console.
Scene inputs, callbacks and prepare run serially; physics callbacks never apply outfits.

`Catalog.swift` is a runnable CI example: metadata agrees with declared regions,
explicit hide areas participate in conflict checks, each replacement validates
independently, and all 32 outfits validate. Library layer overlap remains legal;
the sample catalog rejects its forbidden overlap separately.

## Resource and measurement checks

```sh
swift test --filter 'CompositionLifetimeTests|CompositionPublicAPITests|SkinDescriptionTests'
/tmp/skin-composition-mac/SkinComposition.app/Contents/MacOS/SkinComposition \
  --measure /tmp/skin-composition-measurements.json
```

Lifetime tests use 100 warmups, 1,000 alternations and 1,000 exact repeats; compare
node/body/proxy counts and weak references after autorelease pools; check provider
and internal compiler invocation counts; and prove independent shared-asset owners.

The optional collector writes raw **apply** and **prepare** milliseconds separately,
cold/repeat/alternating statistics and process-resident snapshots. Its custom context
measures CPU preparation, not native frame GPU rendering. Build metadata records
source commit, dirty status and exact source/fixture hashes. Process resident samples
are not isolated asset memory or the transient staging peak. Those require platform
allocation tooling and the target workload in Phase 5. No measured result implies
release approval: budgets, isolated memory and approved workload remain pending.
Physical-iPhone fixture captures are recorded separately in the validation report.

## Automated paired images and native phase recording

```sh
/tmp/skin-composition-mac/SkinComposition.app/Contents/MacOS/SkinComposition \
  --capture /tmp/skin-paired
/tmp/skin-composition-mac/SkinComposition.app/Contents/MacOS/SkinComposition \
  --native-evidence /tmp/skin-native
python3 Examples/SkinComposition/encode-video.py /tmp/skin-native /tmp/skin-native.mp4
```

Paired captures compare a Skeleton changed at the sampled time with a control
wearing that outfit from clip start. Both use the same asset/backend, pose and
requests. Six cases cover setup, color, side/draw order, nil, pause and an event
callback. Raw pixel bytes must match exactly; the runner does not change color
space, alpha or thresholds to obtain a pass. PNGs and `comparisons.json` retain
source hashes and the backend description. Deterministic SKRenderer timestamps
are distinct from native wall-clock playback.

Native recording samples actual SKView `didFinishUpdate`, records the pose of both
owners and compares pixels after the callback changes the outfit. It writes PNGs
and wall-clock times to `native.json`. The optional `encode-video.py` requires an
available `ffmpeg`; the MP4 uses recorded frame intervals. PNG comparisons remain
the exact evidence; lossy MP4 is only playback presentation.

After signing/installing the iOS build, launch the same evidence runner on an
unlocked physical phone and leave it visible until export:

```sh
xcrun devicectl device process launch --terminate-existing --device "$SPINE_DEVICE_ID" \
  "$SPINE_PROBE_BUNDLE_ID" -- --evidence
xcrun devicectl device copy from --device "$SPINE_DEVICE_ID" --domain-type appDataContainer \
  --domain-identifier "$SPINE_PROBE_BUNDLE_ID" --source Documents/skin-composition \
  --destination /tmp/skin-phone-results
python3 Examples/SkinComposition/encode-video.py /tmp/skin-phone-results/native /tmp/skin-phone.mp4
```

Check `result.json`, paired and native reports: launching or copying alone is not
a pass. The native runner writes a timeout failure if the app cannot produce frames.
Platform images are compared only to controls from their own backend, never to
another device. Read `build.json` provenance in each report before accepting it.

Capture reports record SHA-256 for every PNG at capture time. Video encoding verifies
those source frames and writes an MP4/native-report SHA-256 sidecar. The evidence
verifier rejects corrupted or mixed PNG/video artifacts even when JSON pass flags remain.
