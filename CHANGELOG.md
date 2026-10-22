# Changelog — Iron Path

Todas as mudanças notáveis do projeto são documentadas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).

## [Unreleased] — 2026-10-19

### Fase 5 — torres: alcance, L6 lendário e visual por nível (2026-10-22)
- Alcance cresce de verdade com a evolução: do L1 ao L5 +35% a +45% nas torres de longa distância e +20% a +30% nas de área curta e suporte (ex.: Arqueira 4,2 → 6,0 m; Antiaérea 4,9 → 7,0 m). L1 ficou igual.
- Novo nível L6 lendário em cada ramo (16 configurações novas): +35% de dano, alcance extra e +1 alvo/encadeamento/projétil onde se aplica, por 1,5× o custo do L5.
- Evolução liberada mais cedo: L3 nas fases 1–2, L4 nas 3–4, L5 nas 5–8 e L6 nas 9–12 e no Laboratório.
- Visual: losangos dourados sobre a torre, um por nível (violeta no L6); coroa dourada e gemas no L5; auréola de runas girando e partículas no L6; animação de "mola" com onda de poeira ao concluir uma evolução; anel dourado mostra o alcance que a próxima evolução compra.

### Fase 4 — inimigos sem atravessar uns aos outros (2026-10-22)
- A estrada tem três faixas (0,6 m entre elas, dentro dos 2,1 m de largura). Quem alcança alguém mais lento desvia para uma faixa livre e ultrapassa pelo lado; com todas ocupadas, espera atrás sem andar para trás. Voadores formam fila própria.
- Regras de alcance, área e vazamento continuam usando a linha central da estrada, então nenhuma torre perde alcance por causa das faixas; só o corpo desenhado se desloca (`BattleSimV2.display_position`).
- Determinístico e idêntico em 1× e 2×; parâmetros em `core.json` (`movement`). Novo teste `test_lanes.gd` cobre sobreposição, fila, largura da estrada, determinismo e velocidade dupla.

### Fase 3 — progressão consistente das ondas (2026-10-22)
- Nota de ameaça por onda (vida efetiva com armadura, resistência, escudo e suporte, velocidade, voo e densidade), com pesos em `data/campaign/wave_curve.json`.
- `tools/wave_curve.py` reorganizou as 12 fases: ondas vizinhas trocam de lugar (no máximo duas posições, sem antecipar a estreia de nenhum inimigo) e as contagens foram reescaladas para que nenhuma onda seja mais fraca que a anterior. Antes havia 79 quedas.
- A ameaça total de cada fase ficou igual à escrita, exceto nas fases 3 (76%), 4 (96%), 8 (84%, reajustada com as faixas da Fase 4 e os níveis da Fase 5) e 9 (84%), suavizadas até as defesas de referência voltarem a vencer.
- A verificação da curva entrou em `run.ps1`; os testes das fases leem o total de inimigos dos dados (`StageSessionV2.authored_enemy_count`) em vez de números fixos.

### Fase 2 — menus no estilo de app de celular (2026-10-22)
- Tela inicial com o Vale ao fundo em movimento lento, logo grande, botão JOGAR e ícones redondos para Guia, Ajustes e Créditos.
- Mapa da campanha com os três biomas lado a lado (arrastar para navegar), fases como círculos ligados por trilha, estrelas, cadeado nas bloqueadas e destaque pulsante na próxima fase. Desafios opcionais aparecem como selo dourado no bioma.
- Cartão da fase (estrelas, ondas, famílias, nível máximo, melhor tempo, chefe e aviso de voadores) antes da formação; ajustes em janela com seletor de gráficos e volumes.
- Formação com cartas ilustradas das torres e contador de escolhas; guia com abas Torres/Inimigos/Efeitos e retratos.
- Botões grossos que afundam ao toque, transições de entrada, margens de safe area e ícones próprios (`scripts/ui/menu_kit.gd`, `art/ui/`). Batalhas voltam direto ao mapa; Voltar no mapa leva à tela inicial.

### Fase 1 — intro inteira e mais baixa (2026-10-22)
- Áudio da intro normalizado (pico −9,6 dB, média −24,6 dB; antes chegava a 0 dB) e tocado 4 dB abaixo no barramento de música.
- O vídeo original termina de repente com o logo na tela: a versão do jogo segura o último quadro por 1,6 s com o som saindo em fade (5,6 s no total).
- A reprodução começa só depois de dois quadros desenhados, para o travamento inicial do menu não engolir a abertura; fade final de 0,6 s.

### Intro do estúdio e menus repaginados (2026-10-21)
- Abertura toca `art/branding/intro_logo.ogv` (convertido de `animated-logo.mp4` para Theora/Vorbis, formato nativo do Godot) por cima do menu já montado; clique, toque, tecla ou Voltar pulam, com transição suave e retorno da música do Vale. Não roda em modo headless, então os testes não mudam.
- Tema compartilhado para mapa, formação, guia e créditos: fundo em gradiente, botões arredondados com estados de foco/hover/seleção, sliders e barras de rolagem estilizados.
- Mapa reorganizado em cartões por bioma com grade de fases, dificuldade como seletor, ajustes agrupados com porcentagem de volume e rodapé com créditos e versão. Formação destaca as famílias escolhidas e o botão "Entrar na fase"; guia mostra cada torre e inimigo em cartão.
- `*.ogv` incluído no filtro de exportação de `tools/export_presets_candidate.cfg`.

### Início P0/P1 — pipeline e arena 3D
- Blender 4.5.14 portátil, três pacotes FREE KayKit CC0 com licenças e hashes, compilador GLB reproduzível.
- Goblin adaptado e Ranger rigados com 23 ossos e animações reais; teste de ida e volta pelo Blender preserva o rig/clipes.
- Arena ortográfica isolada com terreno/props 3D, sombras, curvas, AnimationTree, transições, slow, pausa, morte e torre com operador e arco.
- `Laboratorio3D.cmd`, 23 verificações automáticas P0/P1 e scripts de captura/gravação.
- Barras projetadas a partir de âncoras 3D; cadência calibrada por velocidade de apoio dos pés, com duas verificações automáticas contra os clipes importados.
- Continuidade automática configurada nesta conversa; progresso e pendências em `documents/PROGRESS_V2.md`.
- Android, acabamento visual e campanha ainda pendentes; nenhum marco V2 foi declarado integralmente concluído.


### Planejamento V2 — documentação
- Definida direção de modelos 3D com câmera fixa, rig e animação natural.
- Especificado contrato de ondas automáticas após o primeiro início manual.
- Documentados campanha proposta, torres com ramos, inimigos, chefes, progressão, economia e critérios de dificuldade justa.
- Criadas etapas P0–P10 com dependências, provas de qualidade, testes e critérios de aceite.
- Atualizados índice, instruções e decisões; especificação V1 identificada como histórico.
- Esta entrega modifica documentação; migração 3D e novos sistemas não foram implementados.


### Primeira apresentação 2.5D
- Terreno pintado de Vale Verde, estrada com volume alinhada ao Path2D e bases de pedra.
- Caminhada do goblin em quatro quadros, espelhamento horizontal, balanço discreto e reação ao dano.
- Sombras no chão e profundidade por posição vertical para inimigos e torres.
- Recuo visual ao disparar e flechas orientadas pelo deslocamento.
- HUD com fundo mais opaco para manter legibilidade sobre o cenário.
- 24 verificações unitárias e 18 de integração aprovadas, incluindo avanço e pausa da animação.

### Visual e encoding do protótipo
- Corrigido texto de vitória corrompido e adicionada configuração UTF-8 em `.editorconfig`.
- Barra de vida sobre cada inimigo, ligada ao sinal de vida e limitada entre zero e o máximo.
- Sprites PNG transparentes gerados para Arqueira e goblin, com prompts e origem registrados.
- Pads reposicionados abaixo da estrada para manter torres fora do HUD.
- 24 verificações unitárias e 15 de integração aprovadas; captura visual em `test-results/preview.png`.

### Preparação para teste M1
- Godot 4.5.2 portátil em `C:/Dev/Tools/Godot`, obtido do release oficial.
- Inicialização abre a batalha; corrigidas assinatura da construção, conexão do HUD e colisão de nome em Area2D.
- Compra validada antes do débito, pausa, reinício e término que congela a simulação.
- Morte/vazamento e impacto resolvem uma única vez; projéteis sem alvo são removidos.
- Estrada, instruções, barra de construção e placeholders geométricos próprios visíveis.
- Cinco vazamentos de 4 vidas permitem derrota no cenário M1 sem defesa.
- Launcher `Jogar.cmd`, runner `tools/run.ps1` e guia `TESTING.md`.
- 24 verificações unitárias e 11 de integração aprovadas. Render Vulkan Mobile inspecionado; Android pendente.

## [0.1.0] — 2026-09-01

### M0 — Bootstrap

#### Adicionado
- `project.godot` — Configuração do projeto Godot 4 com renderer Mobile, resolução 1920×1080, stretch `canvas_items`/`expand`, orientação landscape, 60 ticks/s de física.
- Autoloads: `GameSession`, `SaveService`, `AudioService`, `SceneRouter` — stubs funcionais com tipagem e sinais.
- Resources fundamentais: `TowerDefinition`, `TowerLevel`, `EnemyDefinition`, `WaveDefinition`, `WaveGroup`, `MapDefinition` — todos com validação integrada.
- `ResourceValidator` — validação cruzada de coleções (IDs únicos, referências válidas, custos ordenados).
- `Main.tscn` + `main.gd` — Cena bootstrap com diagnóstico de resolução, renderer e autoloads.
- Framework de testes: `TestBase`, `run_all.gd` (runner headless) e `test_resource_validation.gd` (16 testes).
- Estrutura completa de diretórios conforme `TECHNICAL_SPEC.md`.
- `CHANGELOG.md`, `DECISIONS.md`, `art/ASSET_SOURCES.md`.

### M1 — Fatia vertical mínima

#### Adicionado
- Mapa 1 (`map_01.tscn`) com `Path2D` e espaços de construção (`BuildPad`).
- Entidade inimiga (`grunt.tscn`) separada em componentes (`HealthComponent`, `MovementComponent`).
- Entidade torre (`archer.tscn`) e projétil (`arrow.tscn`) separados em componentes (`TargetingComponent`, `WeaponComponent`).
- Gerenciadores de fluxo: `WaveManager`, `BuildManager` e cena raiz `battle.tscn`.
- HUD principal (`battle_hud.tscn`) informando vidas, moedas, onda atual e permitindo iniciar as ondas.
- Testes unitários para M1: 7 novos testes validando armadura, dano e custos de construção (`test_m1_components.gd`).


### 2026-10-19 — P2 e primeira fatia P3

Simulação 3D determinística e primeira fase de dez ondas ligadas à apresentação; menu/dificuldade e persistência versionada com recuperação. Suite integrada: 134 verificações aprovadas. Capturas Vulkan inspecionadas. Campanha restante, duração/balanceamento, acabamento e Android continuam pendentes; detalhes em documents/PROGRESS_V2.md.

### 2026-10-19 — P4 alpha em validação

Adicionados Cristal/Farol/Alquimista até L3, status limitados e determinísticos, vespa/rastejante volumétricos, mapas02/03 e total36 ondas. Formação, guia, perfis gráficos e progressão local integrados. Suite integrada passou em172 verificações; testes específicos posteriores ampliados e aprovados. Capturas Vulkan revisadas; correções de traçado, bases, vegetação, rio/pontes e nomes UTF-8. Smoke BlueStacks com toque/combate/pausa sem erros após workaround de frame pacing exclusivo do emulador. Ensaio completo Android em andamento. P5–P10 ainda pendentes; não é produto final.

### 2026-10-19 — P5 arsenal no laboratório

Implementadas oito famílias/56configurações com ramos exclusivos, efeitos limitados, foco, correntes, perfuração e suporte sem ciclos. Laboratório acessível pelo menu, seleção5de8 e apresentação de ramos integrados. Suite253verificações aprovada, mais7 asserções adicionais aprovadas após ela;448 cenários controlados e19/19comparações de papéis. Capturas Vulkan inspecionadas. Campanha ainda com três fases; próxima entregaP6.


### Checkpoint P6 parcial — 2026-10-19
Quarta fase e primeiro capitão com Brado, guardião rigado, tutorial/ajuda e música/ambiência originais implementados. Campanha: quatro fases/52 ondas; laboratório: oito famílias/56 configurações. Fase04 aprovada em sete verificações: duas formações legais matam o chefe e vencem com 13 vidas. Testes de chefe, apresentação, áudio e tutorial integrados ao runner; evidência de fechamento em test-results/checkpoint-suite.log. P6 permanece aberta para inspeção visual e balanceamento; P7–P10 pendentes. Trabalho e automação pausados a pedido do usuário para testada e retomada posterior. Detalhes e ponto de retomada em documents/PROGRESS_V2.md.

Fechamento do checkpoint: suíte integrada completa executada com saída 0, sem erros/warnings do Godot; 294 verificações PASS, calibrações e referência de 448 cenários concluídas. Log: test-results/checkpoint-suite.log. Trabalho encerrado neste checkpoint a pedido do usuário.


### Retomada P6 — 2026-10-20
Inspeção Vulkan Mobile em 1280×720 e 1600×720: chefe/Brado, guardiões, ajuda, tutorial e compêndio capturados em test-results/p6-*.png; logs sem erros. Fixture visual explícita, sem alegação de partida real. Compêndio agora exibe velocidade, camada, armadura e resistência; alvos internos do laboratório omitidos. Final do Vale anuncia Garganta Rubra. Elite ganhou ombreiras presas ao osso do peito. Limiar de caminhada calibrado para o Saqueador de 1,4m/s não usar corrida desacelerada; Corredor preserva corrida. Testes isolados: arena25, chefe/mundo7, campanha/save27 aprovados. Suíte completa de fechamento: test-results/p6-closure-suite.log. Aceite humano, duração final e S23 físico continuam pendentes.


### P6 funcional no PC e primeira fatia de P7 — 2026-10-20
Fechamento P6: tools/run.ps1 -Test saiu com código0; 300 linhas PASS, calibrações e 448 cenários de arsenal. Evidência: test-results/p6-closure-suite.log. Inspeção Vulkan 16:9/20:9 realizada; aceites humanos e S23 físico não aprovados.
P7 fase05 Pontes Gêmeas: duas entradas terrestres identificadas, rota aérea separada, dois cruzamentos únicos sobre o rio, bases fora de estrada/água, materiais e paredões de cânion próprios. Xamã Mage adaptado/rig23ossos com staff, cura máxima3alvos/4s/seis usos, sem autocura, ressurreição ou moeda. Cruz de cura distinta do veneno, reutilizada por pool. Arcana e L4 disponíveis antes de entrar. Orçamento inicial final800moedas; upgrade L4 de referência iniciado no intervalo. Duas formações de cinco famílias (Arqueira ou Balista) completaram16ondas/312inimigos e seus ramos ArcanaA/B, ambas18vidas e310mortes/2vazamentos;63173/62160ticks (~17,5/17,3min incluindo preparação). Testes8 de cura,7 de mundo e6 de campanha passaram isoladamente; integrados ao runner. A campanha disponível passou a68ondas na fase05; fase06 em ajuste, sem aprovação ainda. P7 não fechado: faltam fases06–08 completas, mecânicas restantes, música do cânion e validação.


### P7 — fase06 e trilha do cânion, 2026-10-20
Pedreira dos Gigantes:18ondas/292inimigos,14bases,900moedas iniciais revisadas para1100 ao testar preparação e evoluções, L4 e oito famílias disponíveis para seleção de cinco. Mapa espelhado com corredor final e guindaste/vagonetes geométricos próprios. Bruto420HP/lento/vazamento3 com rig volumoso e machado; Veterano100HP/2,5m/s com ombreiras e corrida. Duas formações legais, Cristal ou Alquimista, venceram com2/7vidas,275/279mortes e17/13vazamentos;61715/59590ticks incluindo preparação (~17,1/16,6min). Arcana e antiaérea L4, Estandarte com ataques sob aura reais e zero dano próprio. Teste de campanha8 e mundo5 passaram isoladamente; mundo ampliado com limites do cabeçalho e previsão. A curva está mais punitiva que a fase05; manter revisão P9 e teste humano, sem alegar dificuldade final aprovada.
Trilha original48s/80BPM e vento periódico12s em canyon_*.ogg; síntese sem samples, fontes WAV em source_assets/audio e manifesto de hashes em art/audio/canyon_manifest.json. AudioService troca bioma sem reiniciar a mesma stream, retorna ao Vale no mapa;13testes de áudio e20checks de assets aprovados. Cabeçalho passou a quebrar texto para títulos/avisos longos não expandirem além da tela. Suíte integrada de seis fases em test-results/p7-six-stage-suite.log. P7 continua aberto para07/08, escudo/aura/invocação e chefe2.


### Fechamento funcional P7 — 2026-10-20
Campanha agora com8fases/124ondas. Fortaleza Quebrada:18ondas/299inimigos; duas formações normais vencem16/18vidas. Portador de Escudo:80pontos separados da vida, uma recarga após5s sem dano; DoT adia recarga. Testes9de regra,4de mundo e6de fase aprovados. Fonte física do escudo redondo no mesmo KayKit CC0.
Forja do Colosso:20ondas/345inimigos autorais e até6crias extras. Porta-Estandarte acelera aliados20% sem soma; chefes e próprio portador não recebem a própria aura. Vespa pesada tem carapaça volumétrica. Colosso tem corpo de pedra chanfrada/bronze ligado a23ossos e clipes reais, núcleo emissivo, aviso2s, duas barreiras300/4s e até6crias/no máximo4simultâneas/zero recompensa. Ao quebrar a barreira, o anel desaparece imediatamente. Invocados usam selo pálido para distinguir ausência de recompensa.
BossHP5000 e4000 eram protótipos que deixavam o chefe vazar em referência; calibrado para3800. Plano final conserva antiaérea, poupa a partir da onda17, compra foco ArcanaA em outra base antes do chefe, usa DemolidorB e prioridade Mais forte na última onda. Não houve venda obrigatória nem injeção de moeda no plano final. Duas formações com Cristal/Alquimista matam chefe e6crias, vencem18/20vidas,349/351mortes e2/0vazamentos;74341/68511ticks incluindo preparação (~20,7/19min). Referências em tests/simulation3d/test_stage08.gd.
Suíte integrada de8fases:400linhasPASS e saída0 em test-results/p7-eight-stage-suite.log, mais calibrações/referência448casos. Alterações cosméticas posteriores e som foram verificadas separadamente: mundoForja ampliado11, campanha/save27, regrasForja15, SFX7headless/9GPU e assets56. Não alegar uma nova suíte integral com esses incrementos sem executá-la.
14cues originais curtas, sem samples, em art/audio/sfx:8famílias,UI,impacto,cura,aviso,barreira e invocação. Pool12vozes de combate, UI separada/polifonia2, pausa por bus/nó e cooldown cosmético; nenhuma cadência de som decide dano. Fontes em tools/assets/compose_sfx.py e hashes no manifesto. Encerramento espera a latência reportada do driver após stop, em vez de sair imediatamente; duas execuções GPU com12trocas de região e teste de saturação terminaram sem vazamentos. API consultada: https://docs.godotengine.org/en/4.5/classes/class_audioserver.html . Aceite auditivo humano permanece pendente.

#### Android P7, snapshot antes dos SFX e últimos indicadores
APK isolado test-results/IronPathBenchmark08.apk, pacote org.ironpath.benchmark.stage08, hash em p7-android-build.json; mainQA não grava progresso da campanha. BlueStacks Pie64/API28, Vulkan Mobile, GPU RTX4070Ti do host. Vitória das20ondas,351resolvidos/349mortes/2vazamentos,18vidas,341moedas,74341ticks;620,605s de parede.36.629frames após10s de aquecimento;mediana16,662ms,p9517,182ms,p9917,866ms,pico103,502ms. Pico29inimigos e89.880.229bytes de memória estática Godot(sem equivalência aRSS/VRAM). Pico de frame exige revisão em P9; causa não identificada. Zero erro do Godot no log.
Report JSON foi extraído de IRON_BENCHMARK_COMPLETE no log (run-as do BlueStacks não permitiu ler armazenamento interno), preservado em p7-android-benchmark.json/.log; captura p7-android-result.png. App de ensaio foi encerrado após coletar o resultado; nenhum app externo interrompido. Frame pacing desativado só no staging de emulador. Essa build não inclui os SFX/último feedback de barreira e não é candidata final. S23 físico/temperatura/bateria seguem pendentes.
P7 funcional no PC e em BlueStacks; aceite humano/arte final/performance física continuam em P9/P10. Próximo trabalho:P8, fases09–12 e último bioma; depois P9/P10.


P8, 2026-10-20: conteúdo das fases09–12/212ondas, Sentinela/Escavador/Invocador/Elite/Guardião da Ruína, L5 na campanha, música do Pântano e testes isolados implementados. Validação integrada em execução; acabamento e candidata final P9/P10 não concluídos. Evidências detalhadas em documents/PROGRESS_V2.md.

P8 funcional fechado: doze fases/212ondas/3chefes; Normal e Aventura completas, referências próprias Veterano aprovadas, fase12 BlueStacks24ondas/472resolvidos/20vidas. P9 em início; arte final, ritmo e aparelho físico não aprovados. Evidências em documents/PROGRESS_V2.md.

P9 (2026-10-20): acabamento e regressões técnicas fechadas; ciclo de vida14/14 e save37/37. P10 em execução; aceite humano de arte/ritmo e S23 físico pendentes.

P10 (2026-10-20): candidata0.9.0-rc1 pronta para validação. Windows portátil e APKs BlueStacks/S23 gerados; identidade/créditos/licenças e launcher incluídos. Suíte666PASS, regressões focadas e partida12 Android completa aprovadas. Reinício durante toque corrigido e reensaiado. Picos ocasionais de frame, aceite humano e S23 físico registrados em documents/VALIDATION_RC1.md.
