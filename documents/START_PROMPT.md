# Prompt inicial para o Codex

Copie o texto abaixo para uma tarefa do Codex aberta na pasta onde o jogo será criado.

---

Crie o jogo mobile descrito no pacote de especificação **Iron Path**. Antes de escrever código, leia integralmente `README.md`, `AGENTS.md`, `GAME_SPEC.md`, `CONTENT_BALANCE.md`, `ART_AND_AUDIO.md`, `TECHNICAL_SPEC.md` e `IMPLEMENTATION_PLAN.md`.

Comece somente pelo marco **M0 — Bootstrap**. Inspecione o ambiente para localizar uma instalação utilizável do Godot 4. Se ela não existir, informe exatamente o bloqueio e continue preparando apenas os arquivos que não exigem inventar resultados de execução.

Requisitos desta tarefa:

1. Crie a estrutura do projeto e as configurações mobile previstas.
2. Implemente os Resources fundamentais e validação mínima.
3. Crie um runner de testes pequeno e verificável.
4. Execute o Godot em modo headless e registre os comandos/resultados reais.
5. Crie `CHANGELOG.md`, `DECISIONS.md` e marque o progresso do M0.
6. Não implemente M1, não gere arte final e não adicione funcionalidades fora do escopo.

Ao terminar, entregue: resumo do que funciona, arquivos alterados, testes/comandos executados com resultados, riscos, pendências e o próximo marco recomendado. Não declare o M0 concluído se algum critério de aceite falhar.

---

## Prompts seguintes

Depois da aprovação de cada marco:

> Continue o projeto Iron Path pelo marco M1. Leia novamente as especificações relevantes, preserve todas as decisões congeladas, implemente apenas esse marco, execute seus testes e demonstre cada critério de aceite com evidência.

Para correções:

> Diagnostique o problema abaixo sem expandir o escopo. Reproduza, identifique a causa, crie um teste de regressão quando aplicável, corrija e execute a suíte relevante: [descrever problema e anexar screenshot/log].

