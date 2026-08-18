module main;

import std.getopt;
import std.stdio : writeln, writefln, stdout;
import core.thread : Thread;
import core.time : dur;

import pomodoro;
import sound;
import terminal;
import ui;

void printHelp(string programName)
{
    writeln("==========================================================");
    writeln("  POMODORO TIMER PARA TERMINAL (EM D)");
    writeln("==========================================================");
    writeln("Uso: dub run -- [opções]");
    writeln("  ou ./bin/pomodoro [opções]");
    writeln("");
    writeln("Opções:");
    writeln("  -w, --work <min>        Duração do tempo de foco em minutos (padrão: 25)");
    writeln("  -s, --short-break <min> Duração da pausa curta em minutos (padrão: 5)");
    writeln("  -l, --long-break <min>  Duração da pausa longa em minutos (padrão: 15)");
    writeln("  -c, --cycles <qtd>      Ciclos de foco antes da pausa longa (padrão: 4)");
    writeln("  --no-sound              Inicia com som desativado");
    writeln("  --test-sound            Testa o sintetizador procedural de áudio e sai");
    writeln("  --ascii                 Modo compatibilidade (apenas caracteres ASCII 7-bit)");
    writeln("  -h, --help              Exibe esta mensagem de ajuda");
    writeln("");
    writeln("Atalhos no Terminal:");
    writeln("  [Espaço]   Pausar ou Retomar o temporizador");
    writeln("  [N]/[Enter] Pular para a próxima fase");
    writeln("  [R]        Reiniciar a fase atual");
    writeln("  [+]        Adicionar 1 minuto ao tempo atual");
    writeln("  [-]        Subtrair 1 minuto do tempo atual");
    writeln("  [M]        Ligar / Desligar alarme procedural (Mute)");
    writeln("  [Q]/[ESC]  Sair do programa");
    writeln("==========================================================");
}

int main(string[] args)
{
    PomodoroConfig config;
    bool noSound = false;
    bool testSound = false;
    bool showHelp = false;

    try
    {
        auto helpInformation = getopt(
            args,
            "work|w",        "Duração do foco (minutos)", &config.workMinutes,
            "short-break|s", "Duração da pausa curta (minutos)", &config.shortBreakMinutes,
            "long-break|l",  "Duração da pausa longa (minutos)", &config.longBreakMinutes,
            "cycles|c",      "Quantidade de ciclos de foco", &config.cyclesBeforeLongBreak,
            "no-sound",      "Desativar som procedural", &noSound,
            "test-sound",    "Testar sons procedurais e sair", &testSound,
            "ascii",         "Ativar modo ASCII estrito", &config.asciiMode
        );

        if (helpInformation.helpWanted)
        {
            printHelp(args[0]);
            return 0;
        }
    }
    catch (Exception e)
    {
        writefln("Erro nos argumentos: %s", e.msg);
        writeln("Use --help para ver as opções disponíveis.");
        return 1;
    }

    config.enableSound = !noSound;

    // Modo de teste sonoro procedural
    if (testSound)
    {
        writeln("\n🎵 Testando sintetizador procedural de áudio estéreo...");
        auto soundEngine = new SoundEngine(true);

        writeln("1/2 - Tocando acorde zen relaxante de Fim de Foco (C5 -> E5 -> G5 -> B5 -> C6)...");
        soundEngine.playSync(SoundType.WorkFinished);
        Thread.sleep(dur!"msecs"(1000));

        writeln("2/2 - Tocando sino duplo suave de Retorno ao Foco (A4 -> E5)...");
        soundEngine.playSync(SoundType.BreakFinished);
        Thread.sleep(dur!"msecs"(500));

        writeln("✅ Teste de som concluído com sucesso!\n");
        return 0;
    }

    // Inicialização do Terminal e Estado
    auto term = new Terminal();
    auto sound = new SoundEngine(config.enableSound);
    auto pomo = new Pomodoro(config);
    auto renderer = new Renderer(config.asciiMode);

    term.enterAlternateScreen();
    term.enableRawMode();
    term.hideCursor();

    scope(exit)
    {
        term.restore();
    }

    bool running = true;
    int tickCounter = 0;

    while (running)
    {
        // 1. Processa entrada do teclado (não-bloqueante)
        Key k = term.readKey();
        while (k != Key.None)
        {
            switch (k)
            {
                case Key.Space:
                    pomo.togglePause();
                    sound.play(SoundType.Tick);
                    break;

                case Key.Char_n:
                case Key.Enter:
                    pomo.nextPhase();
                    sound.play(SoundType.Tick);
                    break;

                case Key.Char_r:
                    pomo.resetCurrent();
                    sound.play(SoundType.Tick);
                    break;

                case Key.Plus:
                    pomo.addMinutes(1);
                    sound.play(SoundType.Tick);
                    break;

                case Key.Minus:
                    pomo.addMinutes(-1);
                    sound.play(SoundType.Tick);
                    break;

                case Key.Char_m:
                    sound.toggle();
                    break;

                case Key.Char_q:
                case Key.Escape:
                    running = false;
                    break;

                default:
                    break;
            }
            if (!running) break;
            k = term.readKey();
        }

        if (!running) break;

        // 2. Atualiza o relógio do Pomodoro
        bool completed = pomo.tick();
        if (completed)
        {
            PomodoroMode finishedMode = pomo.getMode();
            
            // Dispara alarme procedural relaxante
            if (finishedMode == PomodoroMode.Work)
            {
                sound.play(SoundType.WorkFinished);
            }
            else
            {
                sound.play(SoundType.BreakFinished);
            }

            pomo.nextPhase();
        }

        // 3. Atualiza frame de animação rústica
        tickCounter++;
        if (tickCounter % 3 == 0)
        {
            renderer.updateAnim();
        }

        // 4. Renderiza a tela
        TerminalSize size = term.getSize();
        renderer.render(pomo, sound, size);

        // 5. Descanso para baixíssimo uso de CPU (~15 FPS)
        Thread.sleep(dur!"msecs"(65));
    }

    return 0;
}
