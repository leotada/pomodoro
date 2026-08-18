module sound;

import core.thread : Thread;
import std.math : sin, exp, PI, round;
import std.process : spawnProcess, wait, ProcessPipes, Redirect;
import std.file : write, exists;
import std.string : toStringz;
import core.sys.posix.unistd : getpid, unlink;
import std.conv : to;

enum SoundType
{
    WorkFinished,    // Chime zen arpejado relaxante
    BreakFinished,   // Sino suave de retorno ao foco
    Tick             // Toque sutil de madeira
}

/// Gera cabeçalho WAV de 44 bytes para dados PCM 16-bit Stereo (2 canais)
ubyte[] createStereoWav(uint sampleRate, float[] left, float[] right)
{
    uint numFrames = cast(uint)left.length;
    uint numChannels = 2;
    uint bitsPerSample = 16;
    uint byteRate = sampleRate * numChannels * (bitsPerSample / 8);
    uint blockAlign = numChannels * (bitsPerSample / 8);
    uint dataSize = numFrames * blockAlign;
    uint chunkSize = 36 + dataSize;

    ubyte[] wav = new ubyte[44 + dataSize];

    // RIFF Chunk
    wav[0..4] = cast(ubyte[])"RIFF";
    wav[4..8] = [cast(ubyte)(chunkSize & 0xFF), cast(ubyte)((chunkSize >> 8) & 0xFF),
                 cast(ubyte)((chunkSize >> 16) & 0xFF), cast(ubyte)((chunkSize >> 24) & 0xFF)];
    wav[8..12] = cast(ubyte[])"WAVE";

    // "fmt " subchunk
    wav[12..16] = cast(ubyte[])"fmt ";
    wav[16..20] = [16, 0, 0, 0];    // Subchunk1Size = 16 para PCM
    wav[20..22] = [1, 0];           // AudioFormat = 1 (PCM)
    wav[22..24] = [2, 0];           // NumChannels = 2 (Stereo)
    wav[24..28] = [cast(ubyte)(sampleRate & 0xFF), cast(ubyte)((sampleRate >> 8) & 0xFF),
                   cast(ubyte)((sampleRate >> 16) & 0xFF), cast(ubyte)((sampleRate >> 24) & 0xFF)];
    wav[28..32] = [cast(ubyte)(byteRate & 0xFF), cast(ubyte)((byteRate >> 8) & 0xFF),
                   cast(ubyte)((byteRate >> 16) & 0xFF), cast(ubyte)((byteRate >> 24) & 0xFF)];
    wav[32..34] = [cast(ubyte)(blockAlign & 0xFF), cast(ubyte)((blockAlign >> 8) & 0xFF)];
    wav[34..36] = [cast(ubyte)(bitsPerSample & 0xFF), cast(ubyte)((bitsPerSample >> 8) & 0xFF)];

    // "data" subchunk
    wav[36..40] = cast(ubyte[])"data";
    wav[40..44] = [cast(ubyte)(dataSize & 0xFF), cast(ubyte)((dataSize >> 8) & 0xFF),
                   cast(ubyte)((dataSize >> 16) & 0xFF), cast(ubyte)((dataSize >> 24) & 0xFF)];

    size_t idx = 44;
    foreach (i; 0 .. numFrames)
    {
        float l = left[i];
        float r = right[i];

        if (l > 1.0f) l = 1.0f;
        if (l < -1.0f) l = -1.0f;
        if (r > 1.0f) r = 1.0f;
        if (r < -1.0f) r = -1.0f;

        short sL = cast(short)round(l * 32760.0f);
        short sR = cast(short)round(r * 32760.0f);

        wav[idx]     = cast(ubyte)(sL & 0xFF);
        wav[idx + 1] = cast(ubyte)((sL >> 8) & 0xFF);
        wav[idx + 2] = cast(ubyte)(sR & 0xFF);
        wav[idx + 3] = cast(ubyte)((sR >> 8) & 0xFF);
        idx += 4;
    }

    return wav;
}

/// Adiciona um tom harmônico de sino acústico/chime com distribuição estéreo
void addChimeTone(float[] left, float[] right, uint sampleRate, float startTime, float duration, float freq, float pan = 0.5f, float volume = 0.6f)
{
    uint startIdx = cast(uint)(startTime * sampleRate);
    uint totalSamples = cast(uint)(duration * sampleRate);

    // Harmônicos rústicos de sino de vento / tigela tibetana
    static struct Partial { float ratio; float amp; float decayRate; }
    static immutable Partial[4] partials = [
        Partial(1.00f, 1.00f, 1.8f),  // Fundamental
        Partial(2.76f, 0.35f, 3.2f),  // Primeiro harmônico de campânula
        Partial(5.40f, 0.15f, 5.0f),  // Segundo harmônico
        Partial(8.93f, 0.08f, 7.5f)   // Brilho suave
    ];

    float panLeft = 1.0f - pan;
    float panRight = pan;

    foreach (i; 0 .. totalSamples)
    {
        uint idx = startIdx + i;
        if (idx >= left.length) break;

        float t = cast(float)i / sampleRate;
        float sample = 0.0f;

        // Attack suave (4ms) para evitar estalos de início
        float attack = (t < 0.004f) ? (t / 0.004f) : 1.0f;

        foreach (p; partials)
        {
            float f = freq * p.ratio;
            float decay = exp(-t * p.decayRate);
            sample += p.amp * sin(2.0f * PI * f * t) * decay;
        }

        float finalSample = sample * volume * attack;
        left[idx]  += finalSample * panLeft;
        right[idx] += finalSample * panRight;
    }
}

/// Normaliza os canais de áudio para volume ótimo e limpo (90% do máximo)
void normalizeAudio(float[] left, float[] right, float targetPeak = 0.88f)
{
    float maxAmp = 0.0001f;
    foreach (s; left)
    {
        float a = s >= 0 ? s : -s;
        if (a > maxAmp) maxAmp = a;
    }
    foreach (s; right)
    {
        float a = s >= 0 ? s : -s;
        if (a > maxAmp) maxAmp = a;
    }

    if (maxAmp > 0.001f)
    {
        float scale = targetPeak / maxAmp;
        foreach (i; 0 .. left.length)
        {
            left[i] *= scale;
            right[i] *= scale;
        }
    }
}

/// Gera o buffer de áudio WAV para o som solicitado
ubyte[] generateProceduralSound(SoundType type)
{
    enum uint sampleRate = 44100;
    float duration;
    float[] left;
    float[] right;

    final switch (type)
    {
        case SoundType.WorkFinished:
            // Acorde Zen Relaxante Arpejado (Dó Maior / Mi Pentatônica com espacialização estéreo)
            // C5 (523Hz) -> E5 (659Hz) -> G5 (784Hz) -> B5 (988Hz) -> C6 (1047Hz)
            duration = 3.2f;
            size_t n = cast(size_t)(duration * sampleRate);
            left = new float[n];
            right = new float[n];
            left[] = 0.0f;
            right[] = 0.0f;

            addChimeTone(left, right, sampleRate, 0.00f, 2.8f, 523.25f, 0.40f, 0.70f); // C5
            addChimeTone(left, right, sampleRate, 0.18f, 2.7f, 659.25f, 0.60f, 0.70f); // E5
            addChimeTone(left, right, sampleRate, 0.36f, 2.6f, 783.99f, 0.35f, 0.70f); // G5
            addChimeTone(left, right, sampleRate, 0.54f, 2.5f, 987.77f, 0.65f, 0.75f); // B5
            addChimeTone(left, right, sampleRate, 0.72f, 2.6f, 1046.50f, 0.50f, 0.80f); // C6
            break;

        case SoundType.BreakFinished:
            // Sino duplo calmo e reconfortante de retorno ao foco: Lá4 (440Hz) -> Mi5 (659Hz)
            duration = 2.6f;
            size_t n = cast(size_t)(duration * sampleRate);
            left = new float[n];
            right = new float[n];
            left[] = 0.0f;
            right[] = 0.0f;

            addChimeTone(left, right, sampleRate, 0.00f, 2.4f, 440.00f, 0.45f, 0.75f); // A4
            addChimeTone(left, right, sampleRate, 0.25f, 2.3f, 659.25f, 0.55f, 0.80f); // E5
            break;

        case SoundType.Tick:
            // Toque sutil e rápido de madeira (35ms)
            duration = 0.05f;
            size_t n = cast(size_t)(duration * sampleRate);
            left = new float[n];
            right = new float[n];
            left[] = 0.0f;
            right[] = 0.0f;

            addChimeTone(left, right, sampleRate, 0.00f, 0.04f, 850.0f, 0.50f, 0.40f);
            break;
    }

    normalizeAudio(left, right, 0.88f);
    return createStereoWav(sampleRate, left, right);
}

/// Gerenciador de Áudio Procedural
class SoundEngine
{
    private bool enabled = true;

    this(bool enableSound = true)
    {
        this.enabled = enableSound;
    }

    void setEnabled(bool enabled)
    {
        this.enabled = enabled;
    }

    bool isEnabled() const
    {
        return this.enabled;
    }

    void toggle()
    {
        this.enabled = !this.enabled;
    }

    /// Toca um som de forma assíncrona em uma thread secundária sem travar a UI
    void play(SoundType type)
    {
        if (!enabled) return;

        auto worker = new Thread({
            try
            {
                ubyte[] wavBytes = generateProceduralSound(type);
                playWavBytes(wavBytes);
            }
            catch (Exception)
            {
                // Fallback silencioso / não trava execução
            }
        });
        worker.isDaemon = true;
        worker.start();
    }

    /// Toca sincronicamente (usado para testes do alarme)
    void playSync(SoundType type)
    {
        if (!enabled) return;
        ubyte[] wavBytes = generateProceduralSound(type);
        playWavBytes(wavBytes);
    }

    private static void playWavBytes(ubyte[] wavBytes)
    {
        // Salva na memória RAM (/dev/shm) para leitura instantânea e sem desgaste de disco
        string baseDir = exists("/dev/shm") ? "/dev/shm" : "/tmp";
        string tmpFile = baseDir ~ "/pomodoro_chime_" ~ to!string(getpid()) ~ "_" ~ to!string(Thread.getThis().toHash()) ~ ".wav";
        
        try
        {
            write(tmpFile, wavBytes);
        }
        catch (Exception)
        {
            return;
        }

        scope(exit)
        {
            unlink(tmpFile.toStringz);
        }

        // 1. Tenta PipeWire pw-play com o arquivo em memória RAM
        try
        {
            auto pid = spawnProcess(["pw-play", tmpFile]);
            int status = wait(pid);
            if (status == 0) return;
        }
        catch (Exception) {}

        // 2. Tenta PulseAudio paplay
        try
        {
            auto pid = spawnProcess(["paplay", tmpFile]);
            int status = wait(pid);
            if (status == 0) return;
        }
        catch (Exception) {}

        // 3. Tenta ffplay (modo silencioso de áudio)
        try
        {
            auto pid = spawnProcess(["ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet", tmpFile]);
            int status = wait(pid);
            if (status == 0) return;
        }
        catch (Exception) {}

        // Fallback para campainha de terminal caso nenhum servidor de áudio responda
        import std.stdio : write, stdout;
        write("\a");
        stdout.flush();
    }
}
