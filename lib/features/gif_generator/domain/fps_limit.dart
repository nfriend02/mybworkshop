/// GIF generator never exceeds 29 frames per second.
int clampGifFps(int fps) => fps.clamp(1, 29);

int delayMsForFps(int fps) => (1000 / clampGifFps(fps)).round().clamp(20, 1000);
