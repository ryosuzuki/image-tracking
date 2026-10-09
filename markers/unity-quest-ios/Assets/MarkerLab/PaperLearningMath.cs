using System;

// SI units and deterministic functions shared by rendering and executable model checks.
// Illustrative teaching models, not a physics-engine measurement of the real paper.
public static class PaperLearningMath
{
    public const double Gravity = 9.81;
    public static double Clamp(double v, double min, double max) { return Math.Max(min, Math.Min(max, v)); }
    public static double Graph(double x, double amplitude, double frequency, double phase) { return amplitude * Math.Sin(frequency * x + phase); }
    public static double GraphSlope(double x, double amplitude, double frequency, double phase) { return amplitude * frequency * Math.Cos(frequency * x + phase); }
    public static double RampAcceleration(double degrees, double friction)
    {
        double a = Clamp(degrees, 0, 85) * Math.PI / 180;
        return Gravity * Math.Max(0, Math.Sin(a) - Clamp(friction, 0, 1) * Math.Cos(a));
    }
    public static double RampTravel(double time, double degrees, double friction, double length)
    {
        return Clamp(.5 * RampAcceleration(degrees, friction) * time * time, 0, Math.Max(0, length));
    }
    public static double PendulumPeriod(double length) { return 2 * Math.PI * Math.Sqrt(Math.Max(.01, length) / Gravity); }
    public static double PendulumAngle(double time, double length, double amplitudeDegrees)
    {
        return amplitudeDegrees * Math.PI / 180 * Math.Cos(2 * Math.PI * time / PendulumPeriod(length));
    }
    public static double PendulumPotential(double length, double radians) { return Gravity * length * (1 - Math.Cos(radians)); }
    public static double OrbitPeriod(double radius) { return 2 * Math.PI * Math.Pow(Math.Max(.1, radius), 1.5); }
    // Topic order matches PaperApplication. Deterministic, quantized and independent of Unity.
    public static bool TryPaperDial(int topic, double radians, double translationMeters, out double primary, out double secondary, out double fold)
    {
        primary = secondary = 0; fold = -1;
        if (topic < 0 || topic > 7 || double.IsNaN(radians) || double.IsInfinity(radians) || double.IsNaN(translationMeters) || double.IsInfinity(translationMeters)) return false;
        double step = Math.PI / 60; // Three-degree bins suppress sub-bin pose jitter.
        double angle = Math.Round(Clamp(radians, -Math.PI / 2, Math.PI / 2) / step) * step;
        double t = Clamp(.5 + angle / Math.PI, 0, 1);
        double d = Math.Round(Clamp(translationMeters, 0, .2) / .002) * .002 / .2; // Two-mm translation bins, 20-cm range.
        switch (topic)
        {
            case 0: primary = .5 + .9 * t; secondary = 45 * d; break; // Solar radius/inclination.
            case 1: primary = 1; secondary = d; fold = t; break; // Geometry unfolds + moves slice.
            case 2: primary = .1 + 1.9 * t; secondary = .5 + 3.5 * d; break; // Function amplitude/frequency.
            case 3: primary = 5 + 60 * t; secondary = .8 * d; break; // Incline angle/friction.
            case 4: primary = .2 + t; secondary = 5 + 20 * d; break; // Pendulum length/amplitude.
            case 5: primary = 1 + 11 * d; secondary = 10 + 990 * t; break; // Circuit voltage/resistance.
            case 6: primary = -180 + 360 * t; secondary = .25 + 1.75 * d; break; // Vector angle/magnitude.
            case 7: primary = t; secondary = Math.Round(8 * d); break; // Binomial probability/outcome.
        }
        return true;
    }
    public static double Dot2D(double ax, double ay, double bx, double by) { return ax * bx + ay * by; }
    public static double ProjectionScalar(double bx, double by, double ax, double ay)
    {
        double length = Math.Sqrt(ax * ax + ay * ay);
        if (length <= 1e-12) throw new ArgumentOutOfRangeException("projection axis");
        return Dot2D(ax, ay, bx, by) / length;
    }
    public static void Projection2D(double bx, double by, double ax, double ay, out double x, out double y)
    {
        double squared = ax * ax + ay * ay;
        if (squared <= 1e-24) throw new ArgumentOutOfRangeException("projection axis");
        double coefficient = Dot2D(ax, ay, bx, by) / squared; x = coefficient * ax; y = coefficient * ay;
    }
    public static double BinomialPMF(int n, int k, double p)
    {
        if (n < 0 || n > 64 || double.IsNaN(p) || double.IsInfinity(p) || p < 0 || p > 1) throw new ArgumentOutOfRangeException("binomial parameters");
        if (k < 0 || k > n) return 0;
        if (p == 0) return k == 0 ? 1 : 0;
        if (p == 1) return k == n ? 1 : 0;
        double choose = 1; int r = Math.Min(k, n - k);
        for (int i = 1; i <= r; i++) choose *= (n - r + i) / (double)i;
        return choose * Math.Pow(p, k) * Math.Pow(1 - p, n - k);
    }
    public static double CircuitCurrent(double voltage, double resistance, bool closed)
    {
        if (resistance <= 0 || double.IsNaN(resistance) || double.IsInfinity(resistance)) throw new ArgumentOutOfRangeException("resistance");
        return closed ? voltage / resistance : 0;
    }
    public static double CircuitPower(double voltage, double resistance, bool closed) { return voltage * CircuitCurrent(voltage, resistance, closed); }
    public static double CubeSectionArea(double edge, double fraction) { return fraction >= 0 && fraction <= 1 ? edge * edge : 0; }
    public static double CubeVolume(double edge) { return edge * edge * edge; }
}
