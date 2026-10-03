// Original test harness. The reference runtime is loaded externally, not vendored.
// Usage: node Scripts/compare-reference.mjs /path/to/spine-core/dist/index.js [output]
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
const directory = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
if (!process.argv[2]) throw new Error('Pass the absolute path to @esotericsoftware/spine-core 4.1.56/dist/index.js');
const manifest = JSON.parse(fs.readFileSync(path.resolve(path.dirname(process.argv[2]), '../package.json'), 'utf8'));
if (manifest.name !== '@esotericsoftware/spine-core' || manifest.version !== '4.1.56') throw new Error('Reference must be @esotericsoftware/spine-core@4.1.56');
const core = await import(pathToFileURL(path.resolve(process.argv[2])).href);
const output = path.resolve(process.argv[3] ?? path.join(directory, 'output'));
const resources = path.join(directory, 'Sources/MeshPrototype/Resources');
const atlas = new core.TextureAtlas(fs.readFileSync(path.join(resources, 'goblins.atlas'), 'utf8'));
for (const page of atlas.pages) {
  page.setTexture({ getImage: () => ({width: page.width, height: page.height}), setFilters() {}, setWraps() {} });
}
const parser = new core.SkeletonJson(new core.AtlasAttachmentLoader(atlas));
const data = parser.readSkeletonData(JSON.parse(fs.readFileSync(path.join(resources, 'goblins-pro.json'), 'utf8')));
const snapshots = JSON.parse(fs.readFileSync(path.join(output, 'vertices.json'), 'utf8'));
let maximum = 0, maximumUV = 0, worst = '', coordinates = 0;
for (const snapshot of snapshots) {
  const skeleton = new core.Skeleton(data);
  skeleton.setSkinByName(snapshot.skin);
  skeleton.setToSetupPose();
  data.findAnimation('walk').apply(skeleton, -1, snapshot.time, false, [], 1, core.MixBlend.setup, core.MixDirection.mixIn);
  skeleton.updateWorldTransform();
  const visible = skeleton.slots.filter(s => s.getAttachment() instanceof core.RegionAttachment || s.getAttachment() instanceof core.MeshAttachment);
  if (visible.length !== snapshot.parts.length) throw new Error('Visible attachment count differs');
  for (const part of snapshot.parts) {
    const slot = skeleton.findSlot(part.slot), attachment = slot.getAttachment();
    if (skeleton.getAttachment(slot.data.index, part.attachment) !== attachment) throw new Error(`Wrong attachment at ${part.slot}`);
    let expected;
    if (attachment instanceof core.MeshAttachment) {
      expected = new Array(attachment.worldVerticesLength).fill(0);
      attachment.computeWorldVertices(slot, 0, expected.length, expected, 0, 2);
    } else {
      const vertices = new Array(8).fill(0);
      attachment.computeWorldVertices(slot, vertices, 0, 2);
      // Prototype regions are BL, BR, TR, TL; the runtime emits BL, TL, TR, BR.
      expected = [0,3,2,1].flatMap(i => vertices.slice(i*2, i*2+2));
    }
    if (expected.length !== part.vertices.length) throw new Error(`Vertex count mismatch: ${part.slot}`);
    for (let i = 0; i < expected.length; i++) {
      if (!Number.isFinite(expected[i]) || !Number.isFinite(part.vertices[i])) throw new Error('Non-finite vertex');
      const difference = Math.abs(expected[i] - part.vertices[i]);
      if (difference > maximum) { maximum = difference; worst = `${snapshot.skin}/${snapshot.time}/${part.slot}/${i}`; }
      coordinates++;
    }
    const sourceUV = attachment instanceof core.MeshAttachment ? Array.from(attachment.uvs)
      : [0,3,2,1].flatMap(i => Array.from(attachment.uvs).slice(i*2, i*2+2));
    if (sourceUV.length !== part.uvs.length) throw new Error(`UV count mismatch: ${part.slot}`);
    for (let i = 0; i < sourceUV.length; i++) {
      if (!Number.isFinite(sourceUV[i]) || !Number.isFinite(part.uvs[i])) throw new Error('Non-finite UV');
      const expectedUV = i % 2 === 0 ? sourceUV[i] : 1-sourceUV[i];
      maximumUV = Math.max(maximumUV, Math.abs(expectedUV-part.uvs[i]));
    }
  }
}
// Allow Float32 rounding; tolerance is in skeleton units, not pixels.
const tolerance = 0.005;
const report = {runtime: '@esotericsoftware/spine-core@4.1.56', snapshots: snapshots.length,
                coordinates, maximumError: maximum, maximumUVError: maximumUV, worst, tolerance,
                passed: maximum <= tolerance && maximumUV <= 1e-6};
fs.writeFileSync(path.join(output, 'reference-comparison.json'), JSON.stringify(report, null, 2)+'\n');
console.log(report);
if (!report.passed) process.exitCode = 1;
