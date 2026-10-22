from pathlib import Path
import subprocess,json,argparse
from godot_test_process import run_test
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--difficulty',choices=['adventure','veteran'],required=True);parser.add_argument('--budget-multiplier',type=float,default=1.0);parser.add_argument('--label');parser.add_argument('--enemy-hp',type=float);parser.add_argument('--enemy-speed',type=float,default=1.0);parser.add_argument('--lives',type=int,default=20);args=parser.parse_args()
run_name=args.label or args.difficulty
folder=root/'test-results/difficulty-src';folder.mkdir(exist_ok=True);(folder/'.gdignore').write_text('')
sources=['test_stage01','test_alpha_campaign','test_vale']+[f'test_stage{i:02d}' for i in range(5,13)]
report=[]
for name in sources:
 text=(root/'tests/simulation3d'/f'{name}.gd').read_text(encoding='utf-8-sig')
 assert 'StageSessionV2.create(stage)' in text,name
 text=text.replace('StageSessionV2.create(stage)',f'StageSessionV2.create(stage, "{args.difficulty}")')
 if args.budget_multiplier != 1.0:
  text=text.replace(f'StageSessionV2.create(stage, "{args.difficulty}")',f'StageSessionV2.create(_trial_budget(stage), "{args.difficulty}")')
  text+=f'\nfunc _trial_budget(original: Dictionary) -> Dictionary:\n\tvar revised: Dictionary = original.duplicate(true)\n\trevised.starting_coins = int(round(float(revised.starting_coins) * {args.budget_multiplier}))\n\treturn revised\n'
 if args.enemy_hp is not None:
  call=f'StageSessionV2.create(_trial_budget(stage), "{args.difficulty}")' if args.budget_multiplier != 1.0 else f'StageSessionV2.create(stage, "{args.difficulty}")'
  text=text.replace(call,'_trial_profile(stage)')
  text+=f'\nfunc _trial_profile(stage: Dictionary) -> BattleSimV2:\n\tvar sim: BattleSimV2 = StageSessionV2.create(stage, "normal")\n\tsim.coins = int(round(float(stage.starting_coins) * {args.budget_multiplier}))\n\tsim.lives = {args.lives}\n\tsim.initial_lives = {args.lives}\n\tfor enemy: Dictionary in sim.catalog.enemies.values():\n\t\tenemy.hp = ceilf(float(enemy.hp) * {args.enemy_hp})\n\t\tenemy.speed = float(enemy.speed) * {args.enemy_speed}\n\tfor wave: Dictionary in sim.waves: wave.interval = 6.0\n\treturn sim\n'
 target=folder/f'{run_name}_{name}.gd';target.write_text(text,encoding='utf-8')
 result=run_test(['C:/Dev/Tools/Godot/Godot_v4.5.2-stable_win64_console.exe','--headless','--path',str(root),'-s',f'res://test-results/difficulty-src/{target.name}'],cwd=root,timeout=180)
 log=root/'test-results'/f'p8-{run_name}-{name}.log';log.write_text(result.stdout,encoding='utf-8')
 passed=result.returncode==0 and 'ERROR:' not in result.stdout
 report.append({'reference':name,'passed':passed,'exit_code':result.returncode,'log':str(log.relative_to(root))})
 print(('PASS' if passed else 'FAIL'),args.difficulty,name,flush=True)
(root/'test-results'/f'p8-{run_name}-campaign.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
raise SystemExit(0 if all(r['passed'] for r in report) else 1)
