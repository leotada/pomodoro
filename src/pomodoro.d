module pomodoro;

import core.time : Duration, dur, MonoTime;
import i18n;

enum PomodoroMode
{
    Work,
    ShortBreak,
    LongBreak
}

struct PomodoroConfig
{
    float workMinutes = 25.0f;
    float shortBreakMinutes = 5.0f;
    float longBreakMinutes = 15.0f;
    int cyclesBeforeLongBreak = 4;
    bool enableSound = true;
    bool asciiMode = false;
    Language lang = Language.PT;
}

class Pomodoro
{
    private PomodoroConfig config;
    private PomodoroMode mode = PomodoroMode.Work;
    private int currentCycle = 1;
    private int completedCycles = 0;
    private bool paused = false;

    private Duration totalDuration;
    private Duration timeRemaining;
    private MonoTime lastUpdateTime;

    this(PomodoroConfig config)
    {
        this.config = config;
        this.mode = PomodoroMode.Work;
        this.currentCycle = 1;
        this.completedCycles = 0;
        this.paused = false;
        
        setupCurrentPhase();
        this.lastUpdateTime = MonoTime.currTime;
    }

    private void setupCurrentPhase()
    {
        final switch (mode)
        {
            case PomodoroMode.Work:
                totalDuration = dur!"hnsecs"(cast(long)(config.workMinutes * 60_0000_000));
                break;
            case PomodoroMode.ShortBreak:
                totalDuration = dur!"hnsecs"(cast(long)(config.shortBreakMinutes * 60_0000_000));
                break;
            case PomodoroMode.LongBreak:
                totalDuration = dur!"hnsecs"(cast(long)(config.longBreakMinutes * 60_0000_000));
                break;
        }
        timeRemaining = totalDuration;
    }

    /// Atualiza o timer com base no tempo monotônico. Retorna true se a fase acabou agora.
    bool tick()
    {
        MonoTime now = MonoTime.currTime;
        Duration delta = now - lastUpdateTime;
        lastUpdateTime = now;

        if (paused) return false;

        if (timeRemaining > delta)
        {
            timeRemaining -= delta;
            return false;
        }
        else
        {
            timeRemaining = Duration.zero;
            return true;
        }
    }

    /// Avança para a próxima fase do ciclo
    void nextPhase()
    {
        final switch (mode)
        {
            case PomodoroMode.Work:
                completedCycles++;
                if (currentCycle >= config.cyclesBeforeLongBreak)
                {
                    mode = PomodoroMode.LongBreak;
                }
                else
                {
                    mode = PomodoroMode.ShortBreak;
                }
                break;

            case PomodoroMode.ShortBreak:
                currentCycle++;
                mode = PomodoroMode.Work;
                break;

            case PomodoroMode.LongBreak:
                currentCycle = 1;
                mode = PomodoroMode.Work;
                break;
        }

        setupCurrentPhase();
        lastUpdateTime = MonoTime.currTime;
    }

    /// Reinicia a fase atual
    void resetCurrent()
    {
        setupCurrentPhase();
        lastUpdateTime = MonoTime.currTime;
    }

    void togglePause()
    {
        paused = !paused;
        lastUpdateTime = MonoTime.currTime;
    }

    void addMinutes(int deltaMinutes)
    {
        Duration d = dur!"minutes"(deltaMinutes);
        if (deltaMinutes < 0 && timeRemaining <= dur!"minutes"(1))
        {
            // Se já resta menos de 1 minuto, limita ao mínimo de 10s
            timeRemaining = dur!"seconds"(10);
        }
        else if (deltaMinutes < 0 && timeRemaining + d < dur!"seconds"(10))
        {
            timeRemaining = dur!"seconds"(10);
        }
        else
        {
            timeRemaining += d;
            if (timeRemaining > totalDuration)
            {
                totalDuration = timeRemaining;
            }
        }
        lastUpdateTime = MonoTime.currTime;
    }

    // Getters
    PomodoroMode getMode() const { return mode; }
    int getCurrentCycle() const { return currentCycle; }
    int getCompletedCycles() const { return completedCycles; }
    int getMaxCycles() const { return config.cyclesBeforeLongBreak; }
    bool isPaused() const { return paused; }

    float getProgress() const
    {
        if (totalDuration == Duration.zero) return 1.0f;
        long totalHn = totalDuration.total!"hnsecs";
        long remHn = timeRemaining.total!"hnsecs";
        float p = 1.0f - (cast(float)remHn / cast(float)totalHn);
        if (p < 0.0f) return 0.0f;
        if (p > 1.0f) return 1.0f;
        return p;
    }

    long getRemainingSeconds() const
    {
        return timeRemaining.total!"seconds";
    }

    long getElapsedSeconds() const
    {
        return (totalDuration - timeRemaining).total!"seconds";
    }

    PomodoroConfig getConfig() const
    {
        return config;
    }
}
