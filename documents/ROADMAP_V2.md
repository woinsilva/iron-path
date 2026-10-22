# Iron Path — fases de implementação V2

Versão 2 · 2026-10-19 · Roteiro de produção do jogo 3D com câmera fixa.

## 1. Como usar este plano

Este é o plano vigente para trabalho futuro. O protótipo M1 em 2D permanece acessível. P0/P1 começaram com uma arena 3D isolada; ver [PROGRESS_V2.md](PROGRESS_V2.md) para evidências e pendências. Nenhum marco V2 foi declarado integralmente concluído. Não confundir fases da campanha, numeradas 01–12, com etapas de desenvolvimento, numeradas P0–P10.

Requisitos do usuário: personagens realmente 3D, visão com leitura 2D, alta qualidade visual, movimento natural, variedade estratégica e ondas automáticas após a primeira. Quantidades e nomes do catálogo são uma proposta inicial, não uma alegação de conteúdo pronto.

Documentos de referência:

- [Visão e qualidade 3D](VISION_3D_V2.md): câmera, modelagem, animação, arte, som e desempenho.
- [Regras de jogo](GAME_DESIGN_V2.md): partida, ondas automáticas, evolução, dificuldade e progressão.
- [Catálogo de conteúdo](CONTENT_PLAN_V2.md): doze fases, oito torres, ramos, inimigos, chefes e arcos de ondas.

Cada etapa termina com uma demonstração pequena e revisável, resultados de teste e pendências. Corrigir um bloqueio de qualidade antes de multiplicá-lo pelo elenco inteiro. Não substituir um problema de animação por mais partículas, nem um problema de estratégia por mais HP.

## 2. Ordem e dependências

| Etapa | Entrega principal | Depende de | Estado inicial |
|---|---|---|---|
| P0 | Especificação operacional, pipeline e dispositivo de referência | Documentação V2 | Pipeline PC validado; Android pendente |
| P1 | Prova de qualidade 3D e movimento natural | P0 | Arena em revisão; testes funcionais passaram |
| P2 | Núcleo de simulação ligado ao mundo 3D | P1 | Funcional/testado |
| P3 | Primeira fase divertida, com dez ondas automáticas | P2 | Funcional; diversão/duração para aceite final |
| P4 | Cinco torres básicas, efeitos e três primeiras fases | P3 | Funcional/testado; acabamento final pendente |
| P5 | Oito famílias e evoluções L4/L5 completas no laboratório | P4 | Pendente |
| P6 | Primeiro bioma completo e chefe 1 | P5 | Pendente |
| P7 | Segundo bioma completo, chefes e beta de oito fases | P6 | Pendente |
| P8 | Terceiro bioma e campanha de doze fases | P7 | Funcional validado PC/BlueStacks; aceite humano pendente |
| P9 | Acabamento, acessibilidade, balanceamento e otimização final | P8 | Em início |
| P10 | Candidata Android, instalação e aceite | P9 | Pendente |

Desempenho, save e legibilidade são verificados desde as primeiras etapas, não adiados integralmente para P9. Arte e gameplay evoluem juntos após a prova de P1.

## 3. P0 — Preparação técnica e de produção

**Objetivo:** tornar viável a qualidade desejada e resolver as dependências antes de produzir em volume.

Entregas:

- Inventário do protótipo: preservar estado atual e classificar o que pode ser reutilizado, adaptado ou substituído.
- Cena nova de teste 3D em diretório separado; manter o protótipo 2D acessível durante a migração.
- Fixar versão do Godot utilizada e confirmar renderer Mobile, exportação Android e ferramentas de modelagem/rig.
- Escolher um Android de referência e um perfil mínimo, além do PC de desenvolvimento. Registrar hardware, SO, resolução e metas de memória/energia após medições iniciais.
- Definir origem dos modelos: criação própria, artista ou biblioteca coerente com licença válida. Registrar disponibilidade de arquivos editáveis e animações. Nenhuma compra é presumida.
- Criar referências de câmera, proporções, materiais e iluminação; um único padrão de escala e orientação.
- Preparar importação `.glb`, política de nomes, rigs, clipes e materiais compartilhados.
- Converter uma pequena amostra de dados para metros; não aplicar números em pixels diretamente ao mundo 3D.
- Inventariar cenas e testes que dependem de `Node2D`, `Area2D`, `Path2D` ou `CanvasItem`.

**Aceite:** um modelo com rig entra e sai do pipeline sem quebrar escala, materiais ou animação; a cena abre no PC e no Android escolhido. Se ainda não houver dispositivo, registrar exatamente a validação ausente e não aprovar desempenho mobile.

**Risco principal:** tentar entregar animação profissional apenas com imagens geradas. O pipeline de malha e rig precisa existir de fato.

## 4. P1 — Prova de qualidade visual e animação

**Objetivo:** demonstrar o padrão que deverá ser repetido no restante do jogo.

Entregas:

- Goblin 3D com rig e clipes de idle, caminhada, corrida aplicável, reação e morte.
- Arqueira 3D com mecanismo/operador, mira, preparação, liberação do projétil e recuperação.
- Trecho de terreno 3D com curva, vegetação, pedra, estrada, sombra e luz coerentes.
- Câmera ortográfica definitiva de teste, HUD mínimo e barra de vida com âncora na cabeça.
- Locomoção ao longo de curva, transições, mudança de direção e ajuste de cadência à velocidade.
- Laboratório com controles de velocidade, pausa, slow, direção e múltiplas cópias.
- Captura de 20–30 segundos na câmera real, incluindo retorno no sentido oposto e curva fechada.

**Aceite visual:** sem salto de ciclo, espelhamento artificial, deformação evidente, arma flutuando ou pés patinando no trecho de velocidade nominal. Transições convincentes e curva contínua. O personagem deve funcionar em tamanho de jogo, não só em close.

**Aceite técnico:** 1×, 2× e pausa coerentes; métricas de frame no aparelho de referência; nenhuma alteração de vida/dano causada pela apresentação. Reduzir sombras não pode fazer o inimigo perder identidade ou leitura.

**Ponto de decisão:** se a prova ainda não estiver bonita e natural, refinar modelo, rig, câmera ou animação aqui. Não autorizar produção do elenco inteiro apenas porque a cena abre sem erro.

## 5. P2 — Núcleo de gameplay no mundo 3D

**Objetivo:** separar a simulação da forma de desenhar os personagens.

Entregas:

- `Battle3D`, rotas terrestres/aéreas, bases selecionáveis e HUD 2D.
- Componentes de vida, movimento, alvo, arma, status e transação econômica reaproveitados quando forem independentes de coordenadas 2D.
- Movimento guiado por distância na rota; tangente para direção; extensão de curvas sem teleporte.
- Filtros de alvo, desempate estável, cálculo de alcance no plano XZ e seleção por raycast a partir da câmera.
- Spawn, morte, vazamento, recompensa única, vitória, derrota, pausa e reinício.
- Projéteis ligados a eventos de disparo; dano não depende do evento visual de um clipe.
- Pools com reinicialização de alvo, rig, animação, materiais, barras e estados.
- Testes de regressão do protótipo adaptados, preservando as regras verificadas que continuam válidas.

**Aceite:** cena pode ser vencida e perdida sem intervenção de depuração; morte e vazamento nunca se duplicam; nenhum inimigo morto visual segura a onda; tela de resultado abre uma vez; compras inválidas não debitam; pausa congela simulação, obras e apresentação.

## 6. P3 — Fatia jogável da fase 01

**Objetivo:** validar diversão, ritmo e automação antes de ampliar conteúdo.

Entregas:

- Fase Estrada do Moinho em 3D, oito a dez bases úteis, composição artística e rota aprovada.
- Arqueira e Canhão com L1/L2, construção, upgrade, cancelamento e venda.
- Saqueador e Corredor com comportamento e animação completos.
- Dez WaveDefinitions, seguindo a tabela inicial do catálogo e revisadas por simulação.
- Preparação sem pressão, primeiro início manual, oito segundos de intervalo automático, botão opcional de antecipação.
- Tutorial contextual de selecionar, confirmar, iniciar, prever, melhorar e pausar.
- Resultado que explica vazamentos, economia e melhoria possível.
- Menu mínimo e save versionado de configuração e vitória.

**Aceite funcional:** após tocar Iniciar defesa uma vez, as dez ondas chegam sozinhas sem toques extras. Pausa, suspensão, antecipação e reinício não duplicam spawns ou recompensas. Vitória apenas após a última onda resolvida; derrota cancela a sequência.

**Aceite de jogo:** ao menos duas disposições de defesa viáveis no Normal, compra versus upgrade com trade-off perceptível e erro pequeno recuperável. Fazer pelo menos cinco sessões assistidas iniciais com registros qualitativos; a amostra serve para descobrir problemas, não provar equilíbrio estatístico. Duração alvo 5–7 min em 1×.

## 7. P4 — Alpha das primeiras três fases

**Objetivo:** provar a variedade inicial sem aumentar toda a campanha de uma vez.

Entregas:

- Cristal Gélido, Farol Celeste e Alquimista; cinco famílias desbloqueadas ao chegar à fase 03.
- L3 para as famílias disponíveis, com visual, animação e custo próprios.
- Slow, veneno, dano em área e filtros terra/ar, com ícones legíveis.
- Rastejante e Vespa; trajetória aérea, sombra/altitude e aviso anterior à primeira aparição.
- Fases 02 e 03, totalizando 36 ondas nos três mapas.
- Escolha de formação, previsão, bestiário e desbloqueio de fase em Aventura/Normal.
- Primeiro conjunto de perfis gráficos e teste prolongado de aquecimento.

**Aceite:** campanha inicial concluível com diferentes formações; primeira onda aérea tem aviso e resposta acessível; filtros são respeitados; sistema de status não acumula além do limite. A interface não exige conhecer uma regra que só aparece no código.

## 8. P5 — Arsenal completo e especializações

**Objetivo:** completar as escolhas estratégicas em laboratório antes de depender delas na campanha.

Entregas:

- Balista Serrilhada, Torre Arcana e Estandarte de Comando.
- L4A/L5A/L4B/L5B das oito famílias, com tabelas de custo, obra e efeito.
- Sete configurações por família, total de 56 configurações; modelos modulares e materiais compartilhados onde adequado.
- Regras e limites de cadeia, perfuração, área, corrosão, buff, propagação e foco sustentado.
- Arena de combate contra alvo isolado, armadura, resistência mágica, enxame, ar e suporte.
- UI de comparação de ramos; escolha exclusiva; venda e cancelamento com investimento correto.
- Simulações de referência e registro de dano útil, controle e retorno de investimento.

**Aceite:** cada família e ramo tem um uso verificável e uma limitação; nenhum buff recursivo, cadeia infinita ou execução sem cap. A evolução altera comportamento e aparência; não existem botões de nível sem configuração correspondente. Equilíbrio da campanha continua sendo refinado nas próximas etapas.

L5 está pronto no laboratório, mas seu uso na campanha segue o desbloqueio planejado da fase 09. Disponibilidade de produção não equivale a disponibilidade para o jogador.

## 9. P6 — Fechamento do primeiro bioma

**Objetivo:** uma região completa com começo, meio, aprendizado e chefe.

Entregas:

- Fase 04, Guardião, Saqueador de Elite e Capitão com rig, habilidades e sinais de preparação.
- Quatro fases e 52 ondas revisadas individualmente.
- Música do Vale, ambientes, UI de região e transição para Garganta Rubra.
- Compêndio de inimigos, desbloqueio da Balista e recordes por dificuldade.
- Polimento de tutorial para que o jogador não dependa de instruções externas.

**Aceite:** primeiro bioma completo sem travamento de progressão; Capitão apresenta ameaça clara e não exige um único ponto de construção. Pelo menos duas formações para cada fase; dificuldade aumenta por combinação, não por salto inexplicável de números.

## 10. P7 — Segundo bioma e beta de oito fases

**Objetivo:** desenvolver estratégia e especializações com sistemas já compreendidos.

Entregas:

- Fases 05–08: pontes, pedreira, fortaleza e forja.
- Xamã, Bruto, Portador de Escudo, Porta-Estandarte, Corredor Veterano, Vespa Couraçada e Colosso.
- Duas entradas, avisos por rota, cura, escudo, aura e invocação limitada de chefe.
- Estreia de Arcana e Estandarte; L4 permitido desde a fase 05.
- Oito fases e 124 ondas acumuladas, com tabelas e soluções de referência.
- Três dificuldades funcionais sobre o conteúdo disponível; testes de economia e formação.
- Música/efeitos do cânion e primeira revisão ampla de desempenho de combate.

**Aceite:** não há fase impossível por falta de torre desbloqueada; suporte inimigo e aliado têm efeito identificável; chefes e invocados não geram economia infinita; duas entradas não escondem spawn sob HUD. Beta jogável do início à fase 08 em dispositivo real.

## 11. P8 — Terceiro bioma e conclusão da campanha

**Objetivo:** concluir a curva de domínio sem introduzir sistemas demais no final.

Entregas:

- Fases 09–12, Sentinela Rúnica, Escavador, Invocador, Guardião de Elite e chefe Guardião da Ruína.
- Pontos de emergência visíveis, resistência mágica comunicada e invocações com teto.
- L5 liberado na fase 09, com orçamento suficiente para experimentar e escolher.
- Doze fases, 212 ondas explícitas, três chefes e final da campanha.
- Música/ambiente do pântano, chefes e resultado final.
- Primeiros desafios opcionais por bioma; priorizar os que reutilizam sistemas existentes.

**Aceite:** campanha completa em Aventura e Normal, Veterano validado em rodadas próprias; nenhuma regra essencial inédita aparece sem ensino na última onda. Todas as formações de referência são reproduzíveis e o save permite voltar ao jogo mantendo desbloqueios e recordes.

## 12. P9 — Acabamento e validação de lançamento

**Objetivo:** transformar conteúdo funcional em produto bonito, estável e justo.

Frentes de trabalho:

- Revisão de animações em curvas, rampas decorativas, slow, 2×, mortes simultâneas e grupos numerosos.
- Revisão de materiais, sombras, luz por bioma, vegetação, água, transições, VFX e áudio.
- Redução de ruído visual; indicadores não dependem de cor; tipografia e safe areas em 16:9–20:9.
- Testes de dificuldade com pessoas de perfis diferentes e histórico de ajustes de dados.
- Verificar compra versus upgrade, pares de especialização, valor do suporte, recuperação após vazamento e duração real.
- Perfil no Android de referência, incluindo sessão de 30 min, memória, temperatura, pausa/retomada e bateria.
- Otimizar número de materiais, transparências, sombras, LOD, animação distante e pools sem remover dano lógico.
- Testar instalação limpa, save válido/corrompido, migração, reset de progresso e interrupção durante gravação.
- Auditoria de PT-BR/UTF-8, licenças, arquivos-fonte e ausência de placeholder no release.

**Aceite:** cenário-alvo estável, 60 FPS como alvo e 30 FPS como piso no perfil mínimo declarado; nenhum erro de gameplay conhecido que bloqueie campanha; todas as fases têm revisão artística e de ritmo. Descrever qualquer limitação restante de forma concreta.

## 13. P10 — Android candidata a lançamento

Entregas: nome/ícone/splash, export presets sem segredos, APK debug instalável, build candidata, créditos, configurações e checklist de distribuição. AAB de release depende de credenciais e configuração de assinatura disponíveis, sem incluí-las no repositório.

**Aceite:** APK real com caminho registrado, instalação limpa em aparelho, fluxo menu → fase → construção → onda automática → pausa → retomada → resultado → save → reinício. A campanha e os perfis gráficos aprovados devem corresponder ao build testado. Não declarar Android validado com base em render no PC.

## 14. Arquitetura e migração planejadas

### Reaproveitar, adaptar e substituir

| Parte atual | Ação planejada |
|---|---|
| Definições de torres/inimigos/ondas e validadores | Reaproveitar conceito; ampliar níveis, ramos, avisos e progressão |
| Vida, moeda, efeitos e fórmula de dano | Separar de nós visuais e preservar testes válidos |
| WaveManager | Reescrever transições e timers conforme contrato V2 |
| Movimento em Path2D | Adaptar para rota no mundo 3D e distância em metros |
| Targeting por Area2D | Migrar para consulta espacial no plano XZ, filtros e desempate estável |
| Sprites e atlas de caminhada | Preservar como referência histórica/concept, substituir por rig 3D |
| Terreno pintado como fundo único | Referência artística; produzir terreno e props 3D |
| HUD | Reaproveitar estrutura útil; seleção por projeção/raycast e novas informações |
| Save | Versionar catálogo/progressão; testar migração ou reset explícito do save de desenvolvimento |
| Launcher e testes | Manter acesso simples; adicionar seleção da nova cena e testes 3D |

### Separação proposta

- `simulation/`: relógio, entidades, ondas, transações, regras de dano e status.
- `data/`: definições de campanha, fase, onda, inimigo, torre, nível e ramo.
- `presentation/3d/`: cenas de modelo, controlador de animação, VFX, luz e áudio.
- `ui/`: HUD 2D, barras projetadas, menus, bestiário e resultados.
- `tests/`: regras unitárias, integração, simulação de campanha e capturas visuais.

Simulação usa IDs estáveis e snapshots de estado. Apresentação lê eventos e não decide recompensa, custo ou avanço de onda. Atualização de animação pode interpolar entre passos; lógica de combate usa tempo determinístico. Cosméticos não consomem a mesma sequência aleatória que decisões de gameplay.

Não criar novos autoloads automaticamente; manter os quatro aprovados até haver necessidade concreta registrada. Não trocar renderer sem medição e decisão explícita. Versionar os dados para evitar que uma mudança de ID apague silenciosamente recordes.

## 15. Matriz mínima de testes

| Área | Casos essenciais |
|---|---|
| Ondas | Primeiro início manual; próximas automáticas; último vivo; último spawn; último chefe; antecipação; duplo toque; última onda sem novo timer |
| Pausa e ciclo do app | Congelar contadores, obra, dano, animação e projétil; retomar sem salto de tempo; reinício sem pausa residual |
| Combate | Filtros, alcance XZ, empate, tiro cancelado antes de liberar, morte única, vazamento sem moeda, invocados sem recompensa |
| Evolução | Ramos exclusivos, custo acumulado, obra bloqueia tiro, cancelamento e venda sem duplicação |
| Status | Piso de slow, resistência de chefe, limite de fontes, renovação, ticks em 1×/2×, cura sem ressurreição |
| Modelos | Escala, orientação, UV, rig, clipe faltante, pontos de arma, materiais e reimportação |
| Animação | Loop, transição, curva, pé no chão, movimento lento/rápido, morte sem segurar onda, tiro sem dano duplicado |
| Campanha | Pré-requisitos, torres antes da ameaça, formações viáveis, todas as ondas contadas, chefe final e resultado |
| Persistência | Arquivo válido, versão antiga, arquivo interrompido/corrompido, backup e reset explícito |
| Mobile | Toque, back, safe area, interrupção, perfis gráficos, aquecimento e FPS |

Equivalência 1×/2× deve comparar uma simulação com a mesma seed e entradas agendadas no tempo de simulação, não duas partidas humanas com cliques em tempos diferentes.

## 16. Definição de concluído por conteúdo

**Personagem:** modelo licenciado e editável, rig, clipes, materiais, leitura em câmera, comportamento, efeitos, ícone, ficha, LOD/perfil e teste de pool.

**Torre:** papel e fraqueza, custos e tempos, níveis/ramos, modelos e mecanismos, tiro sincronizado, som/VFX, UI e testes econômicos.

**Fase:** mapa bonito, rota/bases, onda por onda, avisos, som, progressão, duas formações de referência, teste humano e teste em aparelho.

**Chefe:** habilidades com aviso, limites, estados visuais, contra-ataque possível, duração, recompensa e transição final corretas.

## 17. Riscos e limites de escopo

| Risco | Tratamento |
|---|---|
| Arte bonita isolada, mas inconsistente no jogo | Câmera e iluminação canônicas; revisar assets juntos desde P1 |
| Animação continua artificial | Priorizar rig, passada, curva e transição antes de efeitos ou mais elenco |
| Conteúdo excessivo antes de provar diversão | Gates P1/P3; campanha cresce por bioma |
| Oito torres e 56 configurações aumentam custo | Peças e rigs compartilhados; cada ramo deve justificar sua produção |
| Uma estratégia domina tudo | Comparar composições e contextos; corrigir função e custo |
| Ondas automáticas deixam pouco espaço para decidir | Intervalos claros, previsão, preparação e pausa acessível |
| Inimigos de suporte criam loop infinito | Caps de cura, aura e invocação; sem recompensa em crias |
| Visual alto demais para mobile | Perfil desde P1, LOD e qualidade escalável |
| Documentos V1 contradizem decisões novas | Índice V2, avisos de legado e registro em DECISIONS.md |

Sem multiplayer, backend, monetização, heróis, mundo aberto ou editor de fases no escopo inicial. Cronograma e orçamento só devem ser estimados após medir o pipeline de P0/P1 e o tempo de produzir uma unidade e uma torre completas. Não prometer datas com base apenas em geração de imagens.

## 18. Próxima ação concreta

Executar **P0**, seguido de **P1**: uma arena pequena com um goblin realmente 3D, uma Arqueira e uma curva de estrada. Demonstrar primeiro o salto de qualidade em movimento. O restante da campanha só deve entrar em produção após essa referência técnica e visual funcionar.
