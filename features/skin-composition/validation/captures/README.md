# Recorded captures

`macos/` and `iphone-air/` contain separate same-backend paired PNGs, native frame
sequences, native playback MP4 and raw diagnostic measurements. Do not compare
pixels between devices. Each JSON report embeds the source commit, dirty flag and
exact source/fixture hashes; captures were collected from the Phase 5 working tree
based on commit 4377855, not claimed to be from a future clean commit.

Six deterministic paired cases must have zero differing bytes. Native frames are
compared after the actual owner's callback adopts the control outfit; before that
point different pixels are intentional. The pose trace must agree throughout.
MP4 is encoded from native PNGs with their recorded intervals, not used for exact
pixel acceptance. No manual GUI screenshot inspection is claimed.
