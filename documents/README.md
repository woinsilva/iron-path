# Iron Path — pacote de especificação para Codex

Este diretório é a fonte de verdade para gerar um tower defense 2D mobile em Godot 4. O nome **Iron Path** é provisório e pode ser substituído sem alterar as regras.

## Ordem de leitura

1. `AGENTS.md` — regras obrigatórias para o agente.
2. `GAME_SPEC.md` — visão, regras e experiência completa.
3. `CONTENT_BALANCE.md` — números iniciais de torres, inimigos e ondas.
4. `ART_AND_AUDIO.md` — direção visual, sprites, animações, UI e áudio.
5. `TECHNICAL_SPEC.md` — arquitetura Godot, dados, saves e testes.
6. `IMPLEMENTATION_PLAN.md` — marcos incrementais e critérios de aceite.
7. `START_PROMPT.md` — prompt pronto para iniciar a geração no Codex.

## Premissas congeladas para o primeiro lançamento

- Engine: Godot 4.x estável, sem plugins pagos.
- Linguagem: GDScript tipado.
- Plataforma primária: Android; manter compatibilidade com iOS.
- Orientação: paisagem, base visual 1920×1080, interface adaptável.
- Tipo: single-player, offline, sem anúncios, compras ou login no MVP.
- Construção: pontos fixos no mapa; a estrada nunca pode ser bloqueada.
- Conteúdo inicial: 3 mapas, 6 torres, 8 inimigos e 20 ondas por mapa.
- Arte: 2D estilizada, leitura clara em telas pequenas, câmera superior 3/4.
- Desempenho: 60 FPS como meta e 30 FPS como piso em aparelhos modestos.

## Definição de concluído do MVP

O MVP está concluído quando o APK de debug inicia sem erros, é possível terminar o primeiro mapa, todas as seis torres e oito classes de inimigos funcionam, saves persistem, os três mapas são desbloqueáveis e os testes definidos passam.

