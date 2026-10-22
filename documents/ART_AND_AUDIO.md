> **Referência V1 / histórico do protótipo.** Para o próximo desenvolvimento, prevalecem [ROADMAP_V2.md](ROADMAP_V2.md), [VISION_3D_V2.md](VISION_3D_V2.md), [GAME_DESIGN_V2.md](GAME_DESIGN_V2.md) e [CONTENT_PLAN_V2.md](CONTENT_PLAN_V2.md). Os marcos novos ainda estão pendentes.

# Direção de arte, sprites e áudio

## 1. Identidade visual

Fantasia estilizada, colorida e levemente rústica. Câmera superior 3/4 com volumes simples, contornos discretos e sombras elípticas. Proporções exageradas ajudam a leitura mobile. Não usar pixel art; trabalhar em raster de alta resolução com aparência pintada, permitindo redução limpa.

### Paleta-base

- Fundo claro quente: `#E8D8A8`
- Verde terreno: `#6F9D55`
- Estrada: `#A8794F`
- UI carvão: `#202832`
- Ouro: `#F2C14E`
- Vida/inimigo: `#D94B4B`
- Construção: `#F29E4C`
- Gelo: `#62C6E8`
- Veneno: `#7AC943`
- Sangramento: `#B9364B`
- Aéreo: `#9B8AFB`

Usar variações por mapa sem mudar as cores semânticas da interface.

## 2. Especificação técnica dos assets

- Formato mestre: PNG RGBA, sRGB, fundo transparente.
- Não incluir texto, moldura, assinatura, watermark ou sombra cortada.
- Importação Godot: filtro ligado para arte pintada; mipmaps conforme escala; atlas quando adequado.
- Pivô de unidade: centro inferior; sombra em camada separada.
- Direções: 8 para inimigos terrestres (`N, NE, E, SE, S, SW, W, NW`).
- Torres: base estática + cabeça/arma rotativa separada quando aplicável.
- Margem interna mínima: 8% do canvas para impedir cortes durante animação.

### Tamanhos mestres

| Categoria | Canvas por frame | Exibição aproximada |
|---|---:|---:|
| Inimigo comum | 192×192 | 56–88 px |
| Chefe | 384×384 | 130–180 px |
| Base de torre | 256×256 | 96–120 px |
| Cabeça de torre | 256×256 | 96–120 px |
| Projétil | 96×96 | 18–42 px |
| Ícone de torre/inimigo | 256×256 | 64–96 px |
| Ícone de status | 128×128 | 28–40 px |
| Tile de terreno | 256×256 | 128 px no jogo |
| Decoração | 256–512 px | variável |

## 3. Manifesto de sprites

### Torres

Para cada `tower_id` e nível 1–3:

- `tower_<id>_base_l<n>.png`
- `tower_<id>_head_l<n>.png` quando rotativa.
- `tower_<id>_build_l<n>_01..06.png` — 6 frames, 8 fps, não loop.
- `tower_<id>_attack_l<n>_01..06.png` — 6 frames, sincronizar disparo no frame 4.
- `icon_tower_<id>.png`

Silhuetas:

- Arqueira: plataforma de madeira, arco duplo; leve e vertical.
- Canhão: base de pedra, tubo largo; pesado e circular.
- Cristal: espiral azul e cristal flutuante; pulsação luminosa.
- Alquimista: caldeirão verde, tubos e frascos; lança glóbulo.
- Balista: braços longos e lâmina serrilhada; perfil pontudo.
- Farol Celeste: obelisco violeta com anéis; feixe/raio para o céu.

Níveis devem preservar a silhueta e adicionar detalhes, altura e energia, nunca trocar a identidade.

### Inimigos

Para cada inimigo:

- `enemy_<id>_walk_<dir>_01..08.png` — 8 frames, 10 fps.
- `enemy_<id>_hurt_<dir>_01..02.png` — opcional; shader flash é preferido.
- `enemy_<id>_death_<dir>_01..08.png` — 8 frames, 12 fps, não loop.
- `icon_enemy_<id>.png`.

Adicionais:

- Flyer: `fly` no lugar de `walk`, sombra separada e animação de asa 8 frames.
- Healer: `cast_<dir>_01..08`, cura emitida no frame 5.
- Boss: caminhada 10 frames, ataque/aura 8 frames e morte 12 frames.

Silhuetas devem diferenciar: runner inclinado e fino; brute largo; armored quadrado; healer alto com cajado; flyer com asas largas; boss ocupa aproximadamente 2× a largura de um grunt.

### Efeitos e projéteis

- Flecha, bola de canhão, estilhaço de gelo, glóbulo venenoso, virote serrilhado e raio antiaéreo.
- Explosão: 10 frames em 384×384, centro legível, sem flash branco em tela cheia.
- Impactos: 6 frames por família.
- Status: ícone + partículas discretas. Máximo visual de partículas reduzido quando há mais de 40 inimigos.
- Canteiro: fundação, andaime e poeira; barra de progresso é UI, não sprite.

### Mapas

Cada mapa exige:

- 1 background master em camadas ou tilemap equivalente.
- Tiles de solo, estrada reta/curvas/interseções, bordas e transições.
- 8–12 decorações não bloqueadoras.
- Entrada, saída, BuildPad vazio/selecionado/ocupado.
- Miniatura 512×288 e tela de seleção 1024×576.

## 4. Prompts reutilizáveis para geração

### Prefixo comum

> Cohesive stylized 2D fantasy mobile tower defense game asset, top-down three-quarter view, hand-painted shapes, clean readable silhouette, subtle dark outline, warm directional light from upper left, saturated but controlled palette, production game sprite, isolated on transparent background, no text, no border, no watermark, centered with generous padding.

### Torre

> [PREFIXO] [NOME E DESCRIÇÃO DA TORRE], upgrade level [1/2/3], separate base and rotating weapon layers, consistent camera angle and scale across the set. Avoid: photorealism, isometric side view, cropped weapon, baked ground shadow, UI frame.

### Inimigo

> [PREFIXO] [NOME E DESCRIÇÃO DO INIMIGO], facing [DIREÇÃO], full body, animation-ready neutral walk pose, consistent proportions and costume across eight directions. Avoid: perspective drift, changing equipment, detailed background, cropped limbs.

### Ícone

> Stylized mobile game icon of [OBJETO], bold silhouette, centered, charcoal circular backing, semantic accent color [COR], high contrast at 32 pixels, no letters, no numbers, no watermark.

### Mapa

> Stylized 2D fantasy tower defense battlefield, top-down three-quarter view, [TEMA], clear winding road with width consistency, [QUANTIDADE] circular build pads beside the road, readable entry and exit, no units, no towers, no UI, landscape 16:9 composition, mobile readability, layered environment art.

Salvar cada prompt concreto em `art/prompts/<asset_id>.md`, incluindo seed/model quando disponível.

## 5. UI

- Componentes em 9-slice: painel, botão primário/secundário, cartão, tooltip e barra.
- Ícones precedem texto; estados disabled continuam legíveis.
- Botões de batalha com área mínima de toque 96×96 na base.
- Fonte recomendada: uma família OFL com boa leitura e suporte a português; registrar arquivo e licença.
- Números monetários usam tabular figures se disponíveis.

Telas obrigatórias: splash, menu, seleção de mapa, seleção de dificuldade, batalha, pausa, resultado, configurações e créditos/licenças.

## 6. Áudio

### Música

- Menu: loop calmo de 90–120 s.
- Batalha por bioma: 3 loops de 120–180 s.
- Camada de chefe: percussão sincronizável que entra por crossfade.
- Stingers: vitória e derrota, 3–5 s.

### SFX

Construção início/fim, upgrade, venda, moeda, erro, clique, início de onda, vazamento, cada família de torre, seis tipos de impacto, aplicação de status, morte por classe, chefe e resultado. Gerar 2–4 variações de sons repetitivos, com pequena variação de pitch.

### Mixagem

Buses: `Master`, `Music`, `SFX`, `UI`. Limitar picos; no máximo 12 SFX de combate simultâneos, priorizando disparos próximos/fortes e UI. Configuração persiste de 0 a 100%.

## 7. Licenças

Todo asset deve ter origem registrada. Fontes e áudios externos precisam permitir distribuição comercial. A tela de créditos lê dados de `art/ASSET_SOURCES.md`. Assets temporários recebem prefixo `placeholder_` e não podem entrar no build de release.

