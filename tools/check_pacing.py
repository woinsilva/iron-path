"""Isolated pacing experiment; never edits campaign data or creates player progress."""
from pathlib import Path
import json
from godot_test_process import run_test
root=Path(__file__).resolve().parents[1]
folder=root/'test-results/pacing-src';folder.mkdir(exist_ok=True);(folder/'.gdignore').write_text('')
names=['test_stage01','test_alpha_campaign','test_vale']+[f'test_stage{i:02d}' for i in range(5,13)]
report=[]
for name in names:
 source=(root/'tests/simulation3d'/f'{name}.gd').read_text(encoding='utf-8-sig').replace('StageSessionV2.create(stage)','_trial_pacing(stage)')
 source+='''
func _trial_pacing(stage: Dictionary) -> BattleSimV2:
	var sim: BattleSimV2 = StageSessionV2.create(stage)
	for enemy: Dictionary in sim.catalog.enemies.values():
		enemy.hp = ceilf(float(enemy.hp) * 0.72)
		enemy.speed = float(enemy.speed) * 1.4
		if enemy.has("shield"): enemy.shield.amount = ceilf(float(enemy.shield.amount) * 0.72)
		if enemy.has("ability") and enemy.ability.has("shield_amount"): enemy.ability.shield_amount = ceilf(float(enemy.ability.shield_amount) * 0.72)
		if enemy.has("support") and enemy.support.has("amount"): enemy.support.amount = ceilf(float(enemy.support.amount) * 0.72)
	return sim
'''
 target=folder/f'{name}.gd';target.write_text(source,encoding='utf-8')
 result=run_test(['C:/Dev/Tools/Godot/Godot_v4.5.2-stable_win64_console.exe','--headless','--path',str(root),'-s',f'res://test-results/pacing-src/{name}.gd'],cwd=root)
 log=root/'test-results'/f'p9-pacing-{name}.log';log.write_text(result.stdout,encoding='utf-8')
 passed=result.returncode==0 and 'ERROR:' not in result.stdout
 report.append({'reference':name,'passed':passed,'exit_code':result.returncode,'log':str(log.relative_to(root))})
 print(('PASS' if passed else 'FAIL'),name,flush=True)
(root/'test-results/p9-pacing-experiment.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
raise SystemExit(0 if all(item['passed'] for item in report) else 1)
