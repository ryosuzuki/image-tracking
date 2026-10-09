#include "frame_timestamp_gate.h"
#include <cassert>

int main() {
    FrameTimestampGate session;
    assert(!session.accept(0));
    assert(!session.accept(-1));
    assert(session.accept(100));
    // Stalled producer: repeated reads of the same queued frame are rejected.
    for (int i = 0; i < 60; ++i) assert(!session.accept(100));
    assert(!session.accept(99));
    assert(session.accept(101));
    assert(session.accept(INT64_MAX));
    assert(!session.accept(INT64_MAX));
    // A camera restart has independent state, not a process-global watermark.
    FrameTimestampGate restarted;
    assert(restarted.accept(100));
    assert(!restarted.accept(100));
}
