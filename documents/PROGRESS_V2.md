# Iron Path — progresso V2

Atualização: 2026-10-20. Projeto: `C:/Dev/TowerDefense`.

**Candidata 0.9.0-rc1 pronta para validação do usuário em 2026-10-20. P0–P9 implementados funcionalmente; P10 empacotado e ensaiado no PC/BlueStacks. Aceite humano e S23 físico pendentes.**

O usuário autorizou implementar o roteiro inteiro, testar cada etapa automaticamente e solicitar sua validação apenas quando o produto final estiver pronto. Não parar para confirmações rotineiras. Referência: Galaxy S23 Ultra; BlueStacks disponível no PC. Não confundir alpha jogável com entrega final.

## Estado real

| Marco | Estado | Evidência / pendências |
|---|---|---|
| P0 | Pipeline PC e smoke Android executados | Blender/GLB/rig/clipes; APK instalado no BlueStacks em Vulkan Mobile. Aparelho físico pendente. |
| P1 | Arena funcional e passada calibrada | 23 testes e 2 calibrações; capturas/vídeo inspecionados. Acabamento final e aceite humano pendentes. |
| P2 | Núcleo e integração 3D implementados no PC | 32 verificações de simulação + 9 de integração; simulação fixa de 60 Hz, apresentação não decide dano. |
| P3 | Primeira fase, menu, economia e save implementados | 10 ondas/106 inimigos; duas estratégias normais vencem. Meta de duração e cinco sessões humanas ficam registradas para o aceite final. |
| P4 | Alpha funcional validada automaticamente; acabamento/balanceamento finais pendentes | 3 fases/36 ondas; 5 famílias até L3, 4 inimigos, slow/veneno, rotas aéreas, formação, guia e perfis. Ensaio Android completo concluído sem erros (snapshot baseline). |
| P5 | Arsenal funcional validado no PC | Oito famílias, 56 configurações e ramos exclusivos L4/L5 no laboratório. |
| P6 | Funcional no PC; aceites finais pendentes | Quatro fases/52ondas, chefe1, compêndio e tutorial; suíte300PASS e capturas Vulkan. Duração/balanceamento humano e mobile pendentes. |
| P7 | Funcional no PC e BlueStacks; aceite final pendente | Oito fases/124ondas, chefe2, regras limitadas, música e SFX. Suíte400PASS+incrementais; partida Android completa. |
| P8 | Funcional validado no PC e BlueStacks; aceite final pendente | Doze fases/212 ondas; Normal/Aventura completas e referências próprias de Veterano aprovadas; fase12 Android concluída. |
| P9 | Implementação e regressão aprovadas; aceite humano pendente | Suíte p9-polish-suite sem erros, save37/37, ciclo de vida14/14; arte/movimento/ritmo precisam da validação do jogador. |
| P10 | Candidata pronta para validação | Windows portátil e APKs BlueStacks/S23, hashes/assinaturas conferidos, fluxo e reinício Android testados; usuário e S23 físico pendentes. |

## Runtime e ferramentas

- `Jogar.cmd` abre `scenes/campaign.tscn`, agora 3D. Protótipo preservado em `tools/run.ps1 -Scene prototype`; arena em `-Scene lab3d`/`Laboratorio3D.cmd`.
- `tools/run.ps1 -Test` executa importação e regressões, reprovando erros/warnings. Última suíte integradaP10:666PASS; verificações finais focadas registradas em VALIDATION_RC1.md.
- Godot portátil 4.5.2: `C:/Dev/Tools/Godot/Godot_v4.5.2-stable_win64_console.exe`.
- Blender 4.5.14 LTS: `C:/Dev/Tools/Blender/blender-4.5.14-windows-x64/blender.exe`.
- JDK17, SDK35, build-tools35 e export templates instalados; configuração em `C:/Dev/Tools/Android/environment.json`.
- Assets KayKit FREE CC0 do autor; licenças em `art/licenses`, hashes em `art/models/manifest.json`. Modelos de torre/criaturas auxiliares próprios são geometria volumétrica, não sprites de personagem.

## Implementado

- Simulação independente de nós: primeira onda manual, demais automáticas após resolução + intervalo; antecipação opcional paga uma vez; pausa; 1×/2×; construção/upgrade/cancelamento/venda; prioridades estáveis; projétil, área, recompensa única e estados terminais.
- Goblin/Ranger com Skeleton de 23 ossos, blends Idle/Walk/Run/Death, Hit superior, arco preso à mão. Cadência vinculada à velocidade real e escala: apoio walk medido 0,673 vs perfil 0,675; run 2,986 vs 2,985 m/s. Fonte editável `source_assets/goblin_pipeline.blend`; ida/volta preserva cinco clipes.
- Canhão volumétrico com recuo; Cristal, Alquimista e Farol com emissores distintos. Módulos L2/L3 acrescentam geometria. Vespa alada com juntas e rastejante com seis pernas articuladas, pools separados por família.
- Slow mais forte, piso de 35%, cap de chefe40%; veneno até três fontes, renovação sem reiniciar a cadência, ticks de0,5s e metade da duração em chefe. Dano terrestre em área não atinge ar.
- Moinho/objetivo, pomar/cerca/frutas, rio central e três pontes no mapa03; trilha aérea dourada. Vegetação respeita bases e estrada. Healthbars ancoradas em 3D e ícones de status em 2D.
- Formação por fase, máximo5, somente famílias disponíveis; alerta aéreo; guia; menu com scroll e dificuldades. Perfis Economia/Equilibrado/Qualidade alteram render scale, MSAA e sombras sem trocar renderer ou resolução lógica.
- Save schema2: aceita números JSON, migra V1 preservando progresso, valida, escreve temporário/flush/rename, mantém backup válido, recupera corrupção e conserva melhores estrelas/tempo. Desbloqueio da próxima fase testado.

## Evidências e limites

- `test-results/p1-motion.mp4`, `p1-lab.png`, `p1-detail.png`: arena inspecionada. Vídeo não é benchmark ou playtest humano.
- `p3-menu.png`, `p3-battle.png`, `p4-gallery.png`, `p4-orchard.png`: capturas Vulkan inspecionadas. Galeria P4 usa fixture explicitamente com 2000 moedas para mostrar modelos; não é evidência de balanceamento.
- Estratégias legais da fase01: 20vidas/106kills em583,8s; 19vidas/105kills em545,7s. Sem defesa perde na onda03. Meta inicial5–7min ainda não atingida.
- Fase02 venceu com dois posicionamentos iniciais diferentes, aproximadamente674–682s e6–12vidas. Corrigido traçado que não permitia cobertura em duas passagens; corrigidas bases sobre a estrada.
- Fase03 venceu novamente após mover a base06 para fora do rio: aproximadamente881–935s e5–9vidas; meta inicial10–12min ainda pendente.
- Última revisão visual detectou mojibake em dois nomes do catálogo por leitura Python sem encoding no Windows. Corrigidos Canhão/Cristal Gélido e adicionada regressão UTF-8. **Usar `encoding='utf-8-sig'` nas leituras de fontes/JSON e `python -X utf8` nos scripts no Windows.**

## Android

Smoke em `org.ironpath.smoke` instalado no BlueStacks Pie64/API28: Vulkan Mobile confirmado, menu, toque, obra, combate e pausa. Zero erros do Godot após workaround; pausa comprovada por duas capturas idênticas separadas por1s. Evidências: `android-frame-pacing-fix.png`, `android-preparation.png`, `android-combat.png`, `android-paused.png`, `android-combat.log`.

Tela preta inicial corresponde a [Godot #105598/#121035](https://github.com/godotengine/godot/issues/105598). `tools/android/export_smoke.py` desativa frame pacing **somente no staging para emulador**; renderer Mobile e configuração de produção preservados. Orientação corrigida para landscape (`0`); ETC2/ASTC habilitado. EditorSettings e configuração BlueStacks têm backups em C:/Dev/Tools/Android. ADB ativado quando não havia sessão anterior em execução. HD-Adb é usado depois de exportar para evitar conflito com a versão do daemon do SDK.

`python tools/android/export_smoke.py --benchmark` criou pacote separado `org.ironpath.benchmark`. Ensaio automático da fase03 Normal/Equilibrado/2× em execução no BlueStacks, com recursos legais, métricas de frames/memória e resultado no log `IRON_BENCHMARK_COMPLETE` e `user://benchmark.json`. Snapshot do APK anterior ao rio central e correções mais recentes de UI/nomes; serve como baseline, não candidata final. Consultar PID/estado antes de interromper. O emulador usa RTX4070Ti do host; não certifica desempenho/aquecimento do S23 Ultra.

## Próximo trabalho

1. P4: suíte184 aprovada e capturas de rio/pomar/formação/menu16:9/20:9 inspecionadas. Manter como regressão.
2. Ensaio Android completo recolhido sem erros; repetir com APK final após P9, sem chamar de teste do aparelho físico.
3. P4 funcional fechada. Próximo marco P5: oito famílias e ramos exclusivos L4/L5 em laboratório, com tabelas e comportamentos reais antes de expandir campanha.
4. Em P5, definir tabelas e comportamento real dos dois ramos antes de multiplicar a campanha; não inventar níveis sem configuração.
5. Manter user informado apenas em mudanças relevantes, e avisar para validação somente quando o produto final estiver realmente pronto. A automação de continuação já existente tem intervalo30min; não esperar por ela durante trabalho ativo nem criar duplicata.

Mudanças preexistentes não commitadas devem ser preservadas. Não usar reset/clean nem commit indiscriminado. Não trocar decisão congelada silenciosamente. Não confundir sucesso de teste automático com diversão validada por pessoas.


### Ensaio Android completo recolhido

`test-results/android-benchmark.json` e `.log`: fase03 Normal/Equilibrado/2× venceu as14 ondas,344 inimigos resolvidos(331kills/13vazamentos),7vidas,8moedas e55435ticks, sem erros/SCRIPT ERROR.462,23s de parede;27126frames após aquecimento, mediana16,664ms e p95 de17,302ms. Pico30 inimigos e77.549.362bytes de memória estática do Godot(essa métrica não é RSS nem VRAM). GPU RTX4070Ti do host. Pacote de benchmark encerrado após capturar resultado; não interrompeu apps externos.

O ID do Rastejante foi alinhado ao catálogo de projeto: `swarm`; `CrawlerActorV2` continua sendo o nome de sua apresentação. Atualizar APK na próxima exportação, pois o ensaio foi feito com snapshot anterior.

## P5 — arsenal funcional no laboratório (2026-10-19)

Oito famílias e56 configurações explícitas em `data/campaign/core.json`: níveis1–3 e ramosA/B de4–5. `arsenal_lab.json` oferece recursos de ensaio e seis situações, sem gerar estrelas/desbloqueios da campanha. Formação agora permite escolher5 entre8 no laboratório. A campanha continua limitada a suas famílias/níveis por fase.

- Crítico determinístico, rajada3alvos distintos, morteiro em ponto marcado, penetração parcial, campo de slow até3por fonte, propagação até4alvos sem recursão, corrosão até50% da armadura, sangramento, correntes limitadas com queda, foco aquecido com reset e suporte sem ciclos.
- Balista e Estandarte têm modelos próprios; Arcana tem emissor/lente distintos. Equipamento de ramo acompanha a mira; arco/boca do canhão/emissor reais originam os projéteis. Altura decorativa foi removida do cálculo de tempo do projétil; visual termina na altitude correta de voadores.
- Módulos, campos, aviso de morteiro, feixes/correntes, tecido animado que pausa, controles de alvo e comparação de ramos integrados. Dano útil, atraso causado e ataques sob aura registrados.
- Suite integrada anterior às últimas7 asserções:253verificações aprovadas; após ela, núcleo do arsenal passou em39(antes35) e campanha/menu em24(antes21). Integração do arsenal:15; papéis:19/19. Referência:448 cenários controlados,56configurações×8casos, em `test-results/arsenal-reference.json`. Não é taxa de vitória de jogadores ou benchmark mobile.
- Comparações verificadas: ramos de foco vencem seus equivalentes em alvos isolados; área/múltiplos alvos vencem em grupos; campo controla mais unidades; Agulha tem mais dano individual; Comando melhora cadência e Vigília amplia cobertura útil. Esses testes não substituem balanceamento da campanha.
- Capturas Vulkan inspecionadas: `p5-branches.png`, `p5-arsenal-A.png`, `p5-arsenal-B.png`, `p5-detail-A.png`, `p5-detail-B.png`, `p5-formation-standard.png`. Galerias usam fixture explicitamente identificada; não alegar partida real.

P5 funcional validada no PC. Próximo marco:P6, fase04/primeiro bioma e chefe1. P6–P10, duração final, som, acabamento, aceitação humana e S23 físico continuam pendentes. Não avisar produto final pronto ainda.


## Checkpoint de pausa — P6 parcial, 2026-10-19

- Campanha agora com quatro fases e 52 ondas. Portão da Guarda tem 16 ondas/314 inimigos, 400 moedas iniciais e evoluções até L3. Primeira onda manual; seguintes automáticas.
- Guardião com espada/escudo e Capitão com machado, rig e clipes próprios adaptados de assets CC0. Brado do chefe tem preparação, área anunciada e aura temporária; morte encerra o efeito. Barra do chefe e barras individuais integradas.
- Tutorial inicial, ajuda que pausa a partida, avisos de alcance/alvos na compra e preferências de áudio persistidas. Música e ambiência originais em OGG com fontes reproduzíveis; efeitos completos de combate ainda pendentes.
- Teste final da fase04: 7/7 verificações aprovadas. Duas formações legais venceram as 16 ondas e mataram o capitão, ambas com 13 vidas; 307 mortes e 7 vazamentos por formação. Nenhuma injeção de recursos. Durações simuladas de aproximadamente 22 e 20,6 minutos excedem a meta e precisam de balanceamento em P9.
- Testes de chefe (16), apresentação (6), áudio (10), assets de áudio (10) e tutorial (9) já passaram isoladamente. Nova suíte integrada registrada em tools/run.ps1; resultado final em test-results/checkpoint-suite.log.
- P6 ainda NÃO fechada: inspecionar visualmente modelos/animações novos, interface do chefe, ajuda e tutorial no renderizador; avaliar música e fluidez; revisar duração/dificuldade. P7–P10 seguem pendentes. APK/benchmark anterior não inclui todas estas mudanças; S23 Ultra físico não foi testado.

### Testada rápida

Abrir Jogar.cmd e escolher uma fase disponível. Laboratório do Arsenal permite experimentar imediatamente as oito famílias e os ramos até L5 sem desbloquear a campanha nem gerar estrelas. A campanha mantém desbloqueio sequencial e limites próprios. Jogo de PC já estava aberto no momento da pausa; nenhuma instância adicional foi iniciada.

### Retomada

Ler este checkpoint antes dos trechos históricos acima. Concluir inspeção e correções de P6, registrar feedback desta testada e só então avançar. Não usar os antigos itens de “próximo trabalho” de P4 como estado atual. Preservar alterações não commitadas; nenhum reset/clean/commit geral foi realizado. Automação pausada, sem retomada agendada para amanhã.

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
A automacao foi reativada por engano na retomada e pausada novamente em 2026-10-20 apos questionamento do usuario. Continuar trabalho ativo nesta conversa; nao reativar agenda de30min nem usar agendamento como substituto da implementacao. O usuario quer continuidade imediata.

### P8 — conteúdo funcional, validação integrada em curso, 2026-10-20
Doze fases/212 ondas disponíveis sequencialmente, oito famílias até L5 a partir da fase09. Sem alteração no save real para desbloquear fases. Bioma Pântano com paleta própria, lagoas, ruínas e música original40s/72BPM + ambiente12s, geradores e hashes registrados.
09 Ruínas Veladas:20ondas/308 inimigos,1500moedas. Sentinela240HP/4armadura/55%resistência mágica; dano físico e puro preservam contraponto. Halo volumétrico ligado ao osso da cabeça. Duas formações legais com Canhão/Balista/Estandarte/Farol e Cristal ou Alquimista:5/18vidas,300/306mortes,8/2vazamentos,82386/73518ticks. A segunda precisa priorizar antiaéreaA; plano idêntico da primeira foi reprovado e ficou nos logs de exploração. Tests stage09:8; resistência:5.
10 Trilhas Submersas:22ondas/371inimigos,1600moedas. Entrada adicional com emergência aos12m sinalizada no mundo. Escavador160HP/3armadura,2.6m/s enterrado e1.4m/s exposto; rastro de terra, sem alvo/dano/status enterrado, todas as torres terrestres compatíveis podem atacá-lo após emergir. Oito testes de regra incluindo1x/2x. Duas referências:20/18vidas,371/369mortes,0/2vazamentos,77972/75229ticks. Bases foram reposicionadas após análise geométrica reprovar sobreposição inicial com túnel; teste cobre ambas as rotas.
11 Ninho das Sombras:22ondas/379inimigos autorais mais crias limitadas,1700moedas. Invocador180HP/coroa própria/rigMage:aviso2s,até6crias por fonte,4vivas,zero moeda; sete testes de limites/posicionamento/recompensa. Duas referências resolveram411inimigos,406mortes5vazamentos,15vidas cada,77796/78265ticks.
12 Coração da Ruína:24ondas/432inimigos autorais mais crias,1900moedas. Elite360HP/18armadura; Guardião da Ruína7000HP/8armadura/20%resistênciabase, corpo3D chanfrado ligado ao rig23ossos com chifres/cristais. Acima2/3vida:postura+12armadura5s; meio:aura20%/reforços alternados; abaixo1/3:postura60%resistênciamágica/reforços. Aviso2s/ciclo12s,até8crias4vivas,sem cura/invulnerabilidade/teleporte. Doze testes de regras incluem janelas/1x2x. Duas referências mataram o chefe:20/19vidas,472/470resolvidos,0/1vazamento,88860/86320ticks. Assert explícito de morte do chefe acrescentado ao teste final.
Apresentação:9checks de mundo (coroas/rig/morte/trilha/emergência/bases), capturas Vulkan p8-ruins.png/p8-guardian.png sem erros. Teste inicialmente buscava apenas nós owned e reprovou elementos runtime; diagnóstico confirmou7ruínas/1coroa e corrigiu apenas o filtro de consulta, sem reduzir critérios. Arte continua provisória: halo ainda pouco legível nessa distância, mapas espelhados10–12 precisam mais identidade, ruínas de borda e corpos vistos na captura exigem acabamento P9. Não chamar visual final aprovado.
Trilha:15testesAudio e30checksassets aprovados. Suíte completa iniciada em test-results/p8-twelve-stage-suite.log; não declarar aprovação antes de conclusão. BlueStacksP8, três dificuldades, duração e aceite humano continuam pendentes. Trabalho ativo sem automação.

#### P8 evidências adicionais
Suíte integrada concluída com saída0 e555linhasPASS em p8-twelve-stage-suite.log, calibrações/referência448cenários. Depois dela, menu/save ampliado33checks (antes27) e mundoGuardião6 passaram isoladamente. MundoPântano10checks inclui halo acima do capacete: inspeção das AABBs confirmou que o halo anterior estava dentro do capacete; Ylocal alterado0.48→1.2 e âncora da barra2.95. Não confundir snapshot Android em curso, exportado antes desse ajuste cosmético/menus opcionais, com futura candidata final.
Campanha Aventura completa aprovada:11scripts cobrindo12fases e duas formações cada; JSON p8-adventure-campaign.json. Veterano com referências de Normal reprova várias fases; fase03 tem plano alternativo legal que vence6vidas (probe_veteran03). Tentativa de foco precoce na Arcana: fase06reprovou; fase07venceu3vidas. Protótipo fase06 com orçamento inicial+25% e foco venceu13vidas; ajuste ainda não aplicado ao produto. Não declarar Veterano validado.
Correção no teste08: derrota antes de construir a torre de foco expunha acesso nulo na asserção e deixava processo Godot aberto. Apenas os processos com comando exato veteran_test_stage08.gd foram encerrados; asserção agora valida existência antes de acessar ramo. Runner de dificuldades ganhou timeout180s por referência. Falhas e logs originais preservados.
Desafios opcionais por bioma: revisitar fase04/08/12 sem vazamentos, usando3estrelas reais na dificuldade selecionada. Aparecem após terminar o bioma; não desbloqueiam fases nem dão moeda. Dados challenges.json;6novoschecks menu/progresso/isolamento de dificuldade. Arte/ritmo/performanceP9/P10 e aceites humanos continuam pendentes.

#### Android P8 concluído, 2026-10-20
Snapshot isolado em IronPathBenchmark12-run1.apk/hashp8-android-build.json:24ondas/472resolvidos/472mortes/0vazamentos/20vidas,88860ticks,741.024888s.43.846frames medidos,mediana16.662ms/p9517.248/p9918.355/pico124.408;27inimigos de pico/100.382.641bytes de memória estáticaGodot. BlueStacksVulkanMobile/RTX4070Ti, com testes headless concorrentes no host; não é medição de S23 físico.17frames acima33.4ms, maioria no começo; maior emtick2582,primeiroinimigo. Hipótese de custo da primeira instanciação/pipeline para investigar P9, sem declarar causa provada.
Log original p8-android-original.log sem erro; captura p8-android-result.png. Mensagem única de relatório ultrapassou limite do logcat, mas arquivo interno original continuou íntegro. Recuperado pelo próprio app via build de leitura (reinstalação preservando dados do pacote QA), p8-android-benchmark.json com17frames individuais. Primeira versão do leitor tentou processar batalha nula após pedir saída; corrigida com_finished=true e segunda execução p8-android-report-reader-fixed.log sem erros/17chunks. Erro só do utilitário de leitura, ausente da partida original. App QA encerrado; nenhum save real de campanha alterado.
PerfilVeterano15%HP/5%velocidade/15vidas reprovou várias referências e não estava aprovado para entrega. Orçamento+25% isolado não resolveu a curva e foi rejeitado. Candidato8%HP/2%velocidade/20vidas/intervalo6s,sem bônus de moedas, aplicado em difficulties.json; Normal/Aventura mantêm os valores anteriores. Seis testes de perfil/isolamento aprovados. Referências próprias Veterano em execução por tools/check_veteran.py; fase03usaformação1/fase04focoemchefe/fase06formação1/fase08formação0/fase09formação1. Não exigir que ambas as formações deNormal vençamVeterano, mas exigir uma referência completa por fase e morte dos chefes.

#### Fechamento funcional P8
Referências próprias Veterano concluídas com saída0:11scripts/12fases, todas as ondas resolvidas, todos os chefes mortos; p8-veteran-references.json e logs p8-veteran-reference-*.log. Vidas finais por fase01–12:15,9,5,2,3,1,2,7,18,16,10,16. Dificuldade ainda exige revisão de curva P9: Pedreira e Fortaleza muito estreitas, Pântano mais permissivo; aceite humano não realizado. Normal e Aventura têm duas formações completas por fase. Não usar os antigos logs de exploração reprovados como estado do perfil agora aprovado.
Diff/status de fechamento em test-results/p8-working-tree.txt:31arquivos rastreados alterados(+674/-230) e muitos novos/anteriores não rastreados; estatística inclui marcos anteriores e não é um diff exclusivo de P8. Nenhum reset/clean/commit geral. Suíte555PASS antes dos últimos incrementos; menu/save35,mundoRuína6,contrato8,perfis6 e mundoPântano10 passaram após alterações correspondentes. Persistência final usa arquivo QA isolado. Falha de timeout de processo corrigida e verificada com pai/filho próprios encerrados sem órfão.
Próximo marco P9: reduzir picos de primeira aparição sem alterar simulação; revisar enquadramento/visibilidade de bases/arte por bioma, movimento em curvas/slow/2x e ritmo das fases. Só depois empacotar P10. Testes humanos e S23 físico ficam para aceite; BlueStacks não substitui certificação física.

### P9 — primeiras correções verificadas
Enquadramento ortográfico30.5/v_offset-1.2 e barra de chefe compacta no canto;24casos(12fases16:9/20:9) aprovados com todas as bases fora dos painéis. Preparação carrega/desenha uma instância de cada inimigo e cria antes da primeira onda, sob tela de preparação; pool reaproveita modelos sem moeda/spawn/ticks. Testes5headless/6Vulkan aprovados. A aparente perda de letras na captura inferior era captura antes da estabilização do layout após trocar a mensagem; diagnóstico GPU comprovou retângulos íntegros e espera2frames corrigiu a fixture, sem alteração desnecessária dos controles.
Ensaio curto BlueStacks90s, pacote separado org.ironpath.benchmark.stage12.startup:mediana16.664ms/p9516.794/p9916.974/pico36.09,4802frames,1frame>33.4ms,estadoonda2/semvazamento. Comparação preliminar com pico124.408ms da primeira onda da execução anterior; não equivale a partida completa da nova build. Arquivos p9-android-startup.json/.log/-build.json. Snapshot anterior à decoração e interpolação subsequentes; app QA encerrado.
Arte:solo ampliado para cobrir viewport, grão suavizado em todos os biomas,pedrasdebeira emMultiMesh,folhagem dePântano e marcos próprios09arco/10passarela/11ninho/12santuário. Rotas e bases mantidas. Arquivos de fixture p8-guardian.png/p8-ruins.png foram atualizados durante inspeçõesP9; não usá-los como screenshot imutávelP8. Capturas seguintes usam prefixop9; AndroidP8original preservado.
Correção real:voadores em fases02/05/08/12 ficavam ao nível do solo porque a rota tinhaY0. Regressão test_air_altitude reprovou4/5antes e passou5/5depois; altitudevisual2.2 declarada nos dois tipos. Rota lógica/dano inalterados. Pontos de mira por ator agora correspondem a corpo humano/vespa/casca/golem; projéteis e raios usam esses pontos, impactos letais preservam ponto anterior à morte. Seis testes de mira/pool/ausência de dano visual aprovados.
Interpolação visual ativada a60Hz, apenas em atores/projéteis da campanha; filhos com animação porframe ficamOff, reset ao nascer/reutilizar; HUD acompanha transformação interpolada. Protótipo2D/arena preservadosOff. Rampas cosméticas das pontes suavizadas e passada do crawler usa deslocamentoXZ. Orientação consultada: https://docs.godotengine.org/en/4.5/tutorials/physics/interpolation/physics_interpolation_quick_start_guide.html . Revisão visual em movimento ainda em execução; não declarar aceite humano.
Comparação de clipes CC0:Walking_A0.673m/s,B0.768,C0.417;Running_A2.986,B3.451. Não houve troca arbitrária de animação; manter clipes atuais e calibração enquanto se revisa render/transições. Modelo QA temporário removido, gerador de comparação preservado em tools/assets/prepare_movement_candidates.py; dados candidate-gait-*.json.

### P9 — fechamento técnico, 2026-10-20
Suíte integrada `test-results/p9-polish-suite.log` concluída com importação, testes unitários, integração, conteúdo e assets aprovados. Revisão posterior: save37/37 rejeita best_ticks inválido; lifecycle14/14 cobre Back, Escape durante pausa, previsão, seleção, suspensão, flush de áudio, confirmação duplicada, reinício e liberação da batalha. Save de teste isolado. Capturas e filme em p9-polish-stage*.png / p9-campaign-motion.mp4. Experimento de ritmo global rejeitado após regressões nas fases5/6, sem aplicação nos dados de produção. Duração, diversão, animação natural e desempenho físico S23 permanecem sujeitos ao aceite humano. Início P10 autorizado para produzir candidata revisável, sem alegar esses aceites.

### P10 — candidata pronta para validação, 2026-10-20
Builds em `builds/0.9.0-rc1`: Windows EXE/PCK+ZIP, APK BlueStacks instalado como Iron Path, APK S23 físico não ensaiado. `Testar.cmd` abre a exportação Windows em1280×720 sem precisar de Godot. Identidade própria, créditos KayKit CC0/Godot/dependências e avisos de terceiros incluídos. Assinaturas debug/arquiteturas/ausência de permissão internet e integridade conferidas; nenhum AAB/publicação.
SuíteP10:666PASS/0erros/warnings. Correções finais de tutorial e restart verificadas com10/16/37/9checks focados e7no executável exportado. No toque Android, restart reproduziu can_process com remove_child durante evento; agora processa hide/disable e queue_free ao fim do frame, mantendo o nó na árvore até liberação. Três reinícios nativos no APK final e fechamento/reabertura normais sem erros/warnings. Save de teste separado no PC; nenhuma vitória inserida na campanha Android do jogador.
Benchmark final do mesmo combate:24ondas,472kills/472spawn,0vazamentos,20vidas,88860ticks,741.113s; mediana16.665ms,p9517.479,p9919.314,pico181.057. Picos ocasionais ainda medidos, host compartilhado com testes; não alegar fluidez perfeita nem desempenho físico. Diferenças pós-benchmark limitadas a créditos/restart do CampaignApp e mensagem do tutorial, rotinas não executadas pelo benchmark. Relatório de equivalência89arquivos com diffs explícitos. Teste humano de beleza, movimento, duração e diversão é o próximo aceite, sem agendamento automático.
Evidências detalhadas e limites: `documents/VALIDATION_RC1.md`, `test-results/p10-*.log/json/png`; snapshot de hash do APKQA preservado. BlueStacks deixado no menu principal de Iron Path, pronto para testar. Não houve reset do save real do PC, commit em massa ou compra de assets.
