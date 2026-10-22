# Iron Path — campanha, torres, inimigos e ondas V2

Versão 2 · 2026-10-19 · Catálogo proposto para produção; números ainda precisam de simulação e partidas.

## 1. Escopo em camadas

| Entrega | Fases | Torres | Inimigos | Objetivo |
|---|---:|---|---|---|
| Prova de qualidade 3D | Arena de teste | Arqueira | Goblin | Validar modelo, rig, movimento, tiro, câmera e luz |
| Fatia jogável | 1 fase / 10 ondas | Arqueira e Canhão, L1–L2 | Saqueador e Corredor | Comprovar diversão e ondas automáticas |
| Alpha | 3 fases / 36 ondas | 5 famílias, L1–L3 | 4 arquétipos básicos | Validar ar, controle e progressão |
| Beta de conteúdo | 8 fases / 124 ondas | 8 famílias até L4, dois ramos | Elenco previsto até a fase 8, dois chefes | Validar combinações e especializações |
| Campanha candidata | 12 fases / 212 ondas | 8 famílias até L5 | 12 arquétipos + 4 variantes elite + 3 chefes | Concluir campanha e desafios selecionados |

O lançamento completo contém 16 entradas de inimigos comuns/elite, não 16 esqueletos necessariamente diferentes. Chefes são três entradas adicionais. Cada fase tem uma tabela própria de ondas: não repetir uma única sequência mudando apenas HP.

## 2. Campanha proposta

Três biomas, quatro fases em cada. Os nomes são provisórios. A coluna de bases é faixa inicial para desenho de mapa, não obrigação de preencher todas. Apenas a fase 1 ensina a operação completa dos controles; as seguintes ensinam decisões.

| Fase | Bioma / nome | Ondas | Bases | Nova pressão principal | Novidades disponíveis antes de iniciar |
|---|---|---:|---:|---|---|
| 01 | Vale Verde / Estrada do Moinho | 10 | 8–10 | Cobertura e corredores rápidos | Arqueira e Canhão; L1–L2 |
| 02 | Vale Verde / Pomar Cercado | 12 | 10–12 | Enxames compactos | Cristal Gélido e Farol Celeste; treino de controle |
| 03 | Vale Verde / Travessia do Rio | 14 | 10–12 | Rota aérea indicada | Alquimista; L3 para famílias desbloqueadas |
| 04 | Vale Verde / Portão da Guarda | 16 | 12–14 | Armadura e primeiro chefe | Balista Serrilhada; elite de saqueador |
| 05 | Garganta Rubra / Pontes Gêmeas | 16 | 12–14 | Cura protegida em duas frentes | Torre Arcana; L4 e os dois ramos de cada família disponível |
| 06 | Garganta Rubra / Pedreira dos Gigantes | 18 | 12–14 | Tanques e investimento concentrado | Estandarte de Comando; corredor veterano |
| 07 | Garganta Rubra / Fortaleza Quebrada | 18 | 12–16 | Escudos e ordem de alvo | Todas as oito famílias já disponíveis |
| 08 | Garganta Rubra / Forja do Colosso | 20 | 14–16 | Auras e segundo chefe | Voadores pesados; domínio dos ramos L4 |
| 09 | Pântano Sombrio / Ruínas Veladas | 20 | 12–14 | Resistência mágica | L5; diversificar físico, magia e DoT |
| 10 | Pântano Sombrio / Trilhas Submersas | 22 | 12–16 | Trecho de emergência dos escavadores | Informar pontos de surgimento e cobertura útil |
| 11 | Pântano Sombrio / Ninho das Sombras | 22 | 14–16 | Invocadores com capacidade limitada | Priorizar fonte de pressão, em vez de só enxame |
| 12 | Pântano Sombrio / Coração da Ruína | 24 | 14–18 | Síntese da campanha e chefe final | Guardião de elite; sem mecânica surpresa no final |

Total: 212 ondas de campanha. Introduções simples de dois inimigos básicos na fase 1 formam a base; depois, a cada fase há um foco novo principal. Variantes de elite reutilizam regras conhecidas. Quando uma fase tem duas rotas, introduzir a geometria em ondas leves antes da ameaça nova.

### Geometria e identidade

- **01:** caminho em S, uma entrada e saída; curvas favorecem observar cobertura múltipla. Moinho e riacho fora da área de toque.
- **02:** grupos se aproximam em curvas, mas há trechos espaçados; ensina quando área e slow valem mais que dano direto.
- **03:** ponte e estrada terrestre longa; voadores cruzam uma rota menor, desenhada e prevista no HUD.
- **04:** corredor final de defesa e posições laterais para perfuração; chefe entra por último, sem esconder a saída.
- **05:** duas entradas convergem; o mapa revela com antecedência qual lado recebe cada grupo.
- **06:** posições de cobertura longa contra tanques; zonas alternativas para suporte, sem uma única base obrigatória.
- **07:** entradas alternadas e curva que separa escudos dos grupos; posicionamento e prioridade tornam-se decisivos.
- **08:** arena da forja com confluência e áreas seguras de apoio. Lava é decoração no lançamento, sem dano oculto.
- **09:** ruínas e contraste controlado; mistura de resistência mágica e armadura, anunciada por grupos distintos.
- **10:** rotas subterrâneas demarcadas; inimigos emergem em pontos conhecidos com tempo suficiente de contra-ataque.
- **11:** ninhos e convergência para área; invocadores entram cedo o suficiente para o jogador focá-los.
- **12:** rotas terrestres e aéreas conhecidas, distribuição de cobertura e clímax final. Chefe usa combinações de habilidades já ensinadas.

Em todos: entrada e saída visíveis; bases fora da estrada e da UI; rotas coerentes com cenário; ao menos duas áreas de investimento viáveis. Validar cobertura efetiva, tempo sob fogo e espaço para toque, em vez de aprovar só uma imagem bonita.

## 3. Famílias de torre

Cada família tem ponto forte, deficiência, duas especializações e evolução visual. Custos relativos devem refletir dano útil por tempo de cobertura e a disponibilidade de respostas na fase.

| ID / família | Alvos | Papel e limite | Ramo A, L4–L5 | Ramo B, L4–L5 |
|---|---|---|---|---|
| archer / Arqueira | Terra e ar | Cadência, baixo custo; sofre contra muita armadura | Atiradora: foco e crítico determinístico por sequência, melhor contra isolados | Rajada: até três alvos distintos, dano individual menor; não triplica dano no mesmo alvo |
| cannon / Canhão | Terra | Área física; lento contra espaçados e blindados | Morteiro: área maior e arco lento, ponto de impacto anunciado | Demolidor: raio menor, maior perfuração física; não remove toda defesa |
| frost / Cristal Gélido | Terra e ar | Controle; dano baixo | Geada: pequeno campo de slow, maior cobertura de grupos | Agulha Glacial: slow individual mais intenso; respeita piso e cap de chefe |
| venom / Alquimista | Terra | DoT; precisa de tempo antes da saída | Peste: propagação para vizinhos com limite de alvos por aplicação | Corrosão: DoT e redução limitada de armadura, sem valores negativos |
| bleed / Balista Serrilhada | Terra | Foco físico e sangramento; cadência baixa | Empaladora: linha de perfuração com número máximo de atravessamentos | Caçadora: alvo único, melhor aplicação de sangramento contra tanques |
| anti_air / Farol Celeste | Ar | Resposta aérea eficiente; inútil contra terra | Tempestade: ricochetes limitados entre voadores, dano decrescente | Lança Celeste: foco em alvo aéreo pesado, cadência menor |
| arcane / Torre Arcana | Terra e ar | Dano mágico antiarmadura; cara e vulnerável à resistência mágica | Prisma: feixe sustentado em um alvo, aquecimento limitado que reinicia ao trocar | Conduíte: dano em cadeia limitado, menor eficiência em alvo isolado |
| banner / Estandarte de Comando | Torres aliadas | Suporte sem dano próprio; depende de cobertura e composição | Comando: bônus limitado de cadência, sem acumular com outro igual | Vigília: bônus limitado de alcance e pulsos automáticos de apoio |

**Distinções essenciais:** Arqueira e Farol não devem tornar-se substitutos perfeitos; Balista precisa preservar o valor do foco e do sangramento; Arcana não pode resolver enxame, tanque, suporte e aéreo ao mesmo tempo. Se um ramo sempre vence o outro, redesenhar a função antes de alterar somente o custo.

### Referência inicial para L1

Unidades do mundo em metros; valores de projeto para o primeiro teste. Alcances novos não são uma conversão automaticamente equivalente ao protótipo em pixels.

| Torre | Custo | Obra | Dano direto | Ataques/s | Alcance | Propriedade inicial |
|---|---:|---:|---:|---:|---:|---|
| Arqueira | 70 | 3 s | 12 físico | 1,25 | 4,2 m | Alvo único |
| Canhão | 110 | 6 s | 36 físico | 0,55 | 3,8 m | Área de 1,2 m |
| Cristal | 90 | 5 s | 7 mágico | 0,80 | 3,7 m | Slow 20%, 1,5 s |
| Alquimista | 100 | 5 s | 5 mágico | 0,70 | 3,6 m | Veneno 4 DPS, 3 s |
| Balista | 120 | 7 s | 25 físico | 0,55 | 4,5 m | Sangramento 5 DPS, 3 s |
| Farol | 85 | 4 s | 16 mágico | 1,15 | 4,9 m | Exclusivo ar; bônus inicial de 25% contra ar |
| Arcana | 135 | 6 s | 28 mágico | 0,65 | 3,8 m | Concentração antiarmadura |
| Estandarte | 95 | 4 s | 0 | — | 3,2 m | +10% cadência em aliados; não se afeta |

L2/L3/L4/L5 precisam de tabelas próprias por ramo em Resources: custo incremental, obra, dano, cadência, alcance, projétil, efeito e aparência. Não multiplicar todas as estatísticas juntas automaticamente. O orçamento de uma melhoria deve deixar a decisão entre cobertura adicional e concentração de dano aberta. Validar essa tabela antes de publicar cada torre; o documento não inventa 56 configurações como se já estivessem balanceadas.

### Evolução visual

- L1: função clara e poucas peças.
- L2: reforço da base, material e operador/equipamento.
- L3: mecanismo reconhecível e animação mais elaborada, sem encobrir vizinhos.
- L4: módulo que distingue o ramo: cano, lente, arco, caldeirão ou estandarte próprios.
- L5: acabamento superior e assinatura de ataque; efeitos maiores apenas se continuarem legíveis.

Oito famílias × sete configurações = 56 estados visuais/estatísticos. Reutilizar fundação, rig e peças quando possível; não são necessariamente 56 modelos completos independentes. L5 não deve exigir mais área de toque ou bloquear a visão da saída.

## 4. Elenco de inimigos

Ícones combinam silhueta, equipamento e cor. O papel deve ser identificável sem ler uma ficha durante a onda. A estreia de cada inimigo mostra primeiro um exemplar ou grupo leve.

| ID | Inimigo / estreia | Papel | Resposta e justiça |
|---|---|---|---|
| grunt | Saqueador / 01 | Referência de HP, velocidade e recompensa | Qualquer dano; estabelece leitura de vida e vazamento |
| runner | Corredor / 01 | Rápido e frágil | Cadência e cobertura; não surge correndo junto à saída |
| swarm | Rastejante / 02 | Muitos corpos frágeis | Área; grupos espaçados em outras ondas evitam solução universal |
| flyer | Vespa Sombria / 03 | Rota aérea mais direta | Farol ou família BOTH; desbloqueio e aviso vêm antes |
| armored | Guardião / 04 | Armadura física alta | Magia, corrosão ou foco; ficha mostra armadura |
| healer | Xamã / 05 | Cura aliados próximos | Prioridade suporte e foco; não cura a si nem ressuscita |
| brute | Bruto / 06 | Muita vida, lento, vazamento maior | DoT, foco e tempo sob fogo; animação comunica peso |
| shieldbearer | Portador de Escudo / 07 | Escudo extra visível com recarga limitada | Foco para quebrar escudo; cooldown de recarga explícito |
| standardbearer | Porta-Estandarte / 08 | Aura de velocidade em aliados | Derrubar suporte; aura igual não acumula |
| resistant | Sentinela Rúnica / 09 | Redução de dano mágico | Físico e DoT; símbolo distinto de armadura física |
| burrower | Escavador / 10 | Percorre trecho enterrado conhecido | Emergir em pontos demarcados; todas as torres elegíveis podem atacá-lo na superfície |
| summoner | Invocador / 11 | Gera pequenos rastejantes | Foco na fonte; limite de invocações; crias sem recompensa |
| grunt_elite | Saqueador de Elite / 04 | Variante resistente do básico | Equipamento e tamanho ligeiramente distintos; não ganha habilidade surpresa |
| runner_veteran | Corredor Veterano / 06 | Variante rápida mais resistente | Cadência, slow e trecho de cobertura; velocidade tem teto |
| flyer_heavy | Vespa Couraçada / 08 | Variante aérea pesada | Foco antiaéreo e magia; menor velocidade que a vespa leve |
| armored_elite | Guardião de Elite / 12 | Variante de armadura e vida altas | Combinar respostas já aprendidas; estreia anunciada antes do chefe |

A variante rúnica não é imune a todo dano mágico; o escavador não exige uma única torre de detecção no loadout. Toda composição deve oferecer uma resposta possível com as opções disponíveis e o orçamento previsto.

### Parâmetros e recompensa

Começar por uma unidade de referência: Saqueador com 70 HP, 1,4 m/s, 0 de armadura, 6 moedas e vazamento de 1 vida. Derivar o restante em tabelas de teste, conferindo tempo para matar e cobertura real. Brutos e elites podem vazar 2–3 vidas; chefes, 5–10, sempre exibidos antes da onda. Não carregar o vazamento provisório de 4 vidas do goblin M1 como regra da campanha.

Toda definição exige HP, velocidade, armadura, resistência, recompensa, vazamento, camada, habilidades, limite de invocação, visual e dados de animação. Recompensa deve acompanhar custo efetivo de enfrentar a composição, sem multiplicação oculta por gasto do jogador. Evitar escalar ao mesmo tempo HP, velocidade, quantidade e cura sem orçamento de ameaça correspondente.

## 5. Chefes

| Fase / chefe | Identidade | Habilidade legível | Oportunidade de resposta |
|---|---|---|---|
| 04 / Capitão dos Saqueadores | Armadura, bandeira e marcha pesada | Brado fortalece escolta por intervalo curto; preparação de 1,5–2 s | Focar escolta ou capitão; sem invulnerabilidade completa |
| 08 / Colosso da Forja | Pedra, metal e brasas | Escudo temporário e chamada limitada de reforços, alternados | Adaptar foco e manter dano em área; sem destruir torres permanentemente |
| 12 / Guardião da Ruína | Criatura rúnica de grande porte | Alterna postura resistente, aura e invocação conhecidas; mudança em patamares de HP | Previsão de postura e janela vulnerável; não revelar um contra-ataque inédito na última onda |

Chefes têm barra destacada, fases de habilidade explícitas, cooldowns e teto de invocações. Não bloquear controle com cinematográfica longa durante combate. Uma mudança de fase não apaga projéteis, não cura gratuitamente e não reinicia recompensas. Slow/DoT seguem limites conhecidos. O chefe não teleporta à saída.

## 6. Arcos de ondas por fase

Cada bloco informa intenção; o arquivo final por onda deve registrar grupos, números, horários e rotas. Nem todas as ondas precisam aumentar em força; alternar pressão e recuperação permite reorganização.

| Fase | Apresentação | Desenvolvimento | Pressão / clímax |
|---|---|---|---|
| 01 | 1–3: básico e economia | 4–7: velocidade e upgrade | 8–10: misturas simples e domínio da cobertura |
| 02 | 1–3: retomada | 4–8: enxames e slow | 9–12: densidade versus grupos espaçados |
| 03 | 1–4: prever rota aérea | 5–10: alternar terra e ar | 11–14: misturas em dois trajetos |
| 04 | 1–4: armadura | 5–11: contraste entre leve, elite e blindado | 12–15: preparação econômica; 16: Capitão |
| 05 | 1–4: dividir cobertura | 5–11: curandeiros em grupos pequenos | 12–16: cura protegida com entradas alternadas |
| 06 | 1–4: vida alta e foco | 5–12: tanques e veteranos espaçados | 13–18: DoT, controle e janelas de upgrade |
| 07 | 1–4: quebrar escudo | 5–12: variar suportes e prioridades | 13–18: escudo acompanhado de leves e ar |
| 08 | 1–4: aura | 5–14: voadores pesados e grupos conhecidos | 15–19: recomposição; 20: Colosso |
| 09 | 1–4: resistência mágica | 5–14: alternar armadura e runas | 15–20: usar especializações e dano misto |
| 10 | 1–4: pontos de emergência | 5–15: rotas reveladas e defesa distribuída | 16–22: entradas alternadas sem surpresa de regra |
| 11 | 1–4: origem das crias | 5–15: invocadores escoltados | 16–22: foco em suporte com controle de densidade |
| 12 | 1–6: revisão dos papéis | 7–17: combinações de domínio | 18–23: pressão final; 24: Guardião da Ruína |

### Tabela inicial completa da fase 1

Normal, 200 moedas e 20 vidas, Arqueira/Canhão, L1–L2. Sem chefe e sem aéreo. Estes números só serão aprovados depois de simulação e teste humano na geometria 3D.

| Onda | Composição | Intervalo entre unidades | Intenção |
|---|---|---|---|
| 1 | 6 saqueadores | 1,3 s | Aprender dano, moedas e direção |
| 2 | 8 saqueadores | 1,2 s | Segunda compra e sequência automática |
| 3 | 10 saqueadores | 1,1 s | Valor de cobertura e agrupamento |
| 4 | 4 corredores | 1,4 s | Nova pressão de velocidade, grupo pequeno |
| 5 | 8 saqueadores + 3 corredores | 1,1 / 1,4 s | Separar área e cadência |
| 6 | 12 saqueadores | 0,8 s | Dar espaço ao Canhão e preparar upgrade |
| 7 | 6 corredores | 1,2 s | Melhorar sem abandonar rota |
| 8 | 10 saqueadores + 5 corredores | 0,9 / 1,1 s | Composição mista |
| 9 | 14 saqueadores | 0,8 s | Janela de reorganização, ainda exigente |
| 10 | 12 saqueadores + 8 corredores | 0,8 / 1,0 s | Verificar domínio das duas respostas |

Grupos consecutivos têm 2 s de separação; a primeira unidade do grupo seguinte surge após o término do spawn anterior mais essa separação. Não aplicar escalonamento quadrático V1 junto com estes números sem revisão: usar HP base nesta primeira proposta e ajustar a tabela explicitamente.

As fases seguintes não estão numericamente fechadas. O marco de conteúdo deve transformar cada arco em WaveDefinitions completas e aprovar sua curva; ter 212 linhas de números sem teste não equivale a ter uma campanha pronta.

## 7. Formato das ondas e validação de conteúdo

Campos mínimos de cada onda: ID estável, fase, índice, intervalo após conclusão, grupos, duração esperada, classe de ameaça e aviso. Grupo: inimigo, quantidade, intervalo de spawn, início relativo à onda, rota, modificadores explícitos e limite de invocação quando houver.

Validadores devem rejeitar: IDs ausentes, quantidades negativas, rota inexistente, ameaça sem resposta disponível, desbloqueio posterior à estreia, número de ondas divergente do catálogo, ciclo de invocação ilimitado e spawn depois de estado terminal.

Para cada fase manter pelo menos duas soluções de referência e uma estratégia deliberadamente fraca. Registrar resultado, gasto, torres usadas, perdas, duração e ondas de maior dificuldade. Simulação mede coerência e bugs; pessoas testam clareza, dificuldade e vontade de jogar de novo.

## 8. Plano de balanceamento

1. Aprovar o tempo de cobertura e a caminhada da unidade de referência no mapa.
2. Ajustar L1 das duas torres iniciais e a economia da fase 1.
3. Adicionar uma ameaça por vez; conferir resposta acessível e pelo menos duas escolhas úteis.
4. Avaliar custo por dano útil, controle gerado e influência da posição, incluindo obra sem atacar.
5. Comparar expandir a defesa contra evoluir uma torre, evitando uma escolha sempre superior.
6. Verificar pares de especialização contra solo, enxame, aéreo, tanque e suporte.
7. Testar a campanha com formações diferentes e orçamento real, incluindo erros recuperáveis.
8. Ajustar Veterano por composição e tempo; só depois revisar os multiplicadores.
9. Fazer regressão de todas as fases afetadas a cada alteração de torre ou efeito.

Não usar dificuldade dinâmica secreta. Não impor resistências totais sem alternativa, nem velocidade tão alta que um inimigo atravesse toda a defesa antes de uma decisão humana. O último terço da campanha deve cobrar combinações, não exigir sorte ou conhecimento oculto.
