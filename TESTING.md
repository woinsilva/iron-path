# Testar o Iron Path

`Testar.cmd` abre a candidata Windows exportada (sem instalar Godot). `Jogar.cmd` abre as fontes no Godot. A versão 0.9.0-rc1 está em validação, com aceite humano e S23 físico pendentes.

1. Escolha Aventura, Normal ou Veterano e abra a fase disponível.
2. Toque numa base de pedra e confirme a compra: Arqueira custa 70, Canhão 110 moedas.
3. Espere a construção e toque em **Iniciar defesa**. As demais ondas começam automaticamente após o intervalo.
4. Selecione uma torre para melhorar, cancelar a obra ou vender. Use pausa e velocidade 2× para administrar o combate.
5. Vitórias salvam o melhor número de estrelas e tempo; a fase seguinte é desbloqueada. O guia explica alvos terrestres/aéreos, controle e veneno.

A versão de desenvolvimento tem doze fases e 212 ondas. O **Laboratório do Arsenal** permite testar oito famílias e 56 configurações até L5. A campanha libera níveis por fase: L2 no início, L3 na terceira, L4 na quinta e L5 na nona. Há três chefes, rotas terrestres/aéreas, curadores, escudos, auras, resistência mágica, escavadores com emergência anunciada e invocadores limitados. Desafios opcionais de defesa perfeita aparecem após cada bioma.

Atualização 2026-10-20: conteúdo P8 funcional; suíte integrada Normal e campanha Aventura aprovadas. Referências próprias de Veterano aprovadas após ajuste do perfil. A fase12 completou24ondas/472inimigos sem vazamentos no BlueStacks; não é certificação do S23 físico. Polimento técnico P9 implementado; candidata P10 pronta para validação. Estado e evidências em `documents/PROGRESS_V2.md`.

## Comandos

```powershell
./tools/run.ps1 -Test
python -X utf8 tools/check_difficulties.py --difficulty adventure
python -X utf8 tools/check_veteran.py
./tools/run.ps1 -Scene campaign
./tools/run.ps1 -Scene prototype
./tools/run.ps1 -Scene lab3d
```

O runner executa importação, regressões legadas, arena 3D, calibração de passada, simulação, combate, partida completa, save/menu e alpha. Erros e warnings nos logs também reprovam, mesmo com código de saída zero. Evidências ficam em `test-results/`.

## Android de teste

```powershell
python tools/android/prepare_environment.py
python tools/android/export_smoke.py
```

O segundo comando exporta uma cópia isolada para `test-results/IronPathSmoke.apk`, pacote `org.ironpath.smoke`. A configuração local fica em `C:/Dev/Tools/Android/environment.json`. Nenhuma chave de produção/publicação é usada.

Smoke no BlueStacks Pie64/API28 executado: instalação, Vulkan Mobile, menu, toque, construção, combate e pausa, sem erros do Godot no log após workaround de frame pacing exclusivo da cópia para emulador. Capturas inspecionadas: `android-frame-pacing-fix.png`, `android-combat.png`, `android-paused.png`. O smoke inicial contém a primeira fase, anterior às últimas adições alpha.

A tela preta inicial corresponde a [Godot #105598/#121035](https://github.com/godotengine/godot/issues/105598); o exportador de smoke desabilita frame pacing apenas no staging. A orientação landscape e importação ETC2/ASTC estão configuradas no projeto. O renderer de produção continua Mobile.

BlueStacks usa a GPU do PC; isso não valida FPS, aquecimento ou consumo do Galaxy S23 Ultra. Testes no aparelho e validação humana de diversão/qualidade ficam para o aceite final. Estado detalhado em `documents/PROGRESS_V2.md`.

O benchmark Android da fase12 é exportado com `python -X utf8 tools/android/export_smoke.py --benchmark --stage 12`, pacote QA isolado `org.ironpath.benchmark.stage12`; não grava estrelas nem desbloqueia a campanha. O snapshot efetivamente ensaiado está preservado como `test-results/IronPathBenchmark12-run1.apk`, hash em `p8-android-build.json`. Não confundir esse ensaio com o APK final do produto.

## Candidata 0.9.0-rc1

- Windows portátil: `builds/0.9.0-rc1/Windows/IronPath.exe` ou `Testar.cmd`; mantenha `IronPath.pck` junto ao executável.
- Arquivo para transportar: `builds/0.9.0-rc1/IronPath-Windows-0.9.0-rc1.zip`.
- Emulador: `builds/0.9.0-rc1/IronPath-BlueStacks-0.9.0-rc1.apk`.
- Aparelho físico: `builds/0.9.0-rc1/IronPath-S23-0.9.0-rc1.apk`. Ainda não ensaiado em S23 físico; usa frame pacing padrão.
- APKs assinados apenas com chave debug local, pacote `org.ironpath.game`; sem publicação em loja. Variante BlueStacks desabilita frame pacing no staging, sem mudar o projeto de produção.
- Créditos e licenças no menu, avisos de terceiros distribuídos junto ao PC. Fontes de ícone/splash em `art/branding`.
- Reproduzir exportações: `python -X utf8 tools/build_candidate.py` após configurar SDK/JDK local pelo procedimento Android acima. O script não publica nem modifica o save.

O teste de fluxo `test_release_flow.gd` percorre formação, compra real, dez ondas automáticas, vitória, resultado, save, desbloqueio correto, reinício e recarga, com arquivo de save exclusivo de QA. O teste externo `tools/test_exported_candidate.gd` verifica recursos empacotados e saída normal no executável exportado, também com save isolado. O encerramento forçado `--quit-after` ignora o shutdown de áudio do aplicativo e não é a evidência de saída normal; a verificação válida usa `_request_quit` e não reporta recursos vazados.

Validação humana: observar movimento nas curvas e em 1×/2×, clareza dos alvos, prazer de evoluir a defesa, dificuldade e duração. O Laboratório do Arsenal, no fim do menu, permite comparar as oito famílias e ramos sem conceder estrelas à campanha. A partida em andamento não é retomada após fechar o processo; o jogo preserva resultados, formação e preferências.

Resultado final: candidata0.9.0-rc1 instalada e ensaiada no BlueStacks; use Testar.cmd no PC. Relatório consolidado em documents/VALIDATION_RC1.md.
