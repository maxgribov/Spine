# Physical iOS release validation

This is a validation host, not a library product or replacement demo. It compiles
unchanged `Sources/Spine/**/*.swift` with the host's Swift files using Release
`-O -whole-module-optimization`. Internal diagnostics remain outside the public
API. Minimum deployment target remains iOS 13.

Build/sign first, using an existing development identity and a profile permitting
both the bundle identifier and device. Keep profiles and private identifiers
outside the repository. Add `--device` only when ready to install and launch on
an unlocked physical phone:

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
python3 Examples/MeshDeviceProbe/validate-results.py \
  --documents /tmp/spine-device-results --expected /tmp/spine-device-proof/expected-run.json
spine_run_id=$(python3 -c 'import json; print(json.load(open("/tmp/spine-device-proof/expected-run.json"))["runID"])')
spine_run_directory="/tmp/spine-device-results/runs/$spine_run_id"
node Examples/MeshPrototype/Scripts/compare-library-animation.mjs \
  "$SPINE_CORE_4156_ENTRY" "$spine_run_directory"
python3 Examples/MeshDeviceProbe/validate-results.py \
  --documents /tmp/spine-device-results --expected /tmp/spine-device-proof/expected-run.json --require-oracle
xcrun devicectl device uninstall app --device "$SPINE_DEVICE_ID" "$SPINE_PROBE_BUNDLE_ID"
```

The build script stops on failed build/sign/install/launch commands and records
logs and exact production/host source hashes. It never registers a device or
obtains credentials. A successful build, installation or launch is not a test
pass. Compare hashes with current sources before accepting a capture.

The host performs:

- Thirty actual SKView updates with native preparation, followed by six retained
  setup GPU comparisons covering paired triangles, PMA/tint, trim/rotation,
  reflection, overlap and odd triangle tails.
- Fifteen action-driven synthetic image comparisons: three skins at five
  attachment/deform/color/draw-order transition times, against the independent
  single-triangle shader. All21 cases require visible geometry and maximum
  RGBA error≤2/255; actual/reference PNGs accompany `production-gate.json`.
- The complete223-snapshot animation grid across four fixtures. Run the pinned
  external `spine-core@4.1.56` oracle on the exported `animation-vertices.json`;
  successful export alone is not a parity pass.
- Native initial speed0.5, pause/resume, dynamic node/container speed through0,
  copied finite repeats, exact begin/end/events and lease release, compatible
  skin changes while paused, and invalidated stale actions. Physical SKRenderer
  cases additionally check reentrant restart, conflicting copies and recovery.
- One hundred create/skin-switch/destroy cycles with weak-owner release checks.
- Two reversed1/10/50 rounds,30 warmup+120 measured native callbacks and30+60
  offscreen samples. Reported CPU separates action/preparation from remaining
  scene update/encode; GPU uses completed command-buffer timestamps. Readback
  occurs after timing. Each walking pose is compared against independent
  single-triangle output with the same compiled input, with error≤2/255.

The native viewport is recorded in each result; the isolated Metal target is
1920×1080. Both variants start at phase zero. `device-performance.json` reports
raw measurements; callback FPS is not presented FPS and there is no promised
30FPS device floor. `release-gate.json` summarizes device execution, but final
acceptance also requires the external oracle and source-hash verification.

Native camera/frame mapping is prepared in the stable SKView. Offscreen readback
uses an explicit target context; it is not a screenshot of a presented drawable.
The foreground host temporarily disables its own idle timer and restores it when
validation finishes or fails. Close/uninstall it after retrieving evidence.

Phase3 captures are historical setup-only evidence. Phase5 remains incomplete
until this current-source physical run and the external comparison pass.

## Current-run provenance and validation

Every launch must use `launch-device.py`; it creates a fresh expected UUID before
calling devicectl, even when launch fails. `build-device.py --device` delegates to
that launcher automatically. To launch an already installed build:

```sh
python3 Examples/MeshDeviceProbe/launch-device.py --build-output /tmp/spine-device-proof --device "$SPINE_DEVICE_ID"
```

The app refuses missing/reused IDs. Reports and PNGs live under
`Documents/runs/<runID>`, with a bundled-source digest, atomic running/failed/
completed manifest and artifact hashes. A failed launch cannot reuse an earlier
successful report. After copying Documents, validate the exact expected run:

```sh
python3 Examples/MeshDeviceProbe/validate-results.py --documents /tmp/spine-device-results --expected /tmp/spine-device-proof/expected-run.json
```

The collector prints the exact run directory. Run the pinned animation oracle on
that directory, then repeat collection validation with `--require-oracle` before
accepting release evidence. Top-level historical Documents files are not accepted.
The required `physics-stress` stage now runs three corrected3000-frame paths and
checks canonical slots with unchanged bone pose/time; all six completed stages
are mandatory. Host lifecycle helpers additionally assert that the reentrant
harness has been released before performance begins.
