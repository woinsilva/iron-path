"""Check role trade-offs on actual fixed-tick controlled benchmark output."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
report=json.loads((ROOT/'test-results/arsenal-reference.json').read_text(encoding='utf-8-sig'))
rows=report['rows'];by={(r['family'],r['level'],r['branch'],r['case']):r for r in rows}
checks=[]
def check(value,message):
 checks.append(bool(value));print(('PASS: ' if value else 'FAIL: ')+message)
def metric(family,branch,scenario,key='dps'):
 return by[(family,5,branch,scenario)][key]
check(len(rows)==448 and len(by)==448,'56 configurations have eight distinct controlled scenarios each')
check(all(r['investment']>0 and r['dps']>=0 and r['control_delay_seconds']>=0 for r in rows),'Measured economy and useful combat metrics stay valid')
for family,single,group,scenario in [('archer','A','B','swarm'),('cannon','B','A','swarm'),('venom','B','A','swarm'),('bleed','B','A','swarm'),('arcane','A','B','swarm')]:
 check(metric(family,single,'single')>metric(family,group,'single'),family+' focus branch wins on an isolated target')
 check(metric(family,group,scenario)>metric(family,single,scenario),family+' group branch wins on compact groups')
check(metric('frost','B','single')>metric('frost','A','single'),'Glacial needle has stronger isolated damage')
check(metric('frost','A','control','control_delay_seconds')>metric('frost','B','control','control_delay_seconds'),'Frost field provides more useful control against groups')
check(metric('anti_air','B','air')>metric('anti_air','A','air'),'Celestial spear has stronger isolated airborne damage')
check(metric('anti_air','A','air_swarm')>metric('anti_air','B','air_swarm'),'Air chain has stronger damage against clustered flyers')
check(metric('anti_air','A','swarm')==0 and metric('anti_air','B','single')==0,'Anti-air specializations preserve their ground limitation')
check(metric('banner','A','single')>metric('banner','B','single'),'Command provides more cadence to allies already in range')
check(metric('banner','B','reach')>metric('banner','A','reach'),'Vigil extends useful allied coverage beyond the original range')
print(f'P5 controlled role checks: {sum(checks)}/{len(checks)}')
raise SystemExit(0 if all(checks) else 1)
