# Iron Path — visão 3D e padrão de qualidade

Versão 2 · 2026-10-19 · Planejamento, ainda não implementado.

## 1. O jogo que queremos produzir

Um tower defense de fantasia com personagens, torres e terreno realmente tridimensionais, vistos por uma câmera fixa elevada. A leitura e os comandos continuam tão simples quanto em um jogo 2D: tocar em uma base, escolher uma torre, melhorar a defesa e acompanhar os inimigos pela estrada.

O objetivo visual é um pequeno diorama vivo: personagens com peso, materiais coerentes, sombras de contato, vegetação com movimento discreto e ataques satisfatórios. A qualidade deve aparecer também quando a câmera está parada e não há efeitos na tela.

A instrução do usuário define como requisitos: modelos realmente 3D; visão com leitura 2D; movimentos naturais; variedade de fases, torres, evoluções, inimigos e ondas; ondas automáticas depois da primeira. As quantidades, nomes e números deste pacote são propostas iniciais de produção e balanceamento, sujeitos a testes.

Este documento e os demais arquivos V2 substituem as orientações incompatíveis da especificação V1. O protótipo existente permanece como referência funcional, sem ser apresentado como a versão 3D já pronta.

## 2. Escolha de apresentação

- Mundo em `Node3D`, chão no plano XZ, altura no eixo Y.
- Câmera `Camera3D` ortográfica, fixa e elevada. Inclinação inicial de teste: 45–55 graus em relação ao chão; escolher um enquadramento canônico no primeiro marco.
- Personagens com malha, esqueleto, materiais e animações. Torres com peças móveis e personagens operadores quando contribuírem para a leitura.
- HUD em 2D sobre o mundo; barras de vida e indicadores projetados a partir de pontos de ancoragem 3D.
- Rotas predeterminadas; altura visual não cria regras de alcance ocultas.
- Sem câmera livre ou rotação obrigatória durante a partida. Zoom limitado é opcional, nunca necessário para construir ou reconhecer inimigos.
- Toda a área jogável deve ser legível no enquadramento mínimo 16:9; telas mais largas podem revelar margem decorativa, sem oferecer vantagem de alcance.

A projeção ortográfica mantém o tamanho aparente dos objetos independentemente da distância à câmera. A escolha é adequada à leitura proposta; é uma decisão de projeto apoiada no recurso de câmera do Godot, não uma promessa de qualidade automática. [Camera3D — documentação oficial](https://docs.godotengine.org/en/4.5/classes/class_camera3d.html).

## 3. Por que a animação atual não atende

O protótipo usa imagens de poses separadas em uma grade. Há diferenças de proporção e posição entre quadros, uma única vista espelhada e poucas amostras do movimento. A interpolação de posição do sprite não resolve deformação, passada ou mudança de direção.

A nova abordagem precisa de um personagem contínuo, com ossos e transições entre movimentos. A imagem gerada pode servir como conceito, referência de cor e silhueta; ela não entrega automaticamente malha pronta, topologia, UV, rig ou animação utilizável.

## 4. Direção de arte

**Estilo:** fantasia estilizada com formas esculpidas, materiais pintados e acabamento limpo. Volume real, proporções expressivas e detalhes suficientes para telas pequenas. Evitar realismo fotográfico e excesso de microdetalhes que desaparecem na câmera de jogo.

**Personagens:** cabeça e mãos ligeiramente ampliadas, pernas e armas legíveis, silhuetas distintas para rápido, tanque, suporte e chefe. Unidades comuns devem ter tamanho de leitura aproximado de 56–88 px na base 1920×1080; chefes podem ocupar 130–180 px. Ajustar na cena, não apenas no render de apresentação.

**Torres:** identidade reconhecível em qualquer nível. Melhorias adicionam estrutura, mecanismo e energia visual. A especialização deve ser identificável pela silhueta e pelo disparo, inclusive com cores reduzidas.

**Materiais:** madeira, pedra, metal, tecido, pele e magia com respostas diferentes à luz. Paleta e intensidade de luz compartilhadas entre todos os assets. Evitar personagens brilhantes demais sobre terreno fosco, escalas divergentes ou fontes de luz pintadas incompatíveis com a cena.

**Cenários:** chão tridimensional modular; curvas de estrada suaves, bordas naturais, transições de vegetação, pontes e diferenças de altura decorativas. O terreno deve ter composição, pontos de interesse e espaços de descanso visual. Usar os três biomas da campanha como famílias de materiais e iluminação, não apenas troca de cor.

**Legibilidade:** a estrada e os inimigos têm mais contraste que o fundo. Árvores e ruínas altas ficam fora das zonas de combate; objetos que encobrirem ação devem ser removidos, reposicionados ou receber tratamento de transparência validado no renderer. Nada de inimigos escondidos atrás da torre, sombra confundida com rota ou partículas cobrindo o alvo.

## 5. Pipeline de modelos

1. Concept e folha de proporções: frente, lado e três quartos; câmera de jogo e paleta já definidas.
2. Modelo de trabalho com escala padronizada: 1 unidade de mundo = 1 metro; origem nos pés ou no centro da fundação.
3. Topologia apropriada à deformação, UV, materiais e texturas organizadas.
4. Rig humanoide compartilhável quando a anatomia permitir; rigs próprios para insetos, criaturas grandes e voadores.
5. Animação e revisão de contato dos pés, arma e tecido.
6. Exportação `.glb`, importação no Godot e cena envoltória para lógica, colisão e efeitos.
7. Verificação de orientação, escala, materiais, looping, nomes de ossos e anexos de arma.
8. Revisão na câmera real, com combate e HUD, seguida de teste no dispositivo de referência.

Preservar arquivos-fonte editáveis e arquivos de exportação. Reimportar um modelo não pode destruir componentes de gameplay. O Godot oferece importação de cenas 3D e animações; priorizar glTF no pipeline proposto. [Formatos 3D — documentação oficial](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html).

A produção exige modelagem e animação, por criação própria, artista ou biblioteca licenciada coerente. Não contabilizar conceitos gerados como modelos finalizados. Registrar autor, origem, licença de redistribuição, modificações e arquivo-fonte em `art/ASSET_SOURCES.md`. Compras de assets dependem de orçamento explicitamente definido; este plano não autoriza compras.

## 6. Movimento natural

### Locomoção

- Caminhada e corrida com passada, apoio dos pés, transferência de peso, balanço de braços e movimento secundário de tecido/arma.
- Ciclo contínuo; o último instante deve conectar ao primeiro sem salto de pose.
- Animação esquelética interpolada a partir do tempo, independente do número de imagens desenhadas. Não tentar corrigir o problema atual apenas aumentando uma grade de sprites.
- Animações no lugar, com avanço do corpo controlado pela simulação. Cadência visual acompanha a velocidade real dentro de uma faixa plausível; trocar caminhada por corrida quando necessário.
- Transição inicial de referência de 0,10–0,20 s; ajustar pelo peso da unidade.
- Orientação acompanha a tangente da rota com giro suave do modelo. A trajetória lógica permanece previsível; não usar física de multidão que bloqueie a estrada.
- Pontos de curva desenhados com raio e continuidade. Evitar mudanças instantâneas de 90 graus e pés deslizando nas curvas.
- Variações discretas e determinísticas de fase da passada e pose inicial para grupos não marcharem sincronizados.
- Offset lateral pequeno por unidade, limitado à largura útil da estrada; posição usada para mira e dano deve acompanhar a posição efetiva.
- Inimigos não são espelhados como imagem: o modelo gira e continua consistente em todos os sentidos.

### Estados mínimos

| Família | Animações necessárias |
|---|---|
| Humanoide comum | idle, walk, run quando aplicável, reação curta em camada, death, escape |
| Tanque | caminhada pesada, preparação de habilidade, habilidade, impacto e morte com peso |
| Curandeiro | locomoção, preparação/cast/recuperação de cura, interrupção visual |
| Voadores | voo, mudança de direção, reação, queda/morte; sombra comunica altitude |
| Chefes | entrada curta, locomoção, preparação/execução/recuperação por habilidade, transições e morte |
| Operadores de torre | idle, mirar, preparar, atacar e recuperar; reações discretas à construção |

Reação de dano comum não interrompe locomoção, habilidade nem dano lógico. Morte encerra a entidade de combate imediatamente; o corpo pode permanecer por 0,5–1,5 s no pool visual sem segurar o fim da onda. Vazamento tem resolução própria e não usa a recompensa de morte.

### Ataques

O tiro deve ter preparação, liberação, impacto e recuperação. Arco flexiona; corda solta; canhão recua no trilho; operador estabiliza; projétil sai do ponto da arma; alvo recebe feedback localizado. Não sacudir a torre inteira como substituto de animação mecânica.

O relógio da simulação decide quando um ataque válido é liberado. A apresentação acompanha esse evento; não pode criar um segundo dano por callback de animação. Interromper, vender ou melhorar antes da liberação cancela o disparo; depois da liberação, o projétil existente continua. Pausa e 2× devem manter apresentação e simulação sincronizadas.

`AnimationPlayer` organiza os clipes; `AnimationTree` organiza misturas e estados. [AnimationTree — documentação oficial](https://docs.godotengine.org/en/4.5/tutorials/animation/animation_tree.html). Os parâmetros e tempos acima são metas de projeto a validar na produção.

## 7. Luz, cenário vivo e efeitos

- Luz principal consistente, preenchimento suave e sombras de contato. Evitar sombras pretas que apaguem pernas e inimigos.
- Iluminação estática preparada quando adequada, com solução dinâmica limitada para personagens e torres; confirmar suporte e custo no renderer escolhido.
- Vegetação com vento leve, água com movimento de superfície, rodas/engrenagens, bandeiras e brasas como pontos de vida. Não mover a cena inteira nem usar vento igualmente forte em tudo.
- Projéteis legíveis e rápidos; trilhas curtas, impactos por material e área de efeito claramente delimitada.
- Gelo, veneno e sangramento com ícones e efeitos locais distintos; nenhuma regra depende só da cor.
- Chefe anuncia golpe com forma no chão, animação e som. Aviso continua legível no perfil gráfico baixo.
- Câmera sem tremor contínuo. Pequeno impacto em evento importante é opcional e desativável.
- Construção mostra fundação, andaime, progresso e conclusão; a torre só ataca quando a simulação a libera.

## 8. Som e sensação

Música por bioma com camadas discretas de perigo e chefe, variações de disparo, passos por material, som de vazamento e confirmação de compra. Avisos de ar/chefe devem ser percebidos sem poluir a tela. Limitar sons simultâneos; UI e eventos importantes têm prioridade sobre tiros repetidos.

Disponibilizar volumes separados, redução de flashes e movimento, tremor de câmera desligável e vibração opcional. Uma sessão silenciosa deve continuar compreensível.

## 9. Orçamento inicial de produção e desempenho

Manter Godot 4 e renderer Mobile na primeira prova. A compatibilidade dos efeitos será confirmada no dispositivo, sem assumir equivalência entre renderers. [Renderers — documentação oficial](https://docs.godotengine.org/en/4.5/tutorials/rendering/renderers.html).

Metas iniciais, sem afirmar medição existente:

| Item | Orçamento inicial proposto |
|---|---|
| Inimigo comum | 2–6 mil triângulos no LOD principal; um atlas/material principal sempre que possível |
| Torre | 4–10 mil triângulos, peças modulares para evolução |
| Chefe | 10–20 mil triângulos, efeitos e sombras revisados separadamente |
| Texturas | 512–1024 px por conjunto comum; 2048 apenas quando diferença na câmera justificar |
| Animação | 20–40 ossos em humanoides comuns; rigs maiores exigem perfil |
| Cenário de estresse | 120 inimigos, 30 torres e até 150 projéteis/efeitos, em 1× e 2× |
| Desempenho | alvo 60 FPS; perfil mínimo estável a 30 FPS no aparelho de referência |

São limites de partida para perfil, não garantia de desempenho. Escolher Android de referência antes de produzir a campanha; GPU de PC não certifica mobile. Medir tempo de CPU/GPU, memória, aquecimento e duração de sessão. Ajustar LOD, sombras, transparências, resolução e partículas mantendo as regras de combate.

## 10. Critério de qualidade antes de expandir conteúdo

Uma cena demonstrativa deve mostrar o goblin de todos os lados, ida e volta, curvas, slow, pausa, 2×, reação e morte; uma Arqueira deve mirar e disparar com liberação sincronizada. O cenário deve manter qualidade e leitura sob combate real, inclusive no perfil mínimo.

A revisão compara uma gravação na câmera do jogo com a direção pretendida, não apenas o personagem em close. Não liberar produção em massa se houver salto de ciclo, pés patinando, escala inconsistente, contagem de tiro divergente ou desempenho abaixo do piso. O marco de qualidade vem antes de criar dezenas de unidades.
