# Iron Path — regras e experiência V2

Versão 2 · 2026-10-19 · Especificação de planejamento para a nova implementação.

Leia junto com `VISION_3D_V2.md`, `CONTENT_PLAN_V2.md` e `ROADMAP_V2.md`. A direção 3D e a automação das ondas são requisitos do usuário. Valores numéricos abaixo são hipóteses iniciais de teste, não balanceamento certificado.

## 1. Pilares da diversão

1. **Planejar com informação:** conhecer a próxima ameaça e poder preparar uma resposta.
2. **Posicionar com intenção:** cobertura, curvas e confluências importam mais que preencher todos os espaços.
3. **Combinar papéis:** dano em área, foco, controle e suporte se complementam.
4. **Investir sob pressão:** melhorar uma torre pode valer mais que espalhar várias, mas o tempo de obra cria risco.
5. **Aprender com a derrota:** mostrar o que vazou, por qual rota e por que a composição falhou.
6. **Sentir cada decisão:** melhorias visíveis, disparos satisfatórios e inimigos com comportamento reconhecível.

A dificuldade deve nascer de composição, tempo e distribuição espacial. Apenas multiplicar HP produz partidas longas, não necessariamente interessantes.

## 2. Ciclo de uma partida

Menu → seleção de fase/dificuldade → previsão das ameaças → seleção das torres → preparação → iniciar primeira onda → ondas e intervalos automáticos → vitória/derrota → resultado, desbloqueios e próxima fase.

Na preparação, construir e inspecionar rotas sem cronômetro de pressão. O botão **Iniciar defesa** começa a onda 1 e ativa a sequência. Depois disso, o jogador não precisa apertar um botão para cada onda.

## 3. Ondas automáticas: contrato exato

### Máquina de estados

| Estado | Entrada | Comportamento | Saída |
|---|---|---|---|
| PREPARATION | Partida nova | Construção livre; sequência parada | Jogador inicia a onda 1 |
| WAVE_ACTIVE | Grupo da onda começa | Spawns programados e combate | Não há spawns pendentes nem inimigos vivos |
| INTERMISSION | Onda anterior concluída | Contagem regressiva e construção | Contador chega a zero ou jogador antecipa |
| VICTORY | Última onda concluída e núcleo vivo | Congela combate, persiste e mostra resultado | Reiniciar, próxima fase ou menu |
| DEFEAT | Vidas chegam a zero | Cancela spawns e contagens, resolve resultado uma vez | Reiniciar ou menu |

Pausa é uma condição sobre o estado atual, preservando os timers. Não descartar estado ou reiniciar contagem ao retomar.

### Regras obrigatórias

- O próximo intervalo começa após o último inimigo da onda morrer ou vazar, mesmo que ele esteja na animação visual de morte.
- Na campanha normal, ondas não se sobrepõem. Sobreposição só poderá existir em desafio separado, explicado antes de entrar.
- Intervalo base proposto: 8 s de simulação; 12 s antes de chefe. Valores editáveis por onda. Na primeira apresentação de uma mecânica, mostrar a explicação antes da contagem iniciar.
- O contador dispara a onda seguinte automaticamente, uma única vez. Depois da última onda não existe novo contador.
- **Chamar agora** é opcional; concede `min(5, floor(segundos restantes))` moedas uma vez por intervalo. Sem recompensa por simplesmente esperar, pausar ou alternar telas.
- A previsão exibe próxima composição, rota, presença de ar, elite, escudo e chefe; permitir inspecionar também a onda seguinte.
- Não introduzir uma ameaça inédita sem o aviso, o desbloqueio de uma resposta e uma oportunidade econômica de construí-la.
- Suspender o app pausa timers e simulação. Retornar nunca cria vários spawns acumulados pelo tempo fora do jogo.
- Em 2×, o tempo de simulação avança duas vezes mais rápido, incluindo o contador. HUD deve deixar essa relação explícita; o botão de pausa permanece acessível.
- Vitória e derrota no mesmo tick: resolver vazamentos/dano primeiro; vidas zero determina derrota. Uma entidade já resolvida não pode matar e vazar no mesmo tick.
- Eventos empatados seguem ordem estável por timestamp e ID. Duplo toque, sinal duplicado e retorno de pool não podem repetir a onda.

## 4. Construção e escolhas econômicas

Construção em bases fixas; nunca bloquear a estrada. Tocar uma base abre opções com custo, alvo, alcance e tempo. O toque inicial seleciona; a compra depende de botão explícito. A torre selecionada mostra o alcance no chão, sem distorção da câmera.

Moedas inteiras, sem saldo negativo, sem renda passiva, empréstimos ou compras com dinheiro real. Ganhos vêm de mortes e do bônus de antecipação. Eliminar o bônus V1 de onda perfeita como fonte econômica: a partida não deve perder poder de compra adicional depois de já perder vidas. O domínio é reconhecido por estrelas e desafios.

A economia reinicia a cada fase. O jogador melhora sua estratégia; não precisa repetir uma fase para acumular dano permanente. Desbloqueios ampliam opções e aparências. Não haverá árvore de atributos permanentes no primeiro lançamento.

### Construção e evolução

- L1–L3 formam a base de cada família; em L4 escolhe-se uma de duas especializações, consolidada em L5.
- Cada família tem sete configurações visuais/estatísticas: L1, L2, L3, L4A, L5A, L4B, L5B. Uma torre individual passa por cinco níveis.
- Uma especialização muda a função ou a forma de aplicação, não apenas o dano.
- Após escolher o ramo, não é possível trocar gratuitamente durante a partida. Venda e reconstrução seguem o custo normal.
- Níveis avançados entram gradualmente: L1–L2 nas fases 1–2; L3 a partir da 3; L4 na 5; L5 na 9. Esses limites são mostrados antes da partida.
- Construção e upgrade consomem tempo e bloqueiam o ataque daquela torre. Projéteis já liberados continuam.
- Tempos iniciais: construção 3–7 s conforme família; upgrade básico 4–10 s; especializações 8–14 s. Ajustar após testar os intervalos automáticos.
- Cancelar antes de 10% devolve 100% do custo da obra atual; depois, 70%, arredondado para baixo. Cancelar upgrade restaura nível e investimento anteriores.
- Vender torre pronta devolve 60% do investimento concluído. Torre em obra deve primeiro concluir ou cancelar; não permitir reembolso duplo.
- Mostrar claramente investimento, próximo ganho, tempo sem ataque e valor de venda antes da confirmação.

### Formação de batalha

Campanha completa: levar até cinco famílias entre as oito desbloqueadas. Antes de confirmar, avisar se a formação não tem resposta a uma ameaça anunciada. Nas primeiras fases, usar seleção guiada e menos opções. Toda fase deve ter pelo menos duas formações viáveis; registrar as soluções de referência nos testes de balanceamento.

Não permitir que a escolha prévia torne a fase invisivelmente impossível. A previsão e os avisos vêm antes da primeira onda; reinício é rápido e sem custo externo.

## 5. Combate e contrajogo

Filtros GROUND, AIR e BOTH. Prioridades: primeiro, último, mais forte, mais fraco e suporte quando a interface já estiver ensinada. Empate por ID de spawn. Revalidar vivo, elegível e alcance antes da liberação do tiro.

Distância de ataque é medida no plano de gameplay XZ. Altitude de voo e altura da torre são apresentação, sem alteração de alcance invisível. Dano em área usa esse mesmo plano; colisões e obstáculos decorativos não criam bloqueios de tiro sem regra explicitamente anunciada.

Ponto inicial de fórmula: `max(1, dano_base × multiplicadores - armadura_efetiva)`. Físico considera armadura; mágico considera metade; dano puro ignora. Arredondamento e ordem de resolução devem ser únicos e testados.

| Ferramenta | Vantagem | Limite necessário |
|---|---|---|
| Alvo único rápido | Corredores e voadores leves | Perde eficiência contra armadura e enxames |
| Área | Grupos compactos | Menor eficiência em inimigo isolado ou espaçado |
| Perfuração | Tanques/armadura | Cadência menor e risco de excesso de dano |
| Slow | Amplia tempo sob ataque | Não substitui dano, possui piso e resistência de chefe |
| Veneno/sangramento | Dano distribuído no tempo | Pouco tempo para agir perto da saída |
| Suporte | Melhora um conjunto bem posicionado | Não resolve uma rota sozinho; retorno depende de aliados |

Slow usa o maior efeito, nunca soma indefinidamente; piso geral de movimento de 35% da base. Veneno e sangramento: até três fontes diferentes por tipo; mesma fonte renova. Sangramento pode manter bônus de 25% contra quem se move. Ticks de 0,5 s de simulação, com acumulador que preserva o dano em 1×/2×. Chefes: slow máximo de 40%, DoT com metade da duração base; nenhuma imunidade escondida. Resistência, cura e escudo devem constar no bestiário.

Buffs iguais de suporte usam apenas o mais forte. Proibir ciclos multiplicativos entre torres de suporte. Efeitos que reduzem defesa têm limite por alvo e nunca tornam a armadura negativa. Congelamento total, dano percentual e execução precisam de caps explícitos antes de entrar em uma especialização.

Cura não ressuscita, não ultrapassa HP máximo e não cura o próprio aplicador na regra inicial. Escudo é uma camada de vida com leitura própria, não uma vida secreta. Inimigo que invoca unidades tem número máximo de invocações; invocados não geram moedas, impedindo fazenda infinita.

## 6. Dificuldade justa

Três modos sobre a mesma campanha. Normal é o referencial; Aventura é mais acessível; Veterano é uma segunda leitura estratégica. Variantes de composição são escritas e anunciadas, nunca ajustadas secretamente durante a partida.

| Ajuste inicial | Aventura | Normal | Veterano |
|---|---:|---:|---:|
| Vidas | 25 | 20 | 15 |
| HP inimigo | 0,85× | 1,00× | 1,15× |
| Velocidade inimigo | 0,95× | 1,00× | 1,05× |
| Moedas iniciais | 1,15× | 1,00× | 1,00× |
| Recompensa por morte | 1,00× | 1,00× | 1,00× |
| Intervalo comum | 10 s | 8 s | 6 s |
| Composição | Introduções mais leves | Referência | Grupos remixados e elites anunciadas |

Multiplicadores são hipóteses. Concluir uma fase em Aventura ou Normal desbloqueia a seguinte; Veterano é liberado após vencer a fase. Manter recordes e estrelas separados por modo. O jogador pode reduzir dificuldade sem perder o progresso já conquistado.

Aumentar somente um eixo de pressão na introdução: primeiro um tanque, depois tanque com enxame, só depois cura protegida por tanque. Evitar somar velocidade, HP, armadura e duas rotas inéditas na mesma estreia.

Metas de teste, não números já observados: após o tutorial, maioria dos jogadores de primeira viagem deve compreender a causa da derrota; fases iniciais devem ser concluídas em uma ou duas tentativas por grande parte da amostra; Veterano deve exigir adaptação mesmo de quem venceu Normal. Registrar tamanho e perfil da amostra em vez de apresentar percentuais pequenos como prova estatística.

## 7. Progressão e rejogabilidade

Doze fases propostas, em três biomas. Novas torres são desbloqueadas antes das ameaças que exigem seus papéis. Estrelas: uma pela vitória, outra por manter ao menos metade das vidas iniciais, outra por não perder vidas. Não vincular caminho principal à pontuação perfeita.

Após vencer um bioma: desafios opcionais de orçamento, formação limitada ou rotas alternadas. Reusar o mapa com regras novas; não exigir grind. Modo infinito, heróis controláveis, PvP, itens consumíveis e habilidades globais ficam fora do primeiro lançamento.

## 8. Ritmo e apresentação de informações

- Preparação calma; sinal de início; pressão em blocos; pequenas recuperações; clímax com chefe ou composição de domínio.
- Fase 1: meta 5–7 min; fases 2–4: 7–11 min; intermediárias: 10–14 min; finais: 12–18 min em 1×. Cronometrar a duração real incluindo cauda do último inimigo e intervalos.
- Unidade nova estreia em grupo pequeno e reconhecível; aviso curto explica ameaça e uma resposta possível.
- No máximo uma mecânica inteiramente nova por fase introdutória. Combinações posteriores podem exigir várias respostas já aprendidas.
- HUD: vidas, moedas, onda atual/total, próxima onda, timer, pausa e velocidade. Painel de torre contextual com informações compactas.
- Resultado: vidas, duração, onda alcançada, tipos de vazamento, gasto por família, dano útil e duas sugestões específicas baseadas no ocorrido.
- Dano útil exclui excesso sobre a vida restante; isso evita a estatística favorecer artificialmente torres lentas de dano alto.

## 9. Salvamento, acessibilidade e controles

Android em paisagem e PC para desenvolvimento. Toque único, alvos grandes, safe areas e feedback de compra. Voltar fecha painel; depois pausa; depois confirma saída. Sem gestos de precisão obrigatórios.

Save versionado e atômico de campanha, estrelas, configurações e bestiário. A V2 mantém inicialmente a regra de não retomar uma batalha após encerrar o processo; a interface deve avisar antes de sair. Suspensão normal apenas pausa enquanto o processo permanece vivo. Avaliar checkpoint entre ondas após validar o núcleo; não prometê-lo sem implementação.

Texto PT-BR em UTF-8 e chaves de localização. Escala de UI, redução de movimento/flashes, ícones redundantes com cores e volumes independentes. Pausar pode ser usado para planejar; não é penalizado.

## 10. O que significa diversão validada

Uma fase precisa admitir estratégias diferentes, uma decisão relevante de compra ou upgrade em cada bloco de ondas e uma conclusão compreensível. Realizar sessões assistidas sem dar respostas ao jogador. Registrar onde ele hesita, se entende a ameaça e por que reinicia. Só expandir quando o fluxo básico for claro e houver vontade de repetir para melhorar a estratégia.
