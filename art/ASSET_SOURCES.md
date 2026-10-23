# Fontes e licenças de assets — Iron Path

Todo asset externo deve ter sua origem documentada aqui. Assets temporários usam prefixo `placeholder_`.

## Formato

| Asset | Origem | Licença | Arquivo | Notas |
|-------|--------|---------|---------|-------|
| (nenhum asset externo em M0) | — | — | — | — |

## Fontes tipográficas

| Fonte | Origem | Licença | Arquivo |
|-------|--------|---------|---------|
| (a definir em M6) | — | — | — |

## Áudio

| Arquivo | Origem | Licença | Notas |
|---------|--------|---------|-------|
| (a definir em M6) | — | — | — |

## Placeholders geométricos de teste — 2026-10-19

`art/placeholders/*.svg`: formas simples criadas neste projeto para visualizar terreno, pad, Arqueira, grunt e flecha. Sem recursos externos. Uso temporário de desenvolvimento; substituir antes do release.

## Sprites do protótipo — 2026-10-19

| Arquivo | Origem | Uso / direitos | Notas |
|---|---|---|---|
| `art/sprites/tower_archer_l1.png` | Gerado pela ferramenta imagegen integrada para este projeto | Conteúdo gerado por IA, sujeito aos termos do serviço; sem licença externa de terceiros | PNG com alpha; prompt em `art/prompts/tower_archer_l1.md` |
| `art/sprites/enemy_grunt.png` | Gerado pela ferramenta imagegen integrada para este projeto | Conteúdo gerado por IA, sujeito aos termos do serviço; sem licença externa de terceiros | PNG com alpha; prompt em `art/prompts/enemy_grunt.md` |

Sprites estáticos para teste, sem representar o conjunto final de animações/direções de M6.

## Terreno e caminhada 2.5D — 2026-10-19

| Arquivo | Origem | Uso / direitos | Notas |
|---|---|---|---|
| `art/maps/vale_verde_terrain.png` | imagegen integrada, criado para este projeto | Conteúdo gerado por IA, sujeito aos termos do serviço; sem licença externa de terceiros | Terreno pintado; rota desenhada separadamente pelo Godot. Prompt em `art/prompts/vale_verde_terrain.md` |
| `art/sprites/enemy_grunt_walk.png` | imagegen integrada, derivado do goblin gerado para o projeto | Conteúdo gerado por IA, sujeito aos termos do serviço; sem licença externa de terceiros | Quatro quadros em atlas 2 × 2; uma orientação espelhável. Prompt em `art/prompts/enemy_grunt_walk.md` |

A base de pedra em `art/placeholders/pad.svg` foi redesenhada com formas vetoriais próprias. Sombras, estrada e recuo são apresentação gerada pelo código. A caminhada inicial não substitui o conjunto final de oito direções, morte e ataque de M6.

## Pipeline 3D P0/P1 — 2026-10-19

- **Autor original:** Kay Lousberg / KayKit. Licença CC0, confirmada nas páginas oficiais e nos arquivos de licença incluídos. Não houve compra nem uso dos tiers EXTRA/SOURCE.
- **Adventurers 2.0 FREE:** https://kaylousberg.com/game-assets/characters-adventurers e https://kaylousberg.itch.io/kaykit-adventurers. Personagens Rogue_Hooded e Ranger; acessórios bow_withString, arrow_bow e quiver.
- **Character Animations 1.1 FREE:** https://kaylousberg.com/game-assets/character-animations e https://kaylousberg.itch.io/kaykit-character-animations. Clipes de movimento, idle, reação, morte e arco compatíveis com Rig_Medium.
- **Forest Nature 1.0 FREE:** https://kaylousberg.com/game-assets/forest-nature-pack e https://kaylousberg.itch.io/kaykit-forest. Oito modelos selecionados de árvore, arbusto, rocha e grama.
- **Licenças preservadas:** `art/licenses/kaykit-*.txt`. Os nomes dos arquivos e hashes dos arquivos compilados/pacotes estão em `art/models/manifest.json`.
- **Adaptações do projeto:** junção dos clipes por nomes de ossos, orelhas de goblin ligadas ao rig, materiais/shaders de cor, peças da torre, estrada e cena geradas pelo código. O goblin é uma adaptação do Rogue_Hooded, ainda em prova visual, e não um modelo original completo alegadamente criado do zero.
- **Reprodução:** `tools/assets/fetch_free_packs.py`, `tools/assets/prepare_3d.py` e `tools/assets/blender_roundtrip.py`. Cache dos pacotes originais em `C:/Dev/Tools/AssetCache`; fonte Blender editável de verificação em `source_assets/goblin_pipeline.blend`.
- **Limite de qualidade:** assets CC0 e pipeline importável não significam que o acabamento artístico final foi aprovado. Esta arena é P0/P1 e exige refinamento e revisão em movimento.

### Geometria própria V2 — 2026-10-19

Canhão, emissores mágicos, módulos de upgrade, moinho, portões, pomar, pontes, vespa e rastejante são geometria 3D criada nos scripts `scripts/presentation3d/`. Materiais de cor e malhas procedurais próprias; sem bitmap de personagem ou origem externa adicional. Goblin/Ranger e vegetação continuam com a proveniência CC0 descrita acima. A galeria de inspeção pode usar recursos de fixture e é identificada como tal.

### Personagens P6/P7 — 2026-10-20
Guardian/Knight, Captain/Barbarian e Shaman/Mage adaptam os mesmos pacotes KayKit CC0 licenciados acima, com orelhas e combinação de clipes. Espada, escudo, machado e staff vêm do mesmo Adventurers FREE. Pipeline incremental em tools/assets/prepare_enemy_models.py e prepare_canyon_models.py; checkpoints Blender editáveis em source_assets/{guardian,captain,shaman}_pipeline.blend. Hashes em art/models/manifest.json; sem nova licença externa. Ombreiras do Elite e paredões estratificados do cânion são geometria própria.

Áudio do cânion: música e vento sintetizados originalmente em tools/assets/compose_canyon.py; sem gravações ou samples externos. Fontes editáveis e WAV em source_assets/audio; hashes, seed e parâmetros em art/audio/canyon_manifest.json.

Colosso P7: geometria original de pedra chanfrada/bronze construída em scripts/presentation3d/colossus_actor.gd sobre o esqueleto/clipes CC0 já licenciados. Corpo KayKit é ocultado; partes originais seguem BoneAttachment3D. Cues originais de combate/interface: tools/assets/compose_sfx.py e art/audio/sfx/manifest.json, síntese analítica e ruído com seed; nenhum sample externo.


P8: coroas rúnicas, ruínas, solo de emergência e corpo do Guardião da Ruína são geometria original do projeto em scripts/presentation3d. Reutilizam apenas os rigs/clipes KayKit CC0 já documentados. Música e ambiente do Pântano sintetizados originalmente em tools/assets/compose_swamp.py, sem samples; manifesto art/audio/swamp_manifest.json, fontes WAV source_assets/audio.

P9/P10: água animada, pedras de margem e monumentos por fase gerados pelo código original; ícone/splash vetoriais originais em art/branding. Sem fontes ou recursos externos adicionais.

P10: splash PNG e ícone PNG rasterizados dos SVG próprios com tools/assets/render_branding.gd. Notices do Godot e dependências exportados pelas APIs Engine.get_license_text/get_copyright_info/get_license_info em tools/assets/export_engine_notices.gd e preservados em art/licenses/godot-engine.txt.

### Interface mobile — 2026-10-22
- `art/ui/backdrop_vale.jpg`, `backdrop_canyon.jpg`, `backdrop_swamp.jpg`: capturas do próprio jogo (fases 4, 7 e 10 com torres e inimigos posicionados), geradas por `tools/render_menu_art.gd`. Mesma licença dos modelos usados (KayKit CC0 + geometria própria).
- `art/ui/tower_*.jpg`: retratos das oito famílias em L3, renderizados pelo mesmo script no Laboratório do Arsenal.
- `art/ui/icons/*.svg`: ícones vetoriais desenhados para o projeto (voltar, fechar, engrenagem, livro, informação, estrela, cadeado, jogar, troféu, frasco).
- `art/branding/intro_logo.ogv`: conversão para Theora/Vorbis de `animated-logo.mp4` (logo do estúdio fornecido pelo usuário), com áudio normalizado e final estendido.

### Rodada 2 — 2026-10-23
- `art/fonts/LilitaOne-Regular.ttf`: Lilita One, de Juan Montoreano, SIL Open Font License 1.1 (`art/fonts/OFL-LilitaOne.txt`), baixada de github.com/google/fonts com autorização do usuário.
- `art/models/` (Tree_1_B, Tree_2_A, Tree_4_A/B, Tree_Bare_1_A/2_A, Bush_1_C/3_A/4_A, Rock_1_D/3_A/3_C/3_F, Grass_2_A): KayKit Forest Nature Pack 1.0 FREE (CC0), já no cache local, exportados por `tools/assets/prepare_props.py`.
- `art/ui/skins/*.svg` e novos ícones em `art/ui/icons/` (coração, moeda, pausa, velocidade, casa, reiniciar, ajuda, escudo): desenhados para o projeto.
- `art/sprites3d/*.png|json`: sprites renderizados no ângulo da câmera do jogo (Blender 4.5 portátil, `tools/assets/render_sprites.py`) a partir de modelos CC0 do Poly Haven: island_tree_01, island_tree_02, shrub_01, shrub_02, shrub_04, fern_02, grass_medium_02, celandine_01, dandelion_01, rock_moss_set_01, boulder_01, dead_tree_trunk_02, root_cluster_01 (fontes em polyhaven.com/a/<nome>, baixadas por `tools/assets/fetch_polyhaven.py` com autorização do usuário em 2026-10-23).
- `art/textures/*.jpg`: texturas CC0 do Poly Haven em 1k (aerial_grass_rock, forrest_ground_01, rocky_trail, wood_planks_grey).
