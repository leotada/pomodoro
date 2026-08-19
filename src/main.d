module main;

import std.getopt;
import std.stdio : writeln, writefln, stdout;
import core.thread : Thread;
import core.time : dur;

import pomodoro;
import sound;
import terminal;
import ui;
import i18n;

void printHelp(string programName, Language lang = Language.PT)
{
    auto tr = getTranslations(lang);
    writeln("==========================================================");
    writeln(tr.helpTitle);
    writeln("==========================================================");
    writeln(tr.helpUsage);
    writeln("");
    writeln(tr.helpOptionsHeader);
    writeln(tr.helpOptWork);
    writeln(tr.helpOptShortBreak);
    writeln(tr.helpOptLongBreak);
    writeln(tr.helpOptCycles);
    writeln(tr.helpOptLang);
    writeln(tr.helpOptNoSound);
    writeln(tr.helpOptTestSound);
    writeln(tr.helpOptAscii);
    writeln(tr.helpOptHelp);
    writeln("");
    writeln(tr.helpShortcutsHeader);
    foreach (s; tr.helpShortcuts)
    {
        writeln(s);
    }
    writeln("==========================================================");
}

int main(string[] args)
{
    PomodoroConfig config;
    bool noSound = false;
    bool testSound = false;
    string langArg = "pt";

    try
    {
        auto helpInformation = getopt(
            args,
            std.getopt.config.caseSensitive,
            "work|w",        "Duração do foco (minutos)", &config.workMinutes,
            "short-break|s", "Duração da pausa curta (minutos)", &config.shortBreakMinutes,
            "long-break|l",  "Duração da pausa longa (minutos)", &config.longBreakMinutes,
            "cycles|c",      "Quantidade de ciclos de foco", &config.cyclesBeforeLongBreak,
            "lang|L",        "Idioma / Language (pt, en)", &langArg,
            "no-sound",      "Desativar som procedural", &noSound,
            "test-sound",    "Testar sons procedurais e sair", &testSound,
            "ascii",         "Ativar modo ASCII estrito", &config.asciiMode
        );

        config.lang = parseLanguage(langArg);

        if (helpInformation.helpWanted)
        {
            printHelp(args[0], config.lang);
            return 0;
        }
    }
    catch (Exception e)
    {
        writefln("Erro nos argumentos: %s", e.msg);
        writeln("Opções de idioma suportadas: 'pt', 'en'. Use --help para ver as opções disponíveis.");
        return 1;
    }

    config.enableSound = !noSound;

    // Modo de teste sonoro procedural
    if (testSound)
    {
        auto tr = getTranslations(config.lang);
        writeln(tr.soundTestStart);
        auto soundEngine = new SoundEngine(true);

        writeln(tr.soundTestWork);
        soundEngine.playSync(SoundType.WorkFinished);
        Thread.sleep(dur!"msecs"(1000));

        writeln(tr.soundTestBreak);
        soundEngine.playSync(SoundType.BreakFinished);
        Thread.sleep(dur!"msecs"(500));

        writeln(tr.soundTestSuccess);
        return 0;
    }

    // Inicialização do Terminal e Estado
    auto term = new Terminal();
    auto sound = new SoundEngine(config.enableSound);
    auto pomo = new Pomodoro(config);
    auto renderer = new Renderer(config.asciiMode, config.lang);

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
