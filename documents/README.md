# Iron Path — documentação do projeto

## Direção vigente: 3D com câmera fixa

Em 2026-10-19 o projeto passou a planejar personagens, torres e cenário realmente 3D, com leitura de jogo 2D e animações esqueléticas naturais. A primeira onda começa manualmente; as demais começam automaticamente após a anterior terminar e o intervalo encerrar.

O protótipo M1 em 2D continua acessível. A campanha já tem doze fases/212 ondas em 3D, três chefes e oito famílias. O conteúdo passa por validação e acabamento; a qualidade final ainda não está aprovada. Consulte [PROGRESS_V2.md](PROGRESS_V2.md) para o estado real.

## Comece por aqui

1. [Fases de implementação V2](ROADMAP_V2.md) — etapas P0–P10, ordem, dependências, entregas, critérios de aceite e riscos.
2. [Visão 3D e qualidade](VISION_3D_V2.md) — câmera, modelagem, rig, movimento natural, materiais, luz, áudio e desempenho.
3. [Regras e experiência V2](GAME_DESIGN_V2.md) — ondas automáticas, economia, evolução, dificuldade justa e progressão.
4. [Campanha e conteúdo V2](CONTENT_PLAN_V2.md) — proposta de 12 fases em 3 biomas, 8 famílias de torres, 2 ramos por família, 16 inimigos comuns/elite, 3 chefes e 212 ondas.
5. [Instruções de trabalho](AGENTS.md) e [decisões](../DECISIONS.md).

## O que está definido e o que precisa de teste

**Requisitos do usuário:** modelos realmente 3D com leitura 2D, movimento natural, qualidade visual alta, variedade de conteúdo e sequência automática das ondas após a primeira.

**Propostas de produção:** quantidades, nomes, custos, estatísticas, durações, desbloqueios e metas de desempenho do pacote V2. São um ponto inicial coerente para desenvolvimento e validação, não números já balanceados.

**Próximo passo:** concluir as referências próprias de Veterano de P8, depois executar acabamento/balanceamento/performance P9 e candidata P10. O estado atualizado e as pendências concretas ficam em PROGRESS_V2.md.

Manter Godot 4, Android como plataforma primária, paisagem, UI base 1920×1080, GDScript tipado, funcionamento offline, construção em bases fixas e moedas inteiras. Renderer Mobile permanece a escolha inicial; qualquer troca exige medição e decisão registrada.

## Especificação V1 preservada

Os arquivos abaixo descrevem a origem do protótipo e podem ajudar a entender as regras antigas. Em conflito de direção, escopo, arte, arquitetura ou progressão, prevalecem os quatro documentos V2.

- `GAME_SPEC.md`
- `CONTENT_BALANCE.md`
- `ART_AND_AUDIO.md`
- `TECHNICAL_SPEC.md`
- `IMPLEMENTATION_PLAN.md` — histórico M0–M8; o roteiro futuro passa a ser P0–P10.
- `START_PROMPT.md` — prompt de origem, não utilizar para reiniciar o projeto atual.

O protótipo pode ser aberto por `Jogar.cmd`; os testes atuais estão documentados em `../TESTING.md`.

Candidata para validação: ver `../TESTING.md` e `../builds/0.9.0-rc1/LEIA-ME.txt`. O histórico de cada marco permanece em PROGRESS_V2.md; aceites humanos não são substituídos pelos testes automáticos.
