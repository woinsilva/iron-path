"""Original short game cues; analytic synthesis and seeded noise, no samples."""
from pathlib import Path
import numpy as np,wave,json,hashlib
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'art/audio/sfx';OUT.mkdir(exist_ok=True)
RATE=22050;SEED=20708;rng=np.random.default_rng(SEED)
manifest={'generator':'tools/assets/compose_sfx.py','origin':'Original analytic synthesis; no recordings or external samples','seed':SEED,'files':{}}
for name in ['ui','archer','cannon','frost','venom','anti_air','bleed','arcane','banner','impact','heal','rally','shield_break','summon']:
 duration={'ui':.08,'archer':.18,'cannon':.48,'frost':.3,'venom':.28,'anti_air':.18,'bleed':.25,'arcane':.28,'banner':.28,'impact':.1,'heal':.35,'rally':.6,'shield_break':.4,'summon':.4}[name]
 t=np.arange(int(duration*RATE))/RATE;noise=rng.normal(0,1,len(t));env=np.minimum(1,t/.005)*np.minimum(1,np.maximum(0,(duration-t)/.035))
 if name=='cannon':sig=(np.sin(2*np.pi*(52*t+1.8*(1-np.exp(-t*40))))*.8+noise*.25*np.exp(-t*40))*np.exp(-t*8)
 elif name in ['archer','bleed']:
  sig=(noise-np.roll(noise,1))*.2*np.exp(-t*24)+np.sin(2*np.pi*(145 if name=='archer' else 100)*t)*np.exp(-t*30)*.3
 elif name in ['ui','impact']:
  sig=(np.sin(2*np.pi*760*t)+np.sin(2*np.pi*1100*t)*.25+noise*.08)*np.exp(-t*60)
 elif name=='venom':sig=sum(np.sin(2*np.pi*(240+k*90)*t)*np.exp(-((t-.045*k)/.03)**2) for k in range(1,5))
 elif name in ['rally','summon']:
  sig=(np.sin(2*np.pi*110*t)+.4*np.sin(2*np.pi*165*t)+.25*np.sin(2*np.pi*220*t))*np.minimum(1,t/.05)*np.exp(-t*4)
 else:
  root={'frost':1174,'anti_air':880,'arcane':440,'banner':294,'heal':659,'shield_break':392}[name]
  sig=sum(np.sin(2*np.pi*root*ratio*t)*gain for ratio,gain in [(1,1),(1.5,.4),(2.01,.22)])*np.exp(-t*12)
  if name=='shield_break':sig+=noise*.18*np.exp(-t*30)
 sig*=env;sig*=.42/max(float(np.max(abs(sig))),1e-9)
 pcm=np.round(sig*32767).astype('<i2');path=OUT/(name+'.wav')
 with wave.open(str(path),'wb') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(pcm.tobytes())
 manifest['files'][path.name]={'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'seconds':duration,'peak':float(abs(sig).max())}
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print('Original cues generated:',len(manifest['files']))
