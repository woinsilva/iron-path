"""Reproducible local candidate exports; debug Android signing, no publication."""
from pathlib import Path
import hashlib, json, shutil, subprocess, os
ROOT=Path(__file__).resolve().parents[1]
VERSION="0.9.0-rc1"
OUT=ROOT/"builds"/VERSION
STAGE=ROOT/"test-results"/"candidate-source-rc1"
GODOT=Path("C:/Dev/Tools/Godot/Godot_v4.5.2-stable_win64_console.exe")
OUT.mkdir(parents=True,exist_ok=True)
STAGE.mkdir(parents=True,exist_ok=True)
for folder in ["art","autoload","data","scenes","scripts"]:
    shutil.copytree(ROOT/folder,STAGE/folder,dirs_exist_ok=True,ignore=shutil.ignore_patterns("*.blend","*.import","__pycache__"))
project=(ROOT/"project.godot").read_text(encoding="utf-8-sig")
(STAGE/"project.godot").write_text(project,encoding="utf-8")
presets=(ROOT/"tools"/"export_presets_candidate.cfg").read_text(encoding="utf-8")
(STAGE/"export_presets.cfg").write_text(presets,encoding="utf-8")
def run(args,label):
    log=ROOT/"test-results"/("p10-"+label+".log")
    with log.open("w",encoding="utf-8") as stream:
        proc=subprocess.run([str(GODOT),"--headless","--path",str(STAGE),*args],stdout=stream,stderr=subprocess.STDOUT,timeout=240)
    content=log.read_text(encoding="utf-8")
    if proc.returncode or any(x in content for x in ["ERROR:","SCRIPT ERROR:"]): raise RuntimeError(str(log))
    print("PASS",label,flush=True)
run(["--editor","--quit"],"candidate-import")
pc=OUT/"Windows"
pc.mkdir(exist_ok=True)
(pc/"Jogar.cmd").write_text('@echo off\r\nstart "Iron Path" "%~dp0IronPath.exe" --resolution 1280x720\r\n',encoding="utf-8")
run(["--export-release","Windows Candidate",str(pc/"IronPath.exe")],"windows-export")
run(["--export-debug","Android Candidate",str(OUT/"IronPath-S23-0.9.0-rc1.apk")],"android-s23-export")
# BlueStacks Vulkan frame-pacing workaround applies only to this staging copy.
(STAGE/"project.godot").write_text(project.replace("[display]","[display]\n\nwindow/frame_pacing/android/enable_frame_pacing=false"),encoding="utf-8")
run(["--export-debug","Android Candidate",str(OUT/"IronPath-BlueStacks-0.9.0-rc1.apk")],"android-bluestacks-export")
notices="IRON PATH 0.9.0-rc1\nGodot Engine 4.5.2 (MIT). Engine licensing is available in game credits.\nModels, vegetation and animations: Kay Lousberg / KayKit (CC0).\nAdditional geometry, identity, synthesized music and effects created for this project.\n\n"
for path in sorted((ROOT/"art/licenses").glob("*.txt")): notices+=path.read_text(encoding="utf-8-sig")+"\n\n"
for folder in [OUT,pc]: (folder/"THIRD_PARTY_NOTICES.txt").write_text(notices,encoding="utf-8")
readme="""IRON PATH — 0.9.0-rc1, candidata para validação

PC: abra Windows/Jogar.cmd (ou IronPath.exe). Não precisa instalar Godot. Mantenha o .pck junto ao .exe.
BlueStacks: arraste IronPath-BlueStacks-0.9.0-rc1.apk para o emulador.
Galaxy S23 Ultra: use IronPath-S23-0.9.0-rc1.apk (aparelho físico ainda não validado).
Os APKs usam assinatura debug local; não são distribuição de loja.

Comece pela fase 1. Toque numa base, confirme a Arqueira e inicie a primeira onda.
As seguintes chegam automaticamente. O botão da onda mostra a previsão.
Pausar/Voltar/Escape congela a batalha; Velocidade alterna 1×/2×.
Vitórias abrem a fase seguinte. Recordes/formações/preferências são locais.
Sair durante uma partida retorna à preparação no próximo início; a partida em curso não é salva.
No menu, role para baixo para guia, perfis gráficos, áudio e créditos.

Valide especialmente movimento, legibilidade, ritmo e dificuldade.
Não há telemetria, anúncios, compras, rede ou login.
"""
for folder in [OUT,pc]: (folder/"LEIA-ME.txt").write_text(readme,encoding="utf-8")
shutil.make_archive(str(OUT/"IronPath-Windows-0.9.0-rc1"),"zip",pc)
manifest={"version":VERSION,"main_scene":"res://scenes/campaign.tscn","android_package":"org.ironpath.game","signing":"local debug, not store release","files":{}}
for file in sorted(OUT.rglob("*")):
    if file.is_file() and file.name!="manifest.json": manifest["files"][file.relative_to(OUT).as_posix()]={"bytes":file.stat().st_size,"sha256":hashlib.sha256(file.read_bytes()).hexdigest()}
(OUT/"manifest.json").write_text(json.dumps(manifest,indent=2),encoding="utf-8")
print("CANDIDATE_READY",OUT,flush=True)
