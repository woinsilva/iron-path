"""Original Vale theme and ambience. Analytic synthesis; no sampled recordings."""
from pathlib import Path
import numpy as np, wave, subprocess, shutil, hashlib, json
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'art/audio';OUT.mkdir(parents=True,exist_ok=True)
WAV=ROOT/'source_assets/audio';WAV.mkdir(parents=True,exist_ok=True)
RATE=44100;SEED=19731;rng=np.random.default_rng(SEED)
def frequency(midi):return 440*2**((midi-69)/12)
def envelope(t,duration,attack=.03,release=.15):
 return np.minimum(1,t/attack)*np.minimum(1,np.maximum(0,(duration-t)/release))
def tone(midi,duration,kind):
 t=np.arange(int(RATE*duration))/RATE;f=frequency(midi)
 if kind=='harp':
  signal=sum(np.sin(2*np.pi*f*n*t + n*.03)*np.exp(-t*(1.8+n*.48))/n**1.65 for n in range(1,13))
  signal*=envelope(t,duration,.008,.2)
 elif kind=='flute':
  phase=2*np.pi*f*t + .045*np.sin(2*np.pi*5.2*t)*np.minimum(1,t/.25)
  signal=(np.sin(phase)+.18*np.sin(2*phase)+.04*np.sin(3*phase))*envelope(t,duration,.085,.2)
 elif kind=='pad':
  signal=(np.sin(2*np.pi*f*t)+.32*np.sin(2*np.pi*f*2.0008*t)+.13*np.sin(2*np.pi*f*3*t))*envelope(t,duration,.35,.65)
 else:
  signal=(np.sin(2*np.pi*f*t)+.3*np.sin(4*np.pi*f*t))*envelope(t,duration,.025,.25)*np.exp(-t*.7)
 return signal.astype(np.float32)
def add(track,signal,start,gain,pan=0):
 indices=(np.arange(len(signal))+int(start*RATE))%len(track)
 left=np.sqrt((1-pan)/2);right=np.sqrt((1+pan)/2)
 np.add.at(track[:,0],indices,signal*gain*left);np.add.at(track[:,1],indices,signal*gain*right)
def write_wav(path,signal):
 signal=np.clip(signal,-.95,.95)
 with wave.open(str(path),'wb') as stream:
  stream.setnchannels(2);stream.setsampwidth(2);stream.setframerate(RATE);stream.writeframes((signal*32767).astype('<i2').tobytes())
beat=60/90;bar=beat*4;duration=bar*16
track=np.zeros((round(duration*RATE),2),np.float32)
chords=[[52,55,59,64],[48,52,55,60],[43,47,50,55],[50,54,57,62]]
melodies=[[76,79,83,81,79,78,76,74],[76,79,84,83,79,76,74,76],[74,79,83,86,83,81,79,78],[78,81,86,83,81,78,76,78]]
for measure in range(16):
 start=measure*bar;chord=chords[measure%4]
 for index,note in enumerate(chord):add(track,tone(note,bar+.65,'pad'),start,.022,(-.65+index*.4))
 add(track,tone(chord[0]-12,beat*1.9,'bass'),start,.075)
 add(track,tone(chord[0]-12,beat*1.8,'bass'),start+beat*2,.06)
 for tick in range(8):
  note=chord[[0,2,1,3,0,2,1,2][tick]]+12
  add(track,tone(note,1.6,'harp'),start+tick*beat*.5,.065,-.35 if tick%2 else .35)
 if measure>=4:
  line=melodies[measure%4]
  for index in range(4):
   note=line[(index*2+(2 if measure>=12 else 0))%8]-12
   add(track,tone(note,beat*.92,'flute'),start+index*beat,.055,.15)
 # Soft wood pulse; never a hard click.
 for tick in [0,2]:
  t=np.arange(int(RATE*.13))/RATE
  wood=(np.sin(2*np.pi*210*t)+.35*np.sin(2*np.pi*510*t))*np.exp(-t*45)*envelope(t,.13,.002,.035)
  add(track,wood,start+tick*beat,.021,-.1)
# Cyclic, stereo cross-delay reverb preserves tails at the loop boundary.
dry=track.copy()
for delay,gain in [(.071,.1),(.137,.085),(.231,.07),(.349,.05),(.503,.035)]:
 track[:,0]+=np.roll(dry[:,1],int(RATE*delay))*gain
 track[:,1]+=np.roll(dry[:,0],int(RATE*(delay+.011)))*gain
track=np.tanh(track*1.25);track*=.62/max(.001,float(np.max(np.abs(track))))
write_wav(WAV/'vale_theme.wav',track)
# Periodic pink-ish wind and two original sinusoidal bird motifs.
ambience_duration=12;count=RATE*ambience_duration
white=rng.normal(size=count)
spectrum=np.fft.rfft(white);freq=np.fft.rfftfreq(count,1/RATE)
spectrum*=1/np.sqrt(np.maximum(freq,45));spectrum[freq>6000]=0
wind=np.fft.irfft(spectrum,n=count).astype(np.float32);wind/=max(.001,float(np.max(np.abs(wind))))
t=np.arange(count)/RATE;wind*=.07*(.75+.25*np.sin(2*np.pi*t/ambience_duration))
ambience=np.stack([wind,np.roll(wind,int(RATE*.06))],axis=1)
for start,pan in [(2.1,-.55),(2.38,-.55),(7.3,.6),(7.54,.6)]:
 t=np.arange(int(RATE*.18))/RATE
 phase=2*np.pi*(2200*t+1400*t*t)
 chirp=np.sin(phase)*np.sin(np.pi*t/.18)**2
 add(ambience,chirp,start,.012,pan)
write_wav(WAV/'vale_ambience.wav',ambience)
ffmpeg=shutil.which('ffmpeg')
if not ffmpeg:raise RuntimeError('ffmpeg is required only to rebuild the checked-in music assets')
for name in ['vale_theme','vale_ambience']:
 subprocess.run([ffmpeg,'-y','-v','error','-i',str(WAV/(name+'.wav')),'-c:a','libvorbis','-q:a','6','-map_metadata','-1',str(OUT/(name+'.ogg'))],check=True)
report={'title':'Caminhos do Vale','author':'Iron Path original project composition','source':'tools/assets/compose_vale.py','third_party_samples':False,'seed':SEED,'sample_rate':RATE,'music_seconds':duration,'music_peak':float(np.max(np.abs(track))),'music_rms':float(np.sqrt(np.mean(track**2))),'loop_boundary_step':float(np.max(np.abs(track[0]-track[-1]))),'source_wav_files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in WAV.glob('vale_*.wav')},'files':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.iterdir() if p.suffix == '.ogg'}}
(OUT/'source_manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,ensure_ascii=True))
