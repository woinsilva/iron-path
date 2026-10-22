from pathlib import Path
import json,wave,hashlib,numpy as np
root=Path(__file__).resolve().parents[1];folder=root/'art/audio/sfx'
manifest=json.loads((folder/'manifest.json').read_text(encoding='utf-8-sig'));checks=[]
def check(value,message):
 checks.append(bool(value));print(('PASS: ' if value else 'FAIL: ')+message)
for name,info in manifest['files'].items():
 path=folder/name
 with wave.open(str(path),'rb') as f:
  check(f.getnchannels()==1 and f.getsampwidth()==2 and f.getframerate()==22050,name+' matches the short-cue playback format')
  x=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').astype(float)/32768
 check(.001<float(np.sqrt(np.mean(x*x))) and float(np.max(abs(x)))<=.43,name+' has audible unclipped signal')
 check(max(abs(x[0]),abs(x[-1]))<.002 and len(x)/22050<1,name+' fades to silence within its short voice budget')
 check(hashlib.sha256(path.read_bytes()).hexdigest()==info['sha256'],name+' matches its original synthesis manifest')
print(f'SFX assets: {sum(checks)}/{len(checks)}');raise SystemExit(0 if all(checks) else 1)
