> **Referência V1 / histórico do protótipo.** Para o próximo desenvolvimento, prevalecem [ROADMAP_V2.md](ROADMAP_V2.md), [VISION_3D_V2.md](VISION_3D_V2.md), [GAME_DESIGN_V2.md](GAME_DESIGN_V2.md) e [CONTENT_PLAN_V2.md](CONTENT_PLAN_V2.md). Os marcos novos ainda estão pendentes.

# Plano de implementação

Cada marco termina com jogo executável, testes e atualização do changelog. Não iniciar arte final antes de validar a jogabilidade com placeholders.

> Início V2: arena P0/P1 e pipeline 3D em desenvolvimento; ver [PROGRESS_V2.md](PROGRESS_V2.md). Os marcos M abaixo são histórico do protótipo.

## M0 — Bootstrap ✅ (validado em Godot 4.5.2 em 2026-10-19)

- ✅ Criar projeto Godot, estrutura, configurações mobile e repositório.
- ✅ Adicionar tela de diagnóstico e pipeline mínimo de testes.
- ✅ Definir Resources e validadores sem conteúdo completo.
- ✅ Importação headless e 24 verificações unitárias executadas sem erros.

**Aceite:** projeto abre headless sem erro; teste trivial passa; resolução e orientação estão configuradas.

## M1 — Fatia vertical mínima ✅ (validado em 2026-10-19)

- ✅ Mapa cinza com um path e 3 pads.
- ✅ Um grunt, uma Arqueira, projétil, HP, morte, vazamento e moedas.
- ✅ Construção temporizada, uma onda, vitória e derrota.

**Aceite:** partida pode ser vencida ou perdida apenas por regras reais; recompensa ocorre uma vez; pausa congela tudo.

Validação M1: 18 verificações de integração aprovadas, incluindo construção, pausa, vitória, derrota, recompensa e bloqueio após término. Renderização Vulkan Mobile inspecionada na RTX 4070 Ti. Valores provisórios M1: torre de 50 moedas, cinco inimigos de 10 HP e 4 vidas por vazamento (permite testar derrota sem modificar a cena). Balanceamento completo fica para M2/M3.

Incremento visual solicitado: barra de vida, UTF-8, terreno pintado 2.5D, sombras, caminhada do goblin em quatro quadros e recuo visual da Arqueira. Avanço e pausa da animação testados. Não conclui o manifesto de animações/direções de M6.

## M2 — Combate e economia

- Todas as seis torres no nível 1.
- Alvos Ground/Air/Both, prioridades, splash, slow, veneno e sangramento.
- Compra, cancelamento, venda, upgrade temporizado e painel contextual.
- Testes unitários das fórmulas.

**Aceite:** matriz torre×inimigo respeita filtros; efeitos obedecem stacks; ouro nunca fica negativo.

## M3 — Inimigos e ondas

- Oito inimigos, healer, aura, chefe e pooling.
- 20 ondas orientadas por dados.
- Intermissão, iniciar cedo e avisos de ar/chefe.

**Aceite:** simulação automática completa 20 ondas sem erro/nó órfão; seed repete resultados.

## M4 — Mapas e progressão

- Três mapas funcionais, entradas múltiplas e rota aérea.
- Dificuldades, estrelas, desbloqueio e save versionado.
- Seleção de mapa/dificuldade e resultado.

**Aceite:** campanha pode ser concluída; reiniciar app mantém progresso; save corrompido é tratado.

## M5 — UX mobile

- Tutorial, toque, safe areas, back, escala de UI e acessibilidade.
- Configurações de som/vibração/flash.
- Feedback visual e estados de erro.

**Aceite:** fluxo smoke completo em dispositivo ou emulador; nenhum controle menor que o mínimo definido.

## M6 — Arte e áudio

- Gerar/substituir assets conforme manifesto, preservando prompts e fontes.
- VFX, animações, mixagem e três biomas.
- Auditoria para remover placeholders de release.

**Aceite:** todas as referências resolvem, animações não cortam, leitura permanece clara com 120 inimigos.

## M7 — Balanceamento e performance

- Executar simulações e partidas de teste.
- Ajustar somente dados, documentando antes/depois.
- Pooling, budgets de VFX/áudio e profiling em cenário-alvo.

**Aceite:** 60 FPS alvo/30 piso no dispositivo de referência; nenhum tipo de torre é estritamente superior em todos os cenários.

## M8 — Android candidata a lançamento

- Ícone, splash, nome, versão, permissões mínimas, créditos e licenças.
- Export presets, APK debug e AAB release configurável.
- Checklist de privacidade/offline e teste de instalação limpa.

**Aceite:** APK instala e completa o smoke test; AAB é gerado quando credenciais do usuário estiverem disponíveis; nenhum segredo entra no repositório.

## Backlog posterior

- Posicionamento livre, desafios diários offline, modos infinito e sem pausa.
- Novas torres/mapas, talentos e conquistas de plataforma.
- iOS/TestFlight e localização inglesa completa.



### 2026-10-19 — P2 e primeira fatia P3

Simulação 3D determinística e primeira fase de dez ondas ligadas à apresentação; menu/dificuldade e persistência versionada com recuperação. Suite integrada: 134 verificações aprovadas. Capturas Vulkan inspecionadas. Campanha restante, duração/balanceamento, acabamento e Android continuam pendentes; detalhes em documents/PROGRESS_V2.md.


### 2026-10-19 — P4 funcional validada

Três fases,36ondas,cinco famílias,L3,terra/ar,status,formação,guia,perfis e save integrados. Suite184 verificações aprovada. Ensaio BlueStacks completou14ondas/344inimigos em462,23s de parede/2×,zero erros,mediana16,664ms,p9517,302ms na RTX4070Ti do host. Capturas16:9/20:9 inspecionadas. Acabamento e duração final, sessões humanas e S23 continuam pendentes para o aceite final. Próximo:P5 no laboratório.

### 2026-10-19 — P5 funcional

Arsenal completo disponível no laboratório, com56configurações reais e escolha exclusiva de especialização. Testes de regra, mundo3D e448referências controladas executados; comparações19/19aprovadas. A campanha mantém seus limites por fase. Próximo:P6; produto final ainda não concluído.


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
