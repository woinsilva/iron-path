# Iron Path — instruções obrigatórias do projeto

Você está construindo um tower defense 2D mobile em Godot 4. Leia todos os arquivos Markdown deste diretório antes de implementar. `GAME_SPEC.md` define comportamento; `CONTENT_BALANCE.md` define números; `TECHNICAL_SPEC.md` define arquitetura; `ART_AND_AUDIO.md` define assets; `IMPLEMENTATION_PLAN.md` define a ordem.

## Regras de execução

- Implemente um marco por vez e não antecipe sistemas de marcos futuros.
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

