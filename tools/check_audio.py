from pathlib import Path
import numpy as np,wave,json,hashlib
root=Path(__file__).resolve().parents[1]
report=json.loads((root/'art/audio/source_manifest.json').read_text(encoding='utf-8-sig'))
checks=[]
def check(value,message):
 checks.append(bool(value));print(('PASS: ' if value else 'FAIL: ')+message)
for name in ['vale_theme','vale_ambience','canyon_theme','canyon_ambience','swamp_theme','swamp_ambience']:
 with wave.open(str(root/'source_assets/audio'/f'{name}.wav'),'rb') as f:
  check(f.getnchannels()==2 and f.getframerate()==44100 and f.getsampwidth()==2,name+' is stereo PCM at the declared build sample rate')
  values=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').reshape(-1,2).astype(float)/32768
 check(float(np.max(np.abs(values)))<.95 and float(np.sqrt(np.mean(values**2)))>.001,name+' is audible signal without clipped PCM samples')
 check(float(np.max(np.abs(values[0]-values[-1])))<.01,name+' has no large discontinuity at its loop boundary')
 check((root/'art/audio'/f'{name}.ogg').stat().st_size<2000000,name+' is compressed within its mobile asset budget')
canyon=json.loads((root/'art/audio/canyon_manifest.json').read_text(encoding='utf-8-sig'))
report['files'].update({name:info['sha256'] for name,info in canyon['files'].items()})
swamp=json.loads((root/'art/audio/swamp_manifest.json').read_text(encoding='utf-8-sig'))
report['files'].update({name:info['sha256'] for name,info in swamp['files'].items()})
for name,digest in report['files'].items():
 check(hashlib.sha256((root/'art/audio'/name).read_bytes()).hexdigest()==digest,name+' matches its recorded source manifest')
print(f'P6 audio asset checks: {sum(checks)}/{len(checks)}')
raise SystemExit(0 if all(checks) else 1)
