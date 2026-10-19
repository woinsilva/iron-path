# Conteúdo e balanceamento inicial

Todos os valores são ponto de partida e devem viver em dados editáveis. Alcance está em unidades de jogo; cadência é disparos/s; tempo está em segundos.

## 1. Torres

| ID | Nome | Alvo | Papel | N1 custo/obra | N2 custo/obra | N3 custo/obra |
|---|---|---|---|---:|---:|---:|
| archer | Arqueira | Ambos | alvo único rápido | 70 / 3 | 95 / 5 | 145 / 8 |
| cannon | Canhão | Terra | explosão | 110 / 6 | 155 / 9 | 230 / 13 |
| frost | Cristal Gélido | Ambos | slow | 90 / 5 | 125 / 7 | 190 / 11 |
| venom | Alquimista | Terra | veneno | 100 / 5 | 145 / 8 | 215 / 12 |
| bleed | Balista Serrilhada | Terra | sangramento | 120 / 7 | 170 / 10 | 250 / 15 |
| anti_air | Farol Celeste | Ar | antiaérea | 85 / 4 | 120 / 6 | 180 / 9 |

### Estatísticas por nível

| Torre | Nível | Dano | Cadência | Alcance | Propriedade |
|---|---:|---:|---:|---:|---|
| Arqueira | 1 | 12 | 1,25 | 210 | físico |
| Arqueira | 2 | 22 | 1,40 | 225 | +10% crítico 2× |
| Arqueira | 3 | 38 | 1,60 | 240 | +15% crítico 2× |
| Canhão | 1 | 36 | 0,55 | 190 | raio 62, físico |
| Canhão | 2 | 65 | 0,58 | 205 | raio 72 |
| Canhão | 3 | 110 | 0,62 | 220 | raio 84 |
| Cristal Gélido | 1 | 7 | 0,80 | 185 | slow 20%, 1,5 s |
| Cristal Gélido | 2 | 13 | 0,90 | 200 | slow 28%, 1,8 s |
| Cristal Gélido | 3 | 22 | 1,00 | 215 | slow 35%, 2,1 s; impacto raio 38 |
| Alquimista | 1 | 5 | 0,70 | 180 | veneno 4 DPS, 3 s |
| Alquimista | 2 | 9 | 0,78 | 195 | veneno 7 DPS, 4 s |
| Alquimista | 3 | 15 | 0,85 | 210 | veneno 12 DPS, 5 s |
| Balista | 1 | 25 | 0,55 | 225 | sangramento 5 DPS, 3 s |
| Balista | 2 | 45 | 0,58 | 240 | sangramento 9 DPS, 4 s |
| Balista | 3 | 78 | 0,62 | 255 | sangramento 15 DPS, 5 s |
| Farol Celeste | 1 | 16 | 1,15 | 245 | +25% dano contra ar |
| Farol Celeste | 2 | 29 | 1,30 | 260 | +35% contra ar |
| Farol Celeste | 3 | 50 | 1,50 | 275 | +50% contra ar; ricochete 40% para 1 alvo |

### Regras econômicas

- `investimento_total` soma construção e upgrades concluídos ou em andamento.
- Venda: `floor(investimento_total × 0,60)`.
- Custos mostrados são fixos dentro de uma partida.
- Sem juros, renda passiva ou custo de manutenção no MVP.

## 2. Inimigos

Valores base são para o mapa 1 Normal antes do escalonamento por onda.

| ID | Nome | Movimento | HP | Velocidade | Armadura | Recompensa | Vazamento | Traço |
|---|---|---|---:|---:|---:|---:|---:|---|
| grunt | Saqueador | Terra | 70 | 70 | 0 | 6 | 1 | básico |
| runner | Corredor | Terra | 48 | 115 | 0 | 7 | 1 | rápido |
| brute | Bruto | Terra | 260 | 45 | 8 | 16 | 2 | tanque |
| swarm | Rastejante | Terra | 32 | 82 | 0 | 3 | 1 | grupos numerosos |
| armored | Guardião | Terra | 180 | 58 | 18 | 14 | 2 | armadura alta |
| healer | Xamã | Terra | 125 | 55 | 4 | 18 | 2 | cura 10 HP/s em raio 120; não cura a si |
| flyer | Vespa Sombria | Ar | 85 | 92 | 2 | 10 | 1 | ignora estrada terrestre |
| boss | Colosso | Terra | 2600 | 34 | 16 | 150 | 10 | resistência de chefe; aura +10% velocidade |

### Limites

- Cura não ressuscita e não excede HP máximo.
- No máximo duas auras iguais afetam uma unidade; usar o maior valor, sem somar.
- Inimigo aéreo não recebe colisão de estrada e só pode ser alvo de torre `AIR/BOTH`.
- Chefe não pode ser empurrado ou paralisado no MVP.

## 3. Escalonamento

Para onda `w` iniciando em 1:

- `hp_multiplier = 1 + 0,105 × (w - 1) + 0,006 × (w - 1)^2`
- `reward_multiplier = 1 + 0,035 × (w - 1)`
- `speed_multiplier = min(1,25; 1 + 0,008 × (w - 1))`
- HP final é arredondado para cima; recompensa para o inteiro mais próximo.

Multiplicadores de mapa sobre HP: Vale 1,00; Garganta 1,18; Pântano 1,38. Recompensas não recebem multiplicador de mapa.

| Dificuldade | HP | Velocidade | Recompensa | Vidas | Moedas iniciais |
|---|---:|---:|---:|---:|---:|
| Fácil | 0,80 | 0,95 | 1,10 | 25 | 230 |
| Normal | 1,00 | 1,00 | 1,00 | 20 | 200 |
| Difícil | 1,25 | 1,08 | 0,92 | 15 | 180 |

Ordem de aplicação: base → onda → mapa → dificuldade → modificador especial. Armadura não escala automaticamente; ondas específicas podem usar variantes.

## 4. Plano das ondas

Cada mapa usa uma tabela explícita. Abaixo está a composição canônica; mapas 2–3 podem dividir grupos entre entradas. Intervalo dentro de grupo: 0,55–1,10 s. Intervalo entre grupos: 2,0 s.

| Onda | Composição |
|---:|---|
| 1 | 8 grunt |
| 2 | 12 grunt |
| 3 | 8 grunt + 5 runner |
| 4 | 16 swarm + 6 grunt |
| 5 | 3 brute + 8 grunt |
| 6 | 10 runner + 10 swarm |
| 7 | 6 armored + 8 grunt |
| 8 | 5 flyer + 10 grunt; avisar ar 8 s antes |
| 9 | 4 brute + 12 runner |
| 10 | miniboss: 1 boss com HP ×0,45 + 12 grunt |
| 11 | 10 armored + 16 swarm |
| 12 | 10 flyer + 8 runner |
| 13 | 3 healer + 12 grunt + 4 brute |
| 14 | 18 runner + 12 swarm |
| 15 | 8 armored + 8 flyer + 4 brute |
| 16 | 4 healer + 20 grunt |
| 17 | 14 flyer + 10 armored |
| 18 | 8 brute + 20 swarm + 2 healer |
| 19 | 12 armored + 12 runner + 10 flyer |
| 20 | 1 boss + 4 healer + 10 armored; boss entra por último |

### Variação por mapa

- Garganta: alternar entradas por grupo; ondas 12, 17 e 19 dividem voadores igualmente.
- Pântano: +20% swarm nas ondas 4, 11, 14 e 18; boss final HP ×1,25; remover 2 armored da onda 20 para compensar.

## 5. Regras de ajuste automático proibidas

Não usar dificuldade dinâmica oculta, rubber-banding ou alteração baseada no gasto do jogador. O mesmo mapa, dificuldade e seed devem gerar a mesma onda. Balanceamento é alterado somente nos arquivos de dados.

