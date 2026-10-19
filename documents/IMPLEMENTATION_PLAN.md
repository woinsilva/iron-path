# Plano de implementação

Cada marco termina com jogo executável, testes e atualização do changelog. Não iniciar arte final antes de validar a jogabilidade com placeholders.

## M0 — Bootstrap ✅ (arquivos prontos — validação headless pendente)

- ✅ Criar projeto Godot, estrutura, configurações mobile e repositório.
- ✅ Adicionar tela de diagnóstico e pipeline mínimo de testes.
- ✅ Definir Resources e validadores sem conteúdo completo.
- ⏳ Executar Godot headless (Godot 4 não encontrado no sistema).

**Aceite:** projeto abre headless sem erro; teste trivial passa; resolução e orientação estão configuradas.

## M1 — Fatia vertical mínima ✅

- ✅ Mapa cinza com um path e 3 pads.
- ✅ Um grunt, uma Arqueira, projétil, HP, morte, vazamento e moedas.
- ✅ Construção temporizada, uma onda, vitória e derrota.

**Aceite:** partida pode ser vencida ou perdida apenas por regras reais; recompensa ocorre uma vez; pausa congela tudo.

## M2 — Combate e economia

- Todas as seis torres no nível 1.
- Alvos Ground/Air/Both, prioridades, splash, slow, veneno e sangramento.
- Compra, cancelamento, venda, upgrade temporizado e painel contextual.
- Testes unitários das fórmulas.

**Aceite:** matriz torre×inimigo respeita filtros; efeitos obedecem stacks; ouro nunca fica negativo.

## M3 — Inimigos e ondas

- Oito inimigos, healer, aura, chefe e pooling.
- 20 ondas orientadas por dados.
- Intermissão, iniciar cedo e avisos de ar/chefe.

**Aceite:** simulação automática completa 20 ondas sem erro/nó órfão; seed repete resultados.

## M4 — Mapas e progressão

- Três mapas funcionais, entradas múltiplas e rota aérea.
- Dificuldades, estrelas, desbloqueio e save versionado.
- Seleção de mapa/dificuldade e resultado.

**Aceite:** campanha pode ser concluída; reiniciar app mantém progresso; save corrompido é tratado.

## M5 — UX mobile

- Tutorial, toque, safe areas, back, escala de UI e acessibilidade.
- Configurações de som/vibração/flash.
- Feedback visual e estados de erro.

**Aceite:** fluxo smoke completo em dispositivo ou emulador; nenhum controle menor que o mínimo definido.

## M6 — Arte e áudio

- Gerar/substituir assets conforme manifesto, preservando prompts e fontes.
- VFX, animações, mixagem e três biomas.
- Auditoria para remover placeholders de release.

**Aceite:** todas as referências resolvem, animações não cortam, leitura permanece clara com 120 inimigos.

## M7 — Balanceamento e performance

- Executar simulações e partidas de teste.
- Ajustar somente dados, documentando antes/depois.
- Pooling, budgets de VFX/áudio e profiling em cenário-alvo.

**Aceite:** 60 FPS alvo/30 piso no dispositivo de referência; nenhum tipo de torre é estritamente superior em todos os cenários.

## M8 — Android candidata a lançamento

- Ícone, splash, nome, versão, permissões mínimas, créditos e licenças.
- Export presets, APK debug e AAB release configurável.
- Checklist de privacidade/offline e teste de instalação limpa.

**Aceite:** APK instala e completa o smoke test; AAB é gerado quando credenciais do usuário estiverem disponíveis; nenhum segredo entra no repositório.

## Backlog posterior

- Posicionamento livre, desafios diários offline, modos infinito e sem pausa.
- Novas torres/mapas, talentos e conquistas de plataforma.
- iOS/TestFlight e localização inglesa completa.

