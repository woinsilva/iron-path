# Changelog — Iron Path

Todas as mudanças notáveis do projeto são documentadas aqui.
Formato baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/).

## [0.1.0] — 2026-09-01

### M0 — Bootstrap

#### Adicionado
- `project.godot` — Configuração do projeto Godot 4 com renderer Mobile, resolução 1920×1080, stretch `canvas_items`/`expand`, orientação landscape, 60 ticks/s de física.
- Autoloads: `GameSession`, `SaveService`, `AudioService`, `SceneRouter` — stubs funcionais com tipagem e sinais.
- Resources fundamentais: `TowerDefinition`, `TowerLevel`, `EnemyDefinition`, `WaveDefinition`, `WaveGroup`, `MapDefinition` — todos com validação integrada.
- `ResourceValidator` — validação cruzada de coleções (IDs únicos, referências válidas, custos ordenados).
- `Main.tscn` + `main.gd` — Cena bootstrap com diagnóstico de resolução, renderer e autoloads.
- Framework de testes: `TestBase`, `run_all.gd` (runner headless) e `test_resource_validation.gd` (16 testes).
- Estrutura completa de diretórios conforme `TECHNICAL_SPEC.md`.
- `CHANGELOG.md`, `DECISIONS.md`, `art/ASSET_SOURCES.md`.

### M1 — Fatia vertical mínima

#### Adicionado
- Mapa 1 (`map_01.tscn`) com `Path2D` e espaços de construção (`BuildPad`).
- Entidade inimiga (`grunt.tscn`) separada em componentes (`HealthComponent`, `MovementComponent`).
- Entidade torre (`archer.tscn`) e projétil (`arrow.tscn`) separados em componentes (`TargetingComponent`, `WeaponComponent`).
- Gerenciadores de fluxo: `WaveManager`, `BuildManager` e cena raiz `battle.tscn`.
- HUD principal (`battle_hud.tscn`) informando vidas, moedas, onda atual e permitindo iniciar as ondas.
- Testes unitários para M1: 7 novos testes validando armadura, dano e custos de construção (`test_m1_components.gd`).
