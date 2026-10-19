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
