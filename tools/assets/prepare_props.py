"""Exports the extra KayKit Forest (CC0) props used by the redesigned maps, reusing prepare_3d's glTF packer."""
from prepare_3d import locate, read, write, OUT
PROPS = ['Tree_1_B_Color1', 'Tree_2_A_Color1', 'Tree_4_A_Color1', 'Tree_4_B_Color1', 'Tree_Bare_1_A_Color1', 'Tree_Bare_2_A_Color1',
         'Bush_1_C_Color1', 'Bush_3_A_Color1', 'Bush_4_A_Color1', 'Rock_1_D_Color1', 'Rock_3_A_Color1', 'Rock_3_C_Color1', 'Rock_3_F_Color1', 'Grass_2_A_Color1']
if __name__ == '__main__':
    for name in PROPS:
        data, binary = read(locate('kaykit-forest', name + '.gltf'))
        write(OUT / (name + '.glb'), data, binary)
        print('exported', name)
