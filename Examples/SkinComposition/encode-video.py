#!/usr/bin/env python3
"""Encode native PNG frames with their recorded wall-clock intervals; keep source PNGs."""
import argparse,hashlib,json,pathlib,subprocess,tempfile
p=argparse.ArgumentParser(); p.add_argument('directory'); p.add_argument('output'); a=p.parse_args()
root=pathlib.Path(a.directory).resolve(); frames=json.loads((root/'native.json').read_text())['frames']
if len(frames)<2: raise SystemExit('At least two native frames are required')
with tempfile.TemporaryDirectory() as temporary:
    listing=pathlib.Path(temporary)/'frames.txt'
    lines=[]
    for i,frame in enumerate(frames):
        if hashlib.sha256((root/frame['file']).read_bytes()).hexdigest()!=frame['sha256']: raise SystemExit('Native PNG integrity mismatch')
        file=str(root/frame['file']).replace("'", "'\\''")
        duration=frames[i+1]['time']-frame['time'] if i+1<len(frames) else 1/30
        if duration<=0: raise SystemExit('Native timestamps must increase')
        lines += ["file '"+file+"'", 'duration '+str(duration)]
    lines += ["file '"+str(root/frames[-1]['file']).replace("'", "'\\''")+"'"]
    listing.write_text('\n'.join(lines)+'\n')
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-f','concat','-safe','0','-i',str(listing),'-fps_mode','vfr','-c:v','libx264','-pix_fmt','yuv420p',a.output],check=True)

video=pathlib.Path(a.output)
video.with_name(video.name+'.sha256.json').write_text(json.dumps({'videoSHA256':hashlib.sha256(video.read_bytes()).hexdigest(),'nativeReportSHA256':hashlib.sha256((root/'native.json').read_bytes()).hexdigest()},indent=2)+'\n')
