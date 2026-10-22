"""Build an isolated debug APK from saved sources; no publication or production keys."""
from pathlib import Path
import json, os, shutil, subprocess, argparse
parser=argparse.ArgumentParser()
parser.add_argument("--benchmark", action="store_true")
parser.add_argument("--stage", type=int, choices=[3,8,12], default=3)
parser.add_argument("--report-only",action="store_true")
parser.add_argument("--startup-seconds",type=float,default=0)
args=parser.parse_args()
if args.startup_seconds < 0 or (args.startup_seconds > 0 and not args.benchmark): parser.error("Startup window requires benchmark and positive seconds")
if args.report_only and not args.benchmark: parser.error("--report-only requires --benchmark")
ROOT=Path(__file__).resolve().parents[2]
BASE=Path('C:/Dev/Tools/Android')
config=json.loads((BASE/'environment.json').read_text(encoding='utf-8-sig'))
settings=Path(os.environ['APPDATA'])/'Godot/editor_settings-4.5.tres'
backup=settings.with_suffix('.pre-android.tres')
if not backup.exists(): shutil.copy2(settings,backup)
s=settings.read_text(encoding='utf-8')
for key,value in {'export/android/java_sdk_path':config['java'], 'export/android/android_sdk_path':config['sdk']}.items():
    lines=s.splitlines();line=key+' = '+json.dumps(value.replace('\\','/'))
    lines=[x for x in lines if not x.startswith(key+' =')];lines.append(line);s='\n'.join(lines)+'\n'
settings.write_text(s,encoding='utf-8')
suffix=f'{args.stage:02d}' if args.benchmark and args.stage != 3 else ''
stage=BASE/(('iron-path-benchmark'+suffix+('-startup' if args.startup_seconds > 0 else '')+('-report' if args.report_only else '')) if args.benchmark else 'iron-path-smoke');stage.mkdir(exist_ok=True)
for folder in ['art','scripts','autoload','scenes','data']:
    shutil.copytree(ROOT/folder,stage/folder,dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.blend','*.import'))
project=(ROOT/'project.godot').read_text(encoding='utf-8-sig').replace('res://scenes/battle/battle.tscn','res://scenes/campaign.tscn')
# Godot issue #121035: emulator-only workaround; keep production frame pacing.
project=project.replace('[display]', '[display]\n\nwindow/frame_pacing/android/enable_frame_pacing=false')
if args.benchmark:
    project=project.replace('res://scenes/campaign.tscn','res://benchmark.tscn')
    benchmark=(ROOT/'tools/android/runtime_benchmark.gd').read_text(encoding='utf-8-sig').replace('const STAGE_INDEX: int = 3',f'const STAGE_INDEX: int = {args.stage}')
    if args.startup_seconds > 0: benchmark=benchmark.replace('const MAX_WALL_SECONDS: float = 0',f'const MAX_WALL_SECONDS: float = {args.startup_seconds}')
    if args.report_only: benchmark=benchmark.replace('const READ_EXISTING_REPORT: bool = false','const READ_EXISTING_REPORT: bool = true')
    (stage/'qa_runtime.gd').write_text(benchmark,encoding='utf-8')
    (stage/'benchmark.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://qa_runtime.gd" id="1"]\n[node name="Benchmark" type="Node"]\nscript = ExtResource("1")\n',encoding='utf-8')
(stage/'project.godot').write_text(project,encoding='utf-8')
(stage/'export_presets.cfg').write_text('''[preset.0]
name="Android Smoke"
platform="Android"
runnable=true
export_filter="all_resources"
include_filter="*.json,*.csv,*.gdshader"
exclude_filter=""
export_path=""
script_export_mode=2
[preset.0.options]
gradle_build/use_gradle_build=false
architectures/armeabi-v7a=false
architectures/arm64-v8a=true
architectures/x86=false
architectures/x86_64=true
version/code=1
version/name="0.2.0-smoke"
package/unique_name="org.ironpath.smoke"
package/name="Iron Path Smoke"
package/signed=true
screen/immersive_mode=true
permissions/internet=false
''',encoding='utf-8')
if args.benchmark:
    preset=stage/'export_presets.cfg'
    preset.write_text(preset.read_text(encoding='utf-8-sig').replace('org.ironpath.smoke','org.ironpath.benchmark').replace('Iron Path Smoke','Iron Path Benchmark'),encoding='utf-8')
if suffix:
    preset=stage/'export_presets.cfg'
    preset.write_text(preset.read_text(encoding='utf-8-sig').replace('org.ironpath.benchmark','org.ironpath.benchmark.stage'+suffix+('.startup' if args.startup_seconds > 0 else '')),encoding='utf-8')
output_apk=ROOT/(('test-results/IronPathBenchmark'+suffix+('Startup' if args.startup_seconds > 0 else '')+('Report' if args.report_only else '')+'.apk') if args.benchmark else 'test-results/IronPathSmoke.apk')
godot=Path('C:/Dev/Tools/Godot/Godot_v4.5.2-stable_win64_console.exe')
for args,name in [(['--editor','--quit'],'android-import.log'),(['--export-debug','Android Smoke',str(output_apk)],'android-export.log')]:
    with (ROOT/'test-results'/name).open('w',encoding='utf-8') as output:
        result=subprocess.run([str(godot),'--headless','--path',str(stage),*args],stdout=output,stderr=subprocess.STDOUT)
    if result.returncode: raise RuntimeError(f'{name}: exit {result.returncode}')
print('APK_READY',output_apk)
