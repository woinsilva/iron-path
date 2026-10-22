"""Install project-local build tools from the original publishers (no global PATH edits)."""
from pathlib import Path
import urllib.request, json, zipfile, hashlib, xml.etree.ElementTree as ET, subprocess, os
opener=urllib.request.build_opener();opener.addheaders=[('User-Agent','Mozilla/5.0')];urllib.request.install_opener(opener)
BASE=Path('C:/Dev/Tools/Android');BASE.mkdir(parents=True,exist_ok=True)

def download(url,path,checksum=None):
    if not path.exists():
        with urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'Mozilla/5.0'})) as response,path.open('wb') as output:
            while chunk:=response.read(1024*1024):output.write(chunk)
    if checksum:
        algorithm,digest=checksum
        assert hashlib.new(algorithm,path.read_bytes()).hexdigest()==digest,(path,'checksum mismatch')
    print('READY',path.name,round(path.stat().st_size/1024/1024,1),'MB',flush=True)

if __name__=='__main__':
    assets=json.load(urllib.request.urlopen('https://api.adoptium.net/v3/assets/latest/17/hotspot?architecture=x64&image_type=jdk&os=windows&vendor=eclipse'))
    package=assets[0]['binary']['package'];archive=BASE/'jdk17.zip'
    download(package['link'],archive,('sha256',package['checksum']))
    with zipfile.ZipFile(archive) as z:
        top=z.namelist()[0].split('/')[0]
        if not (BASE/top/'bin/java.exe').exists():z.extractall(BASE)
    java=BASE/top
    sdk=BASE/'sdk';sdk.mkdir(exist_ok=True)
    repo=ET.fromstring(urllib.request.urlopen('https://dl.google.com/android/repository/repository2-1.xml').read())
    entry=next(e for e in repo if e.tag.endswith('remotePackage') and e.attrib.get('path')=='cmdline-tools;latest')
    archive_info=next(e for e in entry.iter('archive') if e.findtext('host-os')=='windows')
    complete=archive_info.find('complete');url=complete.findtext('url');checksum=complete.find('checksum')
    tools_zip=BASE/'commandlinetools.zip';download('https://dl.google.com/android/repository/'+url,tools_zip,(checksum.attrib.get('type','sha1'),checksum.text))
    destination=sdk/'cmdline-tools/latest';destination.mkdir(parents=True,exist_ok=True)
    if not (destination/'bin/sdkmanager.bat').exists():
        with zipfile.ZipFile(tools_zip) as z:
            for info in z.infolist():
                parts=Path(info.filename).parts[1:]
                if not parts or info.is_dir():continue
                target=destination.joinpath(*parts)
                assert target.resolve().is_relative_to(destination.resolve())
                target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(z.read(info))
    env=os.environ.copy();env['JAVA_HOME']=str(java);env['ANDROID_HOME']=str(sdk)
    sdkmanager=destination/'bin/sdkmanager.bat'
    result=subprocess.run([str(sdkmanager),f'--sdk_root={sdk}','--licenses'],input='y\n'*40,text=True,env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (BASE/'licenses.log').write_text(result.stdout,encoding='utf-8')
    result=subprocess.run([str(sdkmanager),f'--sdk_root={sdk}','platform-tools','build-tools/35.0.0','platforms/android-35'],env=env,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
    (BASE/'sdk-install.log').write_text(result.stdout,encoding='utf-8')
    if result.returncode:raise RuntimeError(result.stdout[-3000:])
    assert (sdk/'build-tools/35.0.0/apksigner.bat').exists(), 'Android Build Tools were not installed'
    assert (sdk/'platforms/android-35/android.jar').exists(), 'Android Platform 35 missing'
    release=json.load(urllib.request.urlopen(urllib.request.Request('https://api.github.com/repos/godotengine/godot-builds/releases/tags/4.5.2-stable',headers={'User-Agent':'Mozilla/5.0'})))
    asset=next(a for a in release['assets'] if a['name'].endswith('export_templates.tpz'))
    templates=BASE/'godot-export-templates.tpz';download(asset['browser_download_url'],templates)
    dest=Path(os.environ['APPDATA'])/'Godot/export_templates/4.5.2.stable';dest.mkdir(parents=True,exist_ok=True)
    wanted=['android_debug.apk','android_release.apk','windows_debug_x86_64.exe','windows_release_x86_64.exe']
    with zipfile.ZipFile(templates) as z:
        for filename in wanted:
            member=next(n for n in z.namelist() if n.endswith('/'+filename))
            (dest/filename).write_bytes(z.read(member))
    config={'java':str(java),'sdk':str(sdk),'templates':str(dest),'godot':'4.5.2.stable'}
    (BASE/'environment.json').write_text(json.dumps(config,indent=2),encoding='utf-8')
    print(json.dumps(config),flush=True)
