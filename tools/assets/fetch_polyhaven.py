"""Downloads CC0 Poly Haven assets (glTF 1k models, 1k JPG textures) into the shared asset cache.
No account or payment involved; every file comes from the public api.polyhaven.com file listing."""
import json, sys, urllib.request
from pathlib import Path

CACHE = Path('C:/Dev/Tools/AssetCache/polyhaven')

def get(url):
    return urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': 'IronPathAssetFetch/1.0'})).read()

def save(url, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    if not target.exists(): target.write_bytes(get(url))

def model(slug):
    files = json.loads(get(f'https://api.polyhaven.com/files/{slug}'))
    entry = files['gltf']['1k']['gltf']
    folder = CACHE / slug
    save(entry['url'], folder / Path(entry['url']).name)
    for name, include in entry.get('include', {}).items(): save(include['url'], folder / name)
    return folder

def texture(slug):
    files = json.loads(get(f'https://api.polyhaven.com/files/{slug}'))
    folder = CACHE / slug
    for kind in ('Diffuse', 'nor_gl', 'Rough'):
        if kind in files: save(files[kind]['1k']['jpg']['url'], folder / f'{kind}.jpg')
    return folder

if __name__ == '__main__':
    kind = sys.argv[1]
    for slug in sys.argv[2:]:
        print((model if kind == 'model' else texture)(slug), flush=True)
