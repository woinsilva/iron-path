# Iron Path — candidata 0.9.0-rc1

Data: 2026-10-20. Pacote local para validação do jogador, sem publicação em loja.

## Arquivos

- PC: `../builds/0.9.0-rc1/Windows/IronPath.exe` (ou `../Testar.cmd`). Não precisa de Godot instalado. Mantenha o arquivo PCK junto ao executável.
- PC portátil: `../builds/0.9.0-rc1/IronPath-Windows-0.9.0-rc1.zip`.
- BlueStacks: `../builds/0.9.0-rc1/IronPath-BlueStacks-0.9.0-rc1.apk`.
- S23 Ultra: `../builds/0.9.0-rc1/IronPath-S23-0.9.0-rc1.apk`.
- Hashes SHA256 e tamanhos: `../builds/0.9.0-rc1/manifest.json`.

Os APKs têm assinatura debug local, versão9001/0.9.0-rc1 e pacote `org.ironpath.game`; suportam ARM64 e x86_64. Sem permissão de internet. Só a variante BlueStacks desabilita frame pacing na cópia de exportação; a variante S23 mantém o padrão. Não são um AAB assinado para loja.

## Verificações concluídas

| Verificação | Resultado | Evidência local |
|---|---|---|
| Importação e suíte integrada | 666 linhas de verificação PASS, sem erros/warnings; runner concluído | `test-results/p10-final-suite.log` |
| Save e recuperação | 37 checks, incluindo tempo inválido, backup e progressão | Mesma suíte, `campaign-save.log` |
| Ciclo de vida | 16 checks: Back/Escape, previsão, seleção, suspensão, preferências, duplicação e reinício | Mesma suíte, `lifecycle.log` |
| Enquadramento | 24 casos: 12 fases em 16:9 e20:9 | Mesma suíte, `framing.log` |
| Fluxo completo da fase1 | 9 checks: confirmação, dinheiro real, 10 ondas/106 inimigos, vitória, resultado, save, próxima fase e reinício | `test-results/p10-release-flow-final.log` |
| Executável Windows exportado, Vulkan Mobile | 7 checks: JSON/GLB empacotados, compra, Back, retomada, três perfis, reinício, créditos; saída normal sem erros | `test-results/p10-windows-exported-flow.log` |
| Integridade | Hashes dos arquivos de distribuição conferidos; ZIP/APKs sem entradas corrompidas | `builds/0.9.0-rc1/manifest.json` e logs de assinatura |
| APKs | Assinaturas verificadas; arquiteturas ARM64/x86_64 e manifesto inspecionados com aapt2 | `test-results/*-signature.log`, `p10-apk-aapt2.txt` |
| Conteúdo/dificuldades | 12 fases/212 ondas; duas referências Normal/Aventura e referências próprias Veterano previamente aprovadas, sem alteração posterior das regras | Relatórios P8 e suíte P10 |

Os testes de persistência usam saves isolados; não concedem vitória ao save do jogador. O teste de Windows usa um script externo de QA sobre o binário exportado. Não confundir a saída forçada `--quit-after` (que pulou o shutdown de áudio e emitiu warnings) com a saída normal: a evidência aprovada usa o fechamento do aplicativo, que aguardou e liberou o áudio.

89 arquivos de código/dados/cenas são comparados entre fontes e staging da candidata. Após o benchmark, ajustes de interface corrigiram o aviso do tutorial e a troca de cena no reinício, além dos créditos. Essas rotinas não são chamadas pelo benchmark, que instancia BattleView diretamente e inicia a onda pela simulação. Toda a simulação, modelos, dados, cenas e autoloads continuam idênticos. Relatório: `test-results/p10-snapshot-equivalence.json`.

## Android da candidata

Partida completa em BlueStacks Pie64/API28, Vulkan Mobile/Equilibrado,2×: 24ondas,472inimigos eliminados,0vazamentos,20vidas,88860ticks e741.113s reais. Log sem erros ou warnings. Mediana16.665ms,p9517.479,p9919.314,pico181.057ms; memória estática Godot máxima104630487bytes (não é RAM total/VRAM). Há picos ocasionais registrados; não atribuímos causa sem perfil controlado. Houve testes Windows renderizados e outros testes no mesmo host durante a amostra. Não é certificação do S23 nem aprovação de fluidez perfeita.

Arquivos: `test-results/p10-android-benchmark.json/.log`, hash do APK QA em `p10-android-benchmark-build.json`, captura `p10-android-complete.png`. O pacote QA é isolado e não grava a campanha do jogador.

No APK do jogo, toque confirmou menu, formação, duas compras com custo real, combate e onda2 automática; Back primeiro fecha seleção e depois pausa, e outro Back retoma. Capturas da pausa separadas por2s são idênticas. Home/retorno voltou pausado; alternância2× e reinício foram inspecionados. Reinício inicialmente reproduziu erro `can_process` ao remover a cena dentro do evento de clique; a troca passou a manter a cena antiga na árvore até queue_free e desabilitá-la, nova conferência do APK atualizado aprovada: três reinícios por toque,0erros/warnings em `p10-android-restart-after.log`, campo em preparação/200moedas. Tutorial salvo permaneceu concluído após reiniciar o processo; nenhuma vitória foi concedida à campanha do jogador.

Encerramento normal pelo Back no menu e abertura seguinte também aprovados, sem erros/warnings (`p10-android-final-interactive.log`). Instalação atualizada preservou as preferências e o tutorial. O jogo foi deixado no menu principal do BlueStacks.

Após a suíte666, os ajustes finais foram verificados novamente com tutorial10/10, ciclo de vida16/16,save37/37, fluxo completo9/9 e executável exportado7/7. São verificações focadas com sobreposição à suíte, não uma soma de casos únicos.

## O que o jogador precisa validar

- Movimento em curvas, sob lentidão e em2×; leitura de personagens e alvos.
- Arte dos três biomas, interface, som e clareza das melhorias.
- Diversão, dificuldade e duração. As referências automáticas provam viabilidade, não diversão; não representam uma otimização matemática de todas as formações possíveis.
- Desempenho, calor e bateria no S23 físico ainda não executados. BlueStacks usa a GPU do PC e não certifica o aparelho.

A partida em andamento reinicia em preparação depois de fechar o processo. Resultados concluídos, formação e preferências persistem. O Laboratório do Arsenal compara famílias e evoluções sem dar estrelas à campanha. Não houve reset, commit em massa, compra de assets nem publicação.
