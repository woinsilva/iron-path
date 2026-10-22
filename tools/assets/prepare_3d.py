"""Reproducible glTF pipeline. Sources are the FREE CC0 KayKit packages.
No network access, Blender add-ons or paid content required for this build step.
"""
from pathlib import Path
import json, struct, copy, math, shutil, hashlib
ROOT=Path(__file__).resolve().parents[2]
CACHE=Path('C:/Dev/Tools/AssetCache')
OUT=ROOT/'art/models'; OUT.mkdir(parents=True,exist_ok=True)

def locate(pack,pattern):
    files=list((CACHE/pack).rglob(pattern))
    if len(files)!=1:raise RuntimeError(f'Ambiguous/missing {pack}/{pattern}: {files}')
    return files[0]

def read(path):
    if path.suffix=='.glb':
        raw=path.read_bytes(); size=struct.unpack_from('<I',raw,12)[0]
        data=json.loads(raw[20:20+size]); binary=bytearray(raw[28+size:])
        return data,binary
    data=json.loads(path.read_text(encoding='utf-8'))
    binary=bytearray(); offsets=[]
    for buffer in data['buffers']:
        while len(binary)%4:binary.append(0)
        offsets.append(len(binary));binary.extend((path.parent/buffer['uri']).read_bytes())
    for view in data.get('bufferViews',[]):
        view['byteOffset']=view.get('byteOffset',0)+offsets[view.get('buffer',0)];view['buffer']=0
    for image in data.get('images',[]):
        if 'uri' in image:
            name=image.pop('uri');image_bytes=(path.parent/name).read_bytes()
            while len(binary)%4:binary.append(0)
            image['bufferView']=len(data.setdefault('bufferViews',[]))
            image['mimeType']='image/png' if name.lower().endswith('.png') else 'image/jpeg'
            data['bufferViews'].append({'buffer':0,'byteOffset':len(binary),'byteLength':len(image_bytes)})
            binary.extend(image_bytes)
    data['buffers']=[{'byteLength':len(binary)}]
    return data,binary

def write(path,data,binary):
    data['buffers']=[{'byteLength':len(binary)}]
    raw=json.dumps(data,separators=(',',':')).encode('utf-8')
    raw+=b' '*((-len(raw))%4);binary+=b'\0'*((-len(binary))%4)
    total=12+8+len(raw)+8+len(binary)
    path.write_bytes(struct.pack('<III',0x46546c67,2,total)+struct.pack('<II',len(raw),0x4e4f534a)+raw+struct.pack('<II',len(binary),0x004e4942)+binary)

def merge_clips(target,binary,source,clips):
    data,blob=read(source)
    while len(binary)%4:binary.append(0)
    base=len(binary);binary.extend(blob)
    vo=len(target.get('bufferViews',[]));ao=len(target.get('accessors',[]))
    for view in data.get('bufferViews',[]):
        view=copy.deepcopy(view);view['buffer']=0;view['byteOffset']=view.get('byteOffset',0)+base
        target.setdefault('bufferViews',[]).append(view)
    for accessor in data.get('accessors',[]):
        accessor=copy.deepcopy(accessor)
        if 'sparse' in accessor:raise RuntimeError('Sparse accessor requires explicit remapping')
        if 'bufferView' in accessor:accessor['bufferView']+=vo
        target.setdefault('accessors',[]).append(accessor)
    names={node.get('name'):index for index,node in enumerate(target['nodes'])}
    for old,new in clips.items():
        animation=copy.deepcopy(next(a for a in data['animations'] if a['name']==old));animation['name']=new
        for sampler in animation['samplers']:
            sampler['input']+=ao;sampler['output']+=ao
        for channel in animation['channels']:
            node_name=data['nodes'][channel['target']['node']]['name']
            if node_name not in names:raise RuntimeError(f'Incompatible rig: {node_name}')
            channel['target']['node']=names[node_name]
        target.setdefault('animations',[]).append(animation)

def append_array(data,binary,values,fmt,kind):
    while len(binary)%4:binary.append(0)
    base=len(binary)
    for row in values:binary.extend(struct.pack('<'+fmt,*row))
    view=len(data.setdefault('bufferViews',[]));data['bufferViews'].append({'buffer':0,'byteOffset':base,'byteLength':len(binary)-base})
    accessor={'bufferView':view,'componentType':5126 if fmt[0]=='f' else 5123,'count':len(values),'type':kind}
    if kind=='VEC3' and fmt[0]=='f':
        accessor['min']=[min(v[i] for v in values) for i in range(3)];accessor['max']=[max(v[i] for v in values) for i in range(3)]
    index=len(data.setdefault('accessors',[]));data['accessors'].append(accessor);return index

def goblin_ears(data,binary):
    material=len(data.setdefault('materials',[]));data['materials'].append({'name':'Goblin_Olive_Skin','pbrMetallicRoughness':{'baseColorFactor':[0.38,0.53,0.15,1],'metallicFactor':0,'roughnessFactor':0.85},'doubleSided':True})
    head=next(i for i,n in enumerate(data['nodes']) if n.get('name')=='head');joint=data['skins'][0]['joints'].index(head)
    vertices=[]
    for side in [-1,1]:
        a=(side*0.43,1.72,0.12); b=(side*0.93,1.97,0.03);c=(side*0.48,1.46,0.18);d=(side*0.48,1.69,0.26)
        vertices.extend([a,b,d,b,c,d,c,a,d])
    attrs={'POSITION':append_array(data,binary,vertices,'fff','VEC3'),'NORMAL':append_array(data,binary,[(0,0,1)]*len(vertices),'fff','VEC3'),'JOINTS_0':append_array(data,binary,[(joint,0,0,0)]*len(vertices),'HHHH','VEC4'),'WEIGHTS_0':append_array(data,binary,[(1,0,0,0)]*len(vertices),'ffff','VEC4')}
    mesh=len(data['meshes']);data['meshes'].append({'name':'Goblin_Ears','primitives':[{'attributes':attrs,'material':material}]})
    node=len(data['nodes']);data['nodes'].append({'name':'Goblin_Ears','mesh':mesh,'skin':0})
    rig=next(n for n in data['nodes'] if n.get('name')=='Rig_Medium');rig.setdefault('children',[]).append(node)

def character(source,name,goblin=False):
    data,binary=read(locate('kaykit-adventurers',source+'.glb'))
    if goblin:goblin_ears(data,binary)
    anim='kaykit-character-animations'
    merge_clips(data,binary,locate(anim,'Rig_Medium_MovementBasic.glb'),{'Walking_A':'walk','Running_A':'run'})
    merge_clips(data,binary,locate(anim,'Rig_Medium_General.glb'),{'Idle_A':'idle','Hit_A':'hit','Death_A':'death'})
    if name=='ranger':
        merge_clips(data,binary,locate(anim,'Rig_Medium_CombatRanged.glb'),{'Ranged_Bow_Draw':'draw','Ranged_Bow_Release':'release','Ranged_Bow_Aiming_Idle':'aim'})
    write(OUT/(name+'.glb'),data,binary)
    return {'file':name+'.glb','joints':len(data['skins'][0]['joints']),'clips':[a['name'] for a in data['animations']]}

if __name__=='__main__':
    report={'characters':[character('Rogue_Hooded','goblin',True),character('Ranger','ranger')]}
    names=['Tree_1_A_Color1','Tree_2_B_Color1','Tree_3_A_Color1','Bush_1_A_Color1','Bush_2_C_Color1','Rock_1_A_Color1','Rock_2_A_Color1','Grass_1_A_Color1']
    for name in names:
        p=locate('kaykit-forest',name+'.gltf');data,binary=read(p);write(OUT/(name+'.glb'),data,binary)
    for name in ['bow_withString','arrow_bow','quiver']:
        data,binary=read(locate('kaykit-adventurers',name+'.gltf'));write(OUT/(name+'.glb'),data,binary)
    licenses=ROOT/'art/licenses';licenses.mkdir(exist_ok=True)
    for pack in ['kaykit-adventurers','kaykit-character-animations','kaykit-forest']:
        shutil.copyfile(locate(pack,'License.txt'),licenses/(pack+'.txt'))
    report['sources']=[json.loads((CACHE/(name+'.json')).read_text(encoding='utf-8-sig')) for name in ['kaykit-adventurers','kaykit-character-animations','kaykit-forest']]
    report['files']={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in OUT.glob('*.glb')}
    (OUT/'manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report['characters'],indent=2))
