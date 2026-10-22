"""Original Canyon score: analytic synthesis, no samples or external audio."""
from pathlib import Path
import json,hashlib,wave,subprocess,shutil
import numpy as np
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/audio';SRC=ROOT/'source_assets/audio'
RATE=44100;BPM=80;BEAT=60/BPM;DURATION=48;SEED=20506
rng=np.random.default_rng(SEED)
track=np.zeros((RATE*DURATION,2),np.float32)
def add(midi,start,length,gain,pan=0,kind='plucked'):
 t=np.arange(int(RATE*length))/RATE;f=440*2**((midi-69)/12)
 env=np.minimum(1,t/.012)*np.minimum(1,np.maximum(0,(length-t)/.12))
 if kind=='pad':
  sig=(np.sin(2*np.pi*f*t)+.24*np.sin(2*np.pi*f*2*t))*env*np.minimum(1,t/.25)
 else:
  sig=(np.sin(2*np.pi*f*t)+.3*np.sin(2*np.pi*f*3*t)+.12*np.sin(2*np.pi*f*5*t))*np.exp(-t*3.1)*env
 ix=(np.arange(len(sig))+int(start*RATE))%len(track)
 track[ix,0]+=sig*gain*np.sqrt((1-pan)/2)
 track[ix,1]+=sig*gain*np.sqrt((1+pan)/2)
roots=[38,38,34,34,41,41,36,36,38,38,43,43,34,36,33,33]
melody=[74,77,81,77,72,74,77,74,74,81,79,77,72,69,73,69]
for bar,root in enumerate(roots):
 start=bar*4*BEAT
 add(root,start,4*BEAT,.14,kind='pad')
 add(root+12,start,4*BEAT,.07,kind='pad')
 for step in range(8):add(root+24+[0,7,12,7][step%4],start+step*BEAT/2,.65,.1,-.3 if step%2 else .3)
 for step in [0,2]:add(melody[bar]+(0 if step==0 else -2),start+step*BEAT,1.2,.095,.12)
 for step in range(4):
  t=np.arange(int(RATE*.22))/RATE
  drum=np.sin(2*np.pi*(62*t+26*t*np.exp(-t*22)))*np.exp(-t*22)*np.minimum(1,t/.004)
  ix=(np.arange(len(drum))+int((start+step*BEAT)*RATE))%len(track)
  track[ix]+=(drum*.045)[:,None]
track*=.58/max(float(abs(track).max()),1e-8)
# Periodic, low-level canyon wind with no random boundary seam.
t=np.arange(RATE*12)/RATE
wind=np.zeros((len(t),2),np.float32)
for h in range(8,190):
 phase=rng.uniform(0,2*np.pi);amp=.002/h**.35
 for side in range(2):wind[:,side]+=(np.sin(2*np.pi*h*t/12+phase+side*.23)*amp).astype(np.float32)
wind*=1+.28*np.sin(2*np.pi*t/12)[:,None]
manifest={'license':'Original project synthesis; no sampled recordings','generator':'tools/assets/compose_canyon.py','seed':SEED,'bpm':BPM,'files':{}}
for name,data in [('canyon_theme',track),('canyon_ambience',wind)]:
 wav=SRC/(name+'.wav');ogg=OUT/(name+'.ogg');pcm=np.round(np.clip(data,-1,1)*32767).astype('<i2')
 with wave.open(str(wav),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(pcm.tobytes())
 subprocess.run([shutil.which('ffmpeg'),'-y','-loglevel','error','-i',str(wav),'-c:a','libvorbis','-q:a','4',str(ogg)],check=True)
 manifest['files'][ogg.name]={'sha256':hashlib.sha256(ogg.read_bytes()).hexdigest(),'source':str(wav.relative_to(ROOT)),'peak':float(abs(data).max()),'seconds':len(data)/RATE,'loop_step':float(abs(data[0]-data[-1]).max())}
(OUT/'canyon_manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps(manifest,indent=2))
