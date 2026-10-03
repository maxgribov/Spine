# Physical iOS setup gate

This is a validation host, not a library product or replacement demo. It compiles
unchanged `Sources/Spine/**/*.swift` together with `App.swift`; internal diagnostics
remain outside the library's public API. It needs an unlocked physical device,
a locally available Apple Development identity and a provisioning profile that
permits both the bundle identifier and device.

```sh
python3 Examples/MeshDeviceProbe/build-device.py \
  --output /tmp/spine-device-proof \
  --profile "$SPINE_PROVISIONING_PROFILE" \
  --identity "$SPINE_SIGNING_IDENTITY" \
  --bundle-id "$SPINE_PROBE_BUNDLE_ID" \
  --device "$SPINE_DEVICE_ID"
xcrun devicectl device copy from --device "$SPINE_DEVICE_ID" \
  --domain-type appDataContainer --domain-identifier "$SPINE_PROBE_BUNDLE_ID" \
  --source Documents --destination /tmp/spine-device-results
xcrun devicectl device uninstall app --device "$SPINE_DEVICE_ID" "$SPINE_PROBE_BUNDLE_ID"
```

Keep credentials, provisioning profiles and device identifiers outside the repo.
The script writes build/sign/install/launch logs and exact source hashes to its
output directory. A failed command stops subsequent steps. It does not register
new devices or download provisioning credentials. Minimum deployment target is
iOS 13; this debug host makes no performance claim.

The host performs 30 real SKView updates and requires zero native preparation
errors. It then compares production output with native sprite/single-triangle
references on the physical device's Metal GPU. Frame coordinates come from the
stable native SKView **before** assigning the scene to SKRenderer for readback.
The fixed-size scene uses `aspectFit`. Readback is not a screenshot of a presented
native drawable and is not a presented-FPS measurement.

The six comparisons cover paired-triangle PMA/tint/shared edges, trimmed and
90-degree rotated regions on straight/PMA pages, reflection, folds and the odd
triangle tail. A comparison requires visible colored geometry and maximum RGBA
error at most 2/255, with separate counts for channels/alpha over 2. Actual and
reference PNGs plus `production-gate.json` are written into Documents. Merely
launching the app or rendering empty frames is not a pass.

The foreground validation host temporarily disables its own idle timer to allow
artifact retrieval and follow-up checks. Uninstall or close it after collecting
evidence; no persistent device setting is changed. The recorded phase-3 run was
uninstalled after artifact retrieval.
