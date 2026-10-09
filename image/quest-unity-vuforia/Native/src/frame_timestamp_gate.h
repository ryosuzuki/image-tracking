#pragma once
#include <cstdint>

// One gate per camera delivery session. Never resubmit a queued image or move
// capture time backwards; a new start creates a fresh gate.
class FrameTimestampGate {
public:
    bool accept(int64_t timestamp) {
        if (timestamp <= 0 || timestamp <= last_) return false;
        last_ = timestamp;
        return true;
    }
private:
    int64_t last_ = 0;
};
