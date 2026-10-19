# Especificação técnica — Godot 4

## 1. Projeto

- Godot 4.x estável; renderer Mobile.
- GDScript tipado e formatação consistente.
- Base 1920×1080, stretch mode `canvas_items`, aspect `expand`.
- Landscape, safe area aplicada ao HUD.
- Física 60 ticks/s; lógica de combate fora de colisões físicas sempre que possível.
- Identificadores e código em inglês; conteúdo localizado em português.

## 2. Estrutura

```text
project.godot
autoload/
  game_session.gd
  save_service.gd
  audio_service.gd
  scene_router.gd
data/
  towers/
  enemies/
  waves/
  maps/
  localization/
scenes/
  app/
  battle/
  maps/
  towers/
  enemies/
  projectiles/
  ui/
scripts/
  battle/
  components/
  data/
  ui/
art/
audio/
tests/
tools/
```

Autoloads são serviços de ciclo do aplicativo; nenhum deles executa lógica por inimigo a cada frame.

## 3. Cenas principais

- `Main.tscn`: bootstrap e roteamento.
- `MainMenu.tscn`, `MapSelect.tscn`, `Settings.tscn`.
- `Battle.tscn`: `MapRoot`, `EntityRoot`, `ProjectileRoot`, `EffectRoot`, `BattleHUD`, managers.
- Cada mapa contém paths terrestres/aéreos, spawns, exit, pads e decoração.
- Torre = `Tower` + `TargetingComponent` + `WeaponComponent` + visual.
- Inimigo = `Enemy` + `HealthComponent` + `MovementComponent` + `StatusComponent` + visual.

## 4. Dados como Resources

### TowerDefinition

`id`, `display_name_key`, `description_key`, `target_layer`, `levels[]`, `icon`, `scene`, `tags`.

`TowerLevel`: `cost`, `build_time`, `damage`, `damage_type`, `attacks_per_second`, `range`, `projectile_speed`, `splash_radius`, `effect_definition`, `visual_level`.

### EnemyDefinition

`id`, `display_name_key`, `movement_layer`, `base_hp`, `base_speed`, `armor`, `reward`, `leak_damage`, `effect_resistances`, `abilities`, `scene`.

### WaveDefinition

Lista de grupos: `enemy_id`, `count`, `spawn_interval`, `start_delay`, `path_id`, `modifiers`.

### MapDefinition

`id`, `display_name_key`, `scene`, `thumbnail`, `starting_coins`, `lives`, `wave_set`, `unlock_requirement`, `hp_multiplier`.

Todos os Resources têm validação em editor/teste: IDs únicos, referências válidas, valores não negativos e níveis ordenados.

## 5. Sistemas

### WaveManager

- Máquina de estados definida em `GAME_SPEC.md`.
- Usa seed explícita para qualquer variação cosmética ou de rota.
- Onda termina somente quando todos os grupos terminaram e não há inimigos vivos.
- Emite sinais de início, progresso, fim e conclusão de todas as ondas.

### BuildManager

- Centraliza transações atômicas de compra, cancelamento, upgrade e venda.
- Verifica pad, moedas, estado e definição antes de debitar.
- Cada ação retorna resultado tipado com código de erro localizável.
- Impede duplo toque com lock curto até o fim da transação do frame.

### Targeting

- Consulta espacial atualizada em intervalos de 0,10 s, distribuídos entre torres.
- Ordenação determinística por prioridade e `spawn_sequence_id`.
- Exibe alcance sem alterar a lógica.

### Projectile/Damage

- `DamageEvent` imutável: fonte, alvo, valor, tipo, posição, efeito e timestamp de simulação.
- Projétil perdido pode desaparecer ou explodir na última posição conforme definição.
- Dano, morte e recompensa são processados uma vez em pipeline ordenado.

### Status

- Efeitos armazenam fonte, potência, duração restante e acumulador de tick.
- Slow usa máximo; DoTs usam cargas limitadas conforme regras.
- Pausa congela duração e tick.

### Pooling

Pools para inimigos, projéteis, indicadores de dano e VFX. Objetos retornados ao pool limpam sinais, timers, efeitos, alvo, shader e estatísticas.

## 6. Save

Arquivo `user://savegame.json`, com `schema_version`, progresso, estrelas, tutorial, configurações e melhores resultados. Não salvar batalha ativa.

- Escrita atômica em temporário e rename.
- Validar tipos/faixas ao carregar.
- Backup do último save válido.
- Dados corrompidos geram novo save e preservam o arquivo inválido para diagnóstico.
- Migrações sequenciais entre versões; versão inicial `1`.

## 7. Localização

Todas as strings visíveis usam chaves. CSV em UTF-8 com `pt_BR`; arquitetura permite `en`. Números passam por formatador local. Nenhum texto é renderizado dentro de sprite.

## 8. Mobile

- Toque e mouse mapeiam para ações abstratas.
- Android back: fecha painel, depois pausa, depois confirma saída.
- Suspensão/perda de foco pausa e salva configurações/progresso concluído.
- Vibração é opcional e nunca essencial.
- Evitar alocação por frame e shaders caros em tela cheia.

## 9. Performance

Cenário-alvo de teste: 120 inimigos vivos, 30 torres, 150 projéteis/VFX, 2×. Meta 60 FPS; piso 30 FPS. Limites degradáveis: partículas, sombras dinâmicas, números de dano e áudio simultâneo. A lógica de dano nunca é removida na degradação.

## 10. Testes

### Unitários

- Fórmula de dano e armadura.
- Slow máximo, renovação e piso.
- Cargas/ticks de veneno e sangramento.
- Construção, cancelamento, venda e arredondamento.
- Escalonamento por onda/mapa/dificuldade.
- Prioridades com desempate determinístico.
- Save válido, corrompido e migração.

### Integração

- Onda nasce, percorre path e termina.
- Morte concede moeda uma vez; vazamento não concede.
- Upgrade desativa e reativa torre corretamente.
- Pausa e 2× preservam timers.
- Vitória/desbloqueio/estrelas persistem.
- Aéreo ignora torres terrestres e recebe dano de torres compatíveis.

### Smoke mobile

- Boot → menu → mapa → construir → iniciar onda → pausar → voltar → terminar/sair.
- Rotação do dispositivo não quebra orientação/layout.
- Suspender e retomar não acelera timers.
- Safe areas não cobrem controles.

## 11. Comandos esperados

O Codex deve detectar o executável Godot disponível e documentar comandos reais. Exemplos conceituais:

```text
godot --headless --path . --editor --quit
godot --headless --path . -s res://tests/run_all.gd
godot --path .
```

Não afirmar que export Android foi validado sem gerar o artefato e registrar o caminho.

