# Iron Path — instruções obrigatórias do projeto

Você está construindo um tower defense com modelos realmente 3D, câmera fixa ortográfica e leitura 2D, em Godot 4 para mobile. Leia os documentos V2 antes de implementar: `VISION_3D_V2.md` define qualidade e pipeline; `GAME_DESIGN_V2.md` define regras; `CONTENT_PLAN_V2.md` define o catálogo proposto; `ROADMAP_V2.md` define as etapas P0–P10. A especificação V1 permanece como histórico do protótipo; em conflitos prevalece a V2. Não declarar a migração pronta enquanto o runtime ainda for 2D.

## Regras de execução

- Implemente um marco P0–P10 por vez e não antecipe sistemas de marcos futuros. A arena de qualidade 3D de P1 é uma prova pequena; a produção em massa depende de sua validação.
- Antes de editar, declare o marco atual e liste os arquivos que pretende alterar.
- Ao terminar uma fatia, execute os testes relevantes e abra o projeto em modo headless sempre que possível.
- Nunca declare sucesso sem evidência de execução, teste ou inspeção da cena.
- Corrija warnings relevantes; não esconda falhas com `pass`, valores mágicos ou tratamento vazio.
- Use GDScript tipado, composição, sinais e Resources. Evite singletons, exceto os aprovados em `TECHNICAL_SPEC.md`.
- Dados de balanceamento pertencem a Resources/JSON/CSV, nunca espalhados em scripts.
- Separe lógica de simulação, apresentação e interface.
- Nenhuma regra principal pode depender do frame rate; use `delta` e timers determinísticos.
- O jogo deve funcionar com toque. Mouse é apenas compatibilidade para desenvolvimento.
- Respeite safe areas, resoluções 16:9 a 20:9 e fontes legíveis.
- Não adicione backend, telemetria, anúncios, compras, login ou multiplayer.
- Não baixe assets com licença incerta. Use placeholders próprios ou assets gerados para o projeto.
- Salve prompts de imagens em `art/prompts/` e metadados de origem/licença em `art/ASSET_SOURCES.md`.
- Não altere uma decisão congelada sem registrar a proposta em `DECISIONS.md` e pedir aprovação.
- Atualize `CHANGELOG.md` e marque o progresso em `IMPLEMENTATION_PLAN.md` após cada marco.

## Qualidade mínima

- Não há erros no debugger durante uma partida completa.
- Nenhum nó órfão ou conexão de sinal duplicada.
- Um inimigo não pode receber recompensa duas vezes.
- Pausar congela toda a simulação, inclusive construção e efeitos.
- Velocidade 2× preserva resultados lógicos equivalentes a 1×.
- Valores monetários são inteiros e nunca ficam negativos.
- Saves são versionados, validados e gravados atomicamente.
- Uma cena deve continuar funcional quando os sprites finais forem substituídos.

## Fluxo de Git recomendado

- Faça checkpoints pequenos por marco.
- Não reverta mudanças preexistentes do usuário.
- Antes do fechamento de cada marco, mostre `git diff --stat`, testes executados e pendências.

