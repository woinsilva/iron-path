"""Read bounded local emulator QA logs. Does not schedule future work."""
from pathlib import Path
import argparse,json,subprocess,time
parser=argparse.ArgumentParser()
parser.add_argument("--wait",type=float,default=0)
args=parser.parse_args()
root=Path(__file__).resolve().parents[2]
adb="C:/Program Files/BlueStacks_nxt/HD-Adb.exe"
end=time.monotonic()+min(max(args.wait,0),55)
while True:
    result=subprocess.run([adb,"-s","emulator-5554","logcat","-d","-s","godot"],capture_output=True,text=True,encoding="utf-8",errors="replace",timeout=12)
    if result.returncode: raise RuntimeError(result.stderr)
    log=result.stdout
    (root/"test-results/p10-android-benchmark.log").write_text(log,encoding="utf-8")
    complete=[line.split("IRON_BENCHMARK_COMPLETE ",1)[1] for line in log.splitlines() if "IRON_BENCHMARK_COMPLETE " in line]
    if complete:
        report=json.loads(complete[-1]);report["slow_frames"]=[json.loads(line.split("IRON_SLOW_FRAME ",1)[1]) for line in log.splitlines() if "IRON_SLOW_FRAME " in line]
        (root/"test-results/p10-android-benchmark.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
        print("COMPLETE",json.dumps({key:report.get(key) for key in ["completed_full_stage","lives","kills","spawned","wave","wall_seconds","frame_ms_p95","frame_ms_max"]}));break
    if time.monotonic()>=end:
        waves=[line.split("IRON_BENCHMARK_WAVE ",1)[1] for line in log.splitlines() if "IRON_BENCHMARK_WAVE " in line]
        print("RUNNING",waves[-1] if waves else "preparing");break
    time.sleep(5)
