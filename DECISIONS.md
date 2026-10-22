# Decisões do projeto — Iron Path

Registro de decisões técnicas e de design. Uma decisão marcada como **congelada** não pode ser alterada sem proposta formal e aprovação.

## D001 — Renderer Mobile (Congelada)

**Data:** 2026-09-01
**Contexto:** Godot 4 oferece três renderers: Forward+, Mobile e Compatibility.
**Decisão:** Usar renderer Mobile para equilíbrio entre qualidade visual e performance em dispositivos Android de gama média.
**Consequência:** Não usar features exclusivas do Forward+ (GI, SDFGI, volumetric fog).

## D002 — Resolução base 1920×1080 (Congelada)

**Data:** 2026-09-01
**Contexto:** Conforme `TECHNICAL_SPEC.md`, resolução base 1920×1080 landscape.
**Decisão:** Usar 1920×1080 com stretch mode `canvas_items` e aspect `expand`.
**Consequência:** UI deve funcionar em aspect ratios de 16:9 a 20:9 com safe areas.

## D003 — Framework de testes customizado (Congelada)

**Data:** 2026-09-01
**Contexto:** Godot não possui framework de testes unitários integrado. GdUnit4, Gut e similares são opções externas.
**Decisão:** Usar framework de testes leve e customizado (`TestBase` + `run_all.gd`) para evitar dependências externas e manter compatibilidade com execução headless.
**Consequência:** Testes são mais simples mas totalmente controlados. Migração para framework externo possível em marcos futuros se necessário.

## D004 — Autoloads aprovados (Congelada)

**Data:** 2026-09-01
**Contexto:** `TECHNICAL_SPEC.md` define quatro autoloads de ciclo do aplicativo.
**Decisão:** Apenas `GameSession`, `SaveService`, `AudioService` e `SceneRouter` como autoloads. Nenhum executa lógica por inimigo a cada frame.
**Consequência:** Qualquer novo singleton requer proposta e aprovação.

## D005 — Valores monetários inteiros (Congelada)

**Data:** 2026-09-01
**Contexto:** `AGENTS.md` exige que valores monetários sejam inteiros e nunca negativos.
**Decisão:** Todos os campos de custo, recompensa e moedas são `int`. Operações de venda usam `floor()`.
**Consequência:** Sem acumulação de erros de ponto flutuante. Arredondamento sempre para baixo em vendas.

## D006 — Direção 3D real com leitura 2D (Solicitada pelo usuário; implementação pendente)

**Data:** 2026-10-19.
**Contexto:** a caminhada por atlas de imagens não atingiu a naturalidade desejada. O usuário pediu personagens realmente 3D, vistos com leitura 2D, e qualidade visual elevada.
**Direção:** planejar mundo, torres e personagens 3D com câmera fixa ortográfica, rig e animação esquelética. Referência em `documents/VISION_3D_V2.md`.
**Impacto:** substitui a premissa artística/estrutural V1 de jogo apresentado por sprites 2D. O protótipo atual é preservado. Godot, renderer Mobile, UI base, moedas inteiras e autoloads aprovados permanecem; o stretch 2D existente não define a escala do novo mundo 3D. A implementação precisa validar o novo enquadramento.

## D007 — Sequência automática de ondas (Solicitada pelo usuário; implementação pendente)

**Data:** 2026-10-19.
**Direção:** a primeira onda começa por ação do jogador; após cada onda resolvida há intervalo contado e início automático da seguinte. Antecipar é opcional. Sem sobreposição na campanha normal; pausa preserva o estado e o tempo restante.
**Referência:** contrato de estados e casos de borda em `documents/GAME_DESIGN_V2.md`.

## D008 — Campanha e produção V2 (Proposta de planejamento)

**Data:** 2026-10-19.
**Proposta:** 12 fases em 3 biomas, 8 famílias de torres com níveis L1–L5 e dois ramos exclusivos a partir de L4; 12 arquétipos e 4 variantes de elite, 3 chefes e 212 ondas. Construir por etapas P0–P10, começando por qualidade de animação e uma única fase divertida.
**Estado:** quantidades, custos, nomes, estatísticas e durações são metas iniciais editáveis, ainda sem validação de balanceamento. Não implicam conteúdo implementado nem orçamento de aquisição aprovado.
**Referências:** `documents/CONTENT_PLAN_V2.md` e `documents/ROADMAP_V2.md`.

## D009 — Seis níveis por torre e liberação por bioma (Solicitada pelo usuário)

**Data:** 2026-10-22.
**Decisão:** cada ramo ganha um L6 lendário. Limite de nível por fase: 3 (fases 1–2), 4 (3–4), 5 (5–8) e 6 (9–12 e Laboratório do Arsenal).
**Motivo:** o usuário pediu mais de uma evolução por torre e evolução visível; antes as fases 1–4 limitavam a L2–L3. O L6 ficou no último bioma porque, liberado já no segundo, as defesas de referência da fase 8 gastavam o orçamento em L6 e perdiam.

