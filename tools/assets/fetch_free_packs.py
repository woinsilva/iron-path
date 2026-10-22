"""Fetch only the public FREE file of an itch.io CC0 pack. Never purchases assets."""
import urllib.request, urllib.parse, http.cookiejar, re, json, hashlib, zipfile
from pathlib import Path

CACHE = Path('C:/Dev/Tools/AssetCache'); CACHE.mkdir(parents=True,exist_ok=True)
def fetch(slug,author='kaylousberg'):
    url=f'https://{author}.itch.io/{slug}'
    op=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))
    html=op.open(url).read().decode()
    csrf=re.search(r'name="csrf_token" value="([^"]+)"',html).group(1)
    def post(target,data):
        return json.load(op.open(urllib.request.Request(target,urllib.parse.urlencode(data).encode(),headers={'Referer':url,'X-Requested-With':'XMLHttpRequest'})))
    result=post(url+'/download_url',{'csrf_token':csrf})
    page=op.open(result['url']).read().decode()
    uploads=re.findall(r'data-upload_id="(\d+)".*?<strong[^>]*>(.*?)</strong>',page,re.S)
    free=[(i,n) for i,n in uploads if 'free' in n.lower()]
    if len(free)!=1:raise RuntimeError(f'Expected exactly one explicit FREE upload: {uploads}')
    file_info=post(url+'/file/'+free[0][0],{'csrf_token':csrf})
    target=CACHE/(slug+'.zip')
    with op.open(file_info['url']) as response,target.open('wb') as output:
        while data:=response.read(1024*1024):output.write(data)
    digest=hashlib.sha256(target.read_bytes()).hexdigest()
    dest=CACHE/slug;dest.mkdir(exist_ok=True)
    with zipfile.ZipFile(target) as archive:archive.extractall(dest)
    (CACHE/(slug+'.json')).write_text(json.dumps({'url':url,'file':free[0][1],'sha256':digest},indent=2),encoding='utf-8')
    print(slug,free[0][1],digest)
    print('\n'.join(str(p.relative_to(dest)) for p in dest.rglob('*') if p.suffix.lower() in ['.glb','.gltf','.txt','.md'] )[:4000])
if __name__=='__main__':
    import sys
    for slug in sys.argv[1:]:fetch(slug)
