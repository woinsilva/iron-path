# Especificação de jogo — Iron Path

## 1. Visão

Iron Path é um tower defense 2D de visão superior 3/4 para celular. O jogador protege um núcleo contra ondas terrestres e aéreas, construindo e melhorando torres durante a batalha. Construções levam tempo, portanto gastar moedas também é uma decisão temporal: uma torre cara não resolve uma emergência imediatamente.

### Pilares

1. **Decisões legíveis:** alcance, alvo, dano e estado devem ser entendidos sem abrir menus complexos.
2. **Tempo como recurso:** construção e upgrade criam janelas de vulnerabilidade.
3. **Contrajogo:** não existe torre universal; composição de ondas exige diversidade.
4. **Partidas compactas:** 10–18 minutos por mapa na velocidade 1×.
5. **Mobile primeiro:** ações com um toque, alvos grandes e nenhum gesto obrigatório de precisão.

## 2. Escopo

### MVP

- Campanha linear com 3 mapas e três dificuldades.
- 6 famílias de torre, cada uma com níveis 1–3.
- 8 famílias de inimigo, incluindo aéreo e chefe.
- 20 ondas por mapa.
- Tutorial contextual no mapa 1.
- Salvamento local de progresso, configurações e melhores resultados.
- Português do Brasil e estrutura pronta para localização.

### Fora do MVP

- Multiplayer, ranking online, conta, nuvem, energia, gacha, anúncios e compras.
- Posicionamento livre, heróis, habilidades consumíveis e árvore meta permanente.
- Editor de mapas para o jogador.

## 3. Fluxo do usuário

`Inicialização → Menu → Seleção de mapa/dificuldade → Preparação → Batalha → Vitória/Derrota → Resultado → Menu`

O jogo salva após configuração, resultado de partida e desbloqueio. Fechar durante batalha não permite continuar a partida no MVP.

## 4. Regras da batalha

### Recursos

- **Vidas:** 20 no Normal. Cada inimigo que alcança a saída remove seu valor de vazamento.
- **Moedas:** começam conforme mapa/dificuldade; ganhas somente ao derrotar inimigos e por bônus de onda perfeita.
- **Tempo:** construções, upgrades, recargas e efeitos seguem o relógio da simulação.

### Estados

- `PREPARATION`: primeira onda ainda não começou; construção permitida.
- `WAVE_ACTIVE`: inimigos surgindo ou vivos; construção permitida.
- `INTERMISSION`: intervalo de 8 s; botão “iniciar agora” concede +1 moeda por segundo restante, máximo +5.
- `PAUSED`: simulação congelada; UI continua responsiva.
- `VICTORY` e `DEFEAT`: simulação encerrada e resultado persistido.

### Velocidade

- 1× e 2×; pausa separada.
- 2× é desbloqueada após a onda 3 do tutorial.
- A troca não altera cooldowns acumulados nem ordem de alvos.

### Construção

- Torres são colocadas apenas em `BuildPad` vazio.
- Ao confirmar, o custo é debitado e surge um canteiro com barra de progresso.
- A torre não ataca até 100% da construção.
- Cancelar construção devolve 100% se o progresso for menor que 10%; depois disso, 70% do custo pago.
- Vender torre ativa devolve 60% de todo o ouro investido naquela torre, arredondado para baixo.
- Upgrade bloqueia ataques e efeitos emitidos pela torre durante a obra; projéteis já lançados continuam.
- Cancelar upgrade segue a mesma regra da construção e restaura o nível anterior.
- Uma torre em construção não pode ser vendida e cancelada no mesmo frame.

### Alvos

Filtros: `GROUND`, `AIR` ou `BOTH`. Prioridades selecionáveis por torre: primeiro, último, mais forte ou mais fraco. Padrão: primeiro.

- “Primeiro” = maior progresso normalizado no caminho.
- Empate: menor `spawn_sequence_id`.
- Torre nunca escolhe unidade fora de seu filtro, morta ou fora do alcance real.
- Alvo é revalidado imediatamente antes de disparar.

### Dano

`dano_final = max(1, dano_base × multiplicadores - armadura)`

- Dano físico sofre armadura.
- Dano mágico ignora 50% da armadura.
- Dano puro ignora armadura, reservado para ticks de veneno/sangramento e chefes futuros.
- Resistências de efeito reduzem duração, nunca abaixo de 25% da duração original.
- Ataque em área usa distância ao centro do impacto; não há friendly fire.

### Efeitos

- **Slow:** usa apenas o maior slow ativo; duração pode ser renovada. Piso de velocidade: 35% da base.
- **Veneno:** dano puro por segundo. Mesmo aplicador renova duração; fontes diferentes acumulam até 3 cargas.
- **Sangramento:** dano puro por segundo e aumenta em 25% contra alvo em movimento; até 3 cargas de fontes diferentes.
- **Imunidade de chefe:** chefe recebe no máximo 40% de slow e 50% da duração nominal de DoT.
- Ticks ocorrem a cada 0,5 s com acumulador, preservando dano entre 1× e 2×.

### Morte e recompensa

- Um inimigo concede recompensa exatamente uma vez, ao transicionar de vivo para morto.
- Inimigo vazado não concede moeda.
- DoT credita a morte à torre que aplicou a carga responsável pelo último dano.
- Estatísticas por torre: dano total, eliminações e tempo ativo.

## 5. Progressão

### Campanha

- Mapa 1 disponível inicialmente.
- Vitória no Normal desbloqueia o mapa seguinte.
- Fácil, Normal e Difícil usam multiplicadores de `CONTENT_BALANCE.md`.
- Avaliação: 1 estrela por vitória, +1 se restarem pelo menos 10 vidas, +1 se nenhuma vida for perdida.
- Estrelas são registro de domínio, não moeda.

### Tutorial contextual

1. Destacar um BuildPad e mandar construir Arqueira.
2. Iniciar onda.
3. Explicar moedas e recompensa.
4. Mandar fazer upgrade.
5. Na primeira unidade blindada, sugerir Canhão/Alquimista.
6. Antes da primeira onda aérea, destacar a torre Antiaérea.
7. Liberar 2× e prioridades.

Tutoriais pausam a simulação somente quando uma decisão obrigatória é exibida. Podem ser pulados e não reaparecem após conclusão.

## 6. Mapas

### Mapa 1 — Vale Verde

- Tema: pradaria, estrada de terra, riacho e moinho.
- Uma entrada, uma saída, caminho em S, 12 BuildPads.
- Comprimento de caminho: 1500 unidades de jogo.
- Ensina fundamentos; nenhuma bifurcação.

### Mapa 2 — Garganta Rubra

- Tema: cânion, pontes de madeira e lava distante.
- Duas entradas que convergem, uma saída, 14 BuildPads.
- Caminhos de 1250 e 1380 unidades.
- Exige cobertura de duas frentes e introduz curandeiro.

### Mapa 3 — Pântano Sombrio

- Tema: pântano bioluminescente, ruínas e névoa leve.
- Uma entrada terrestre, uma rota aérea direta e uma saída, 13 BuildPads.
- Terrestre: 1650 unidades; aéreo: 1050 unidades.
- Mistura resistências, grupos densos e chefe final.

### Regras de layout

- Estrada tem no mínimo 96 px visuais de largura na base 1920×1080.
- BuildPad não pode sobrepor estrada, UI ou outro pad.
- Ao menos 40% do caminho deve estar coberto por dois ou mais pads de alcance médio.
- A entrada e saída permanecem visíveis; nenhuma decoração prejudica hitboxes.
- Rota aérea é indicada por sombras/setas sutis antes da onda.

## 7. UX e interface

### HUD de batalha

- Superior esquerdo: vidas.
- Superior centro: onda atual/total e contador da próxima onda.
- Superior direito: moedas, pausa e velocidade.
- Rodapé: painel contextual da torre/pad selecionado.
- Pressionar pad abre carrossel de torres disponíveis com custo e tempo.
- Pressionar torre exibe alcance, alvo atual, prioridade, upgrade e venda.
- Toque fora fecha o painel; nenhuma ação econômica ocorre sem botão explícito.

### Feedback

- Verde: pode construir; vermelho: recursos insuficientes; amarelo: em construção.
- Barra de vida para inimigo danificado; barra segmentada maior para chefe.
- Ícones acima do inimigo para slow, veneno e sangramento, sem texto flutuante excessivo.
- Ao tentar ação inválida: vibração curta opcional, som discreto e motivo em uma linha.
- Valores devem caber até 999.999 moedas e onda 999 sem quebrar layout.

### Acessibilidade

- Escala de UI 90%, 100%, 115%.
- Opção de vibração, música, efeitos e redução de flashes.
- Estados nunca dependem somente de cor; sempre combinar ícone/forma.
- Fonte mínima equivalente a 28 px na base 1920×1080.
- Não exigir multitouch.

## 8. Áudio e pausa de aplicativo

- Perda de foco pausa automaticamente.
- Áudio respeita estado silencioso/configuração da plataforma.
- Música continua entre telas com crossfade; batalha possui camada adicional nas ondas de chefe.

## 9. Métricas locais de balanceamento

Sem telemetria externa. Em builds de desenvolvimento, registrar por partida: mapa, dificuldade, duração, onda final, moedas ganhas/gastas, torres por tipo, dano por tipo, vidas finais e velocidade mais usada. Exportação opcional para JSON local.

