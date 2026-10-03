// Original verification harness; official code is loaded externally, never vendored.
// node .../compare-library-animation.mjs /path/to/spine-core/dist/index.js /tmp/spine-phase3-oracle
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'../../..');
const entry=path.resolve(process.argv[2]);
const manifest=JSON.parse(fs.readFileSync(path.resolve(path.dirname(entry),'../package.json'),'utf8'));
if(manifest.name!=='@esotericsoftware/spine-core'||manifest.version!=='4.1.56')throw new Error('Pinned spine-core 4.1.56 is required');
const core=await import(pathToFileURL(entry).href);
const output=path.resolve(process.argv[3]??'/tmp/spine-phase4-oracle');
const resources=path.join(root,'Tests/SpineTests/Resources/Mesh41');
const snapshots=JSON.parse(fs.readFileSync(path.join(output,'animation-vertices.json'),'utf8'));
const results=[];
for(const snapshot of snapshots){
 const atlas=new core.TextureAtlas(fs.readFileSync(path.join(resources,snapshot.atlas),'utf8'));
 for(const page of atlas.pages)page.setTexture({getImage:()=>({width:page.width,height:page.height}),setFilters(){},setWraps(){}});
 const data=new core.SkeletonJson(new core.AtlasAttachmentLoader(atlas)).readSkeletonData(JSON.parse(fs.readFileSync(path.join(resources,snapshot.fixture+'.json'),'utf8')));
 const skeleton=new core.Skeleton(data);skeleton.setSkinByName(snapshot.skin);skeleton.setToSetupPose();data.findAnimation(snapshot.animation).apply(skeleton,-1,snapshot.time,false,[],1,core.MixBlend.setup,core.MixDirection.mixIn);skeleton.updateWorldTransform();
 if(JSON.stringify(snapshot.drawOrder)!==JSON.stringify(skeleton.drawOrder.map(slot=>slot.data.index)))throw new Error('Setup draw order differs');
 for(let i=0;i<skeleton.slots.length;i++){
  const key=snapshot.activeAttachments[i],actual=skeleton.slots[i].getAttachment();
  if(key===null ? actual!==null : skeleton.getAttachment(i,key)!==actual)throw new Error(`Active identity differs: ${snapshot.fixture}/${snapshot.skin}/${snapshot.time}/${i}`);
  const color=skeleton.slots[i].color,rgba=[color.r,color.g,color.b,color.a];
  if(rgba.some((value,c)=>Math.abs(value-snapshot.slotColors[i][c])>1e-5))throw new Error(`Slot color differs at ${snapshot.fixture}/${snapshot.skin}/${snapshot.time}/${i}`);
 }
 let maximumPositionError=0,maximumUVError=0,coordinates=0,worstPosition=null;
 const visible=skeleton.slots.filter(slot=>slot.getAttachment() instanceof core.MeshAttachment||slot.getAttachment() instanceof core.RegionAttachment);
 if(visible.length!==snapshot.parts.length)throw new Error('Visible part count differs');
 for(const part of snapshot.parts){
  const slot=skeleton.findSlot(part.slot),attachment=slot.getAttachment();let positions,uv;
  if(attachment instanceof core.MeshAttachment){
   positions=new Array(attachment.worldVerticesLength).fill(0);attachment.computeWorldVertices(slot,0,positions.length,positions,0,2);uv=Array.from(attachment.uvs);
   const source=data.findSkin(part.deformSourceSkin).getAttachment(slot.data.index,part.deformSourceName);
   if(attachment.timelineAttachment!==source)throw new Error('Linked timeline identity differs');
  }else{
   const raw=new Array(8).fill(0);attachment.computeWorldVertices(slot,raw,0,2);positions=[0,3,2,1].flatMap(i=>raw.slice(i*2,i*2+2));uv=[0,3,2,1].flatMap(i=>Array.from(attachment.uvs).slice(i*2,i*2+2));
  }
  if(positions.length!==part.vertices.length||uv.length!==part.uvs.length)throw new Error('Vertex/UV count differs');
  positions.forEach((value,i)=>{if(!Number.isFinite(value)||!Number.isFinite(part.vertices[i]))throw new Error('Nonfinite position');if(Math.abs(value-part.vertices[i])>maximumPositionError){maximumPositionError=Math.abs(value-part.vertices[i]);worstPosition={slot:part.slot,attachment:part.attachment,index:i,expected:value,actual:part.vertices[i]};}coordinates++;});
  uv.forEach((value,i)=>{const expected=i%2?1-value:value;if(!Number.isFinite(expected)||!Number.isFinite(part.uvs[i]))throw new Error('Nonfinite UV');maximumUVError=Math.max(maximumUVError,Math.abs(expected-part.uvs[i]));});
 }
 results.push({fixture:snapshot.fixture,skin:snapshot.skin,time:snapshot.time,coordinates,maximumPositionError,maximumUVError,worstPosition,passed:maximumPositionError<=.005&&maximumUVError<=1e-6});
}
const report={runtime:'@esotericsoftware/spine-core@4.1.56',scope:'phase 4 full key/midpoint/switch-boundary grid through real SKAction scheduling',fixtures:new Set(snapshots.map(x=>x.fixture)).size,snapshots:results.length,results,passed:results.every(x=>x.passed)};
fs.writeFileSync(path.join(output,'animation-oracle.json'),JSON.stringify(report,null,2)+'\n');console.log({snapshots:results.length,maximumPositionError:Math.max(...results.map(x=>x.maximumPositionError)),maximumUVError:Math.max(...results.map(x=>x.maximumUVError)),failures:results.filter(x=>!x.passed),passed:report.passed});
if(!report.passed)process.exitCode=1;
