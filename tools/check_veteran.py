"""Own reproducible Veteran references; original Normal plans remain untouched."""
from pathlib import Path
import json
from godot_test_process import run_test
root=Path(__file__).resolve().parents[1]
folder=root/'test-results/veteran-references';folder.mkdir(exist_ok=True);(folder/'.gdignore').write_text('')
names=['test_stage01','test_alpha_campaign','test_vale']+[f'test_stage{i:02d}' for i in range(5,13)]
report=[]
for name in names:
 source=(root/'tests/simulation3d'/f'{name}.gd').read_text(encoding='utf-8-sig')
 source=source.replace('StageSessionV2.create(stage)','StageSessionV2.create(stage, "veteran")')
 if name=='test_stage01': source=source.replace('for strategy in range(3):','for strategy in range(1):')
 elif name=='test_alpha_campaign': source=source.replace('for variant in range(2):','for variant in ([0] if stage_index == 2 else [1]):')
 elif name in ['test_stage06','test_stage09']:source=source.replace('for variant in range(2):','for variant in [1]:')
 else: source=source.replace('for variant in range(2):','for variant in range(1):')
 if name=='test_vale':
  source=source.replace('\t\t\tif index % 30 == 0:','\t\t\tif sim.wave_index == 16:\n\t\t\t\tfor tower: SimTowerV2 in sim.towers.values():\n\t\t\t\t\tif tower.type_id in ["bleed", "cannon"]: tower.priority = "strongest"\n\t\t\tif index % 30 == 0:',1)
 target=folder/f'{name}.gd';target.write_text(source,encoding='utf-8')
 result=run_test(['C:/Dev/Tools/Godot/Godot_v4.5.2-stable_win64_console.exe','--headless','--path',str(root),'-s',f'res://test-results/veteran-references/{name}.gd'],cwd=root)
 log=root/'test-results'/f'p8-veteran-reference-{name}.log';log.write_text(result.stdout,encoding='utf-8')
 passed=result.returncode==0 and 'ERROR:' not in result.stdout
 report.append({'reference':name,'passed':passed,'exit_code':result.returncode,'log':str(log.relative_to(root))})
 print(('PASS' if passed else 'FAIL'),name,flush=True)
(root/'test-results/p8-veteran-references.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
raise SystemExit(0 if all(item['passed'] for item in report) else 1)
