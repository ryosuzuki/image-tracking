#if PAPER_LEARNING_TEST
using System;
public static class PaperLearningModelChecks
{
    static int count;
    static void Check(bool condition, string name) { count++; if (!condition) throw new Exception(name); }
    static void Near(double got, double expected, double tolerance, string name) { Check(Math.Abs(got - expected) <= tolerance, name + ": " + got + " != " + expected); }
    public static void Main()
    {
        Near(PaperLearningMath.Graph(0, 2, 3, 0), 0, 1e-12, "graph origin");
        Near(PaperLearningMath.Graph(Math.PI / 4, 2, 2, 0), 2, 1e-12, "graph peak and amplitude");
        foreach (double x in new[] { -2.8, -.9, .1, 1.2, 2.9 })
        foreach (double a in new[] { .2, 1.0, 1.9 })
        foreach (double k in new[] { .5, 1.0, 3.7 })
        {
            double step = 1e-6;
            double derivative = (PaperLearningMath.Graph(x + step, a, k, 0) - PaperLearningMath.Graph(x - step, a, k, 0)) / (2 * step);
            Near(PaperLearningMath.GraphSlope(x, a, k, 0), derivative, 1e-7, "analytic graph tangent vs central difference");
        }
        Near(PaperLearningMath.RampAcceleration(0, 0), 0, 1e-12, "horizontal rest");
        Near(PaperLearningMath.RampAcceleration(30, 0), 4.905, 1e-10, "frictionless thirty-degree incline");
        Near(PaperLearningMath.RampAcceleration(30, Math.Tan(Math.PI / 6)), 0, 1e-10, "friction threshold");
        Near(PaperLearningMath.RampAcceleration(30, .8), 0, 1e-12, "no backward acceleration above threshold");
        Near(PaperLearningMath.RampTravel(0, 30, 0, 1), 0, 1e-12, "ramp starts at rest");
        Near(PaperLearningMath.RampTravel(100, 30, 0, 1), 1, 1e-12, "finite ramp endpoint");
        Near(PaperLearningMath.RampTravel(100, 5, .8, 1), 0, 1e-12, "static block with excessive friction");
        Near(PaperLearningMath.PendulumPeriod(1), 2.006066680710647, 1e-10, "one-metre pendulum period");
        Near(PaperLearningMath.PendulumPeriod(.8) / PaperLearningMath.PendulumPeriod(.2), 2, 1e-12, "period square-root scaling");
        Near(PaperLearningMath.PendulumAngle(PaperLearningMath.PendulumPeriod(.6) / 4, .6, 20), 0, 1e-12, "quarter-period equilibrium crossing");
        Near(PaperLearningMath.PendulumPotential(.6, 0), 0, 1e-12, "potential reference at bottom");
        Near(PaperLearningMath.PendulumPotential(.6, .2), PaperLearningMath.PendulumPotential(.6, -.2), 1e-12, "potential angle symmetry");
        Near(PaperLearningMath.OrbitPeriod(4) / PaperLearningMath.OrbitPeriod(1), 8, 1e-12, "Kepler period radius law");
        Near(PaperLearningMath.CubeVolume(.03) * 1e6, 27, 1e-10, "three-cm cube volume");
        foreach (double height in new[] { 0.0, .25, .5, .75, 1.0 }) Near(PaperLearningMath.CubeSectionArea(.03, height) * 1e4, 9, 1e-10, "parallel section area constant");
        Near(PaperLearningMath.CubeSectionArea(.03, 1.1), 0, 0, "section outside cube empty");
        Near(PaperLearningMath.CircuitCurrent(5, 100, true), .05, 1e-12, "five-volt hundred-ohm current");
        Near(PaperLearningMath.CircuitPower(5, 100, true), .25, 1e-12, "Ohm resistor power");
        Near(PaperLearningMath.CircuitCurrent(12, 10, false), 0, 0, "open switch current zero");
        Near(PaperLearningMath.CircuitPower(12, 10, false), 0, 0, "open switch power zero");
        Near(PaperLearningMath.CircuitCurrent(10, 100, true), 2 * PaperLearningMath.CircuitCurrent(5, 100, true), 1e-12, "current linear voltage law");
        Near(PaperLearningMath.CircuitPower(10, 100, true), 4 * PaperLearningMath.CircuitPower(5, 100, true), 1e-12, "power quadratic voltage law");
        Near(PaperLearningMath.CircuitPower(5, 100, true), Math.Pow(PaperLearningMath.CircuitCurrent(5, 100, true), 2) * 100, 1e-12, "independent I squared R power identity");
        bool invalidResistance = false; try { PaperLearningMath.CircuitCurrent(5, 0, true); } catch (ArgumentOutOfRangeException) { invalidResistance = true; }
        Check(invalidResistance, "zero resistance rejected");
        Near(PaperLearningMath.Dot2D(1, 0, -2, 3), -2, 0, "signed negative dot product");
        Near(PaperLearningMath.ProjectionScalar(-2, 3, 1, 0), -2, 0, "negative projection direction");
        Near(PaperLearningMath.ProjectionScalar(0, 4, 1, 0), 0, 0, "orthogonal projection zero");
        double px, py; PaperLearningMath.Projection2D(-2, 7, 3, 4, out px, out py);
        Near(PaperLearningMath.Dot2D(-2 - px, 7 - py, 3, 4), 0, 1e-12, "projection residual orthogonal to axis");
        Near(px * 4 - py * 3, 0, 1e-12, "projection parallel to axis");
        bool invalidAxis = false; try { PaperLearningMath.ProjectionScalar(1, 2, 0, 0); } catch (ArgumentOutOfRangeException) { invalidAxis = true; }
        Check(invalidAxis, "zero projection axis rejected");
        foreach (double p in new[] { 0.0, .01, .25, .5, .8, .99, 1.0 }) {
            double totalProbability = 0, firstMoment = 0, secondMoment = 0;
            for (int k = 0; k <= 8; k++) { double probability = PaperLearningMath.BinomialPMF(8, k, p); Check(probability >= 0 && probability <= 1, "PMF nonnegative bounded"); totalProbability += probability; firstMoment += k * probability; secondMoment += k * k * probability; }
            Near(totalProbability, 1, 1e-12, "PMF normalized");
            Near(firstMoment, 8 * p, 1e-12, "distribution mean independently summed");
            Near(secondMoment - firstMoment * firstMoment, 8 * p * (1 - p), 1e-12, "distribution variance independently summed");
        }
        for (int k = 1; k <= 8; k++) Near(PaperLearningMath.BinomialPMF(8, k, 0), 0, 0, "p0 impossible outcome exactly zero");
        for (int k = 0; k < 8; k++) Near(PaperLearningMath.BinomialPMF(8, k, 1), 0, 0, "p1 impossible outcome exactly zero");
        Near(PaperLearningMath.BinomialPMF(8, 4, .5), 70 / 256.0, 0, "eight-trial central probability");
        Near(PaperLearningMath.BinomialPMF(0, 0, .3), 1, 0, "zero-trial degenerate distribution");
        for (int topic = 0; topic < 8; topic++) {
            double a, b, fold, sameA, sameB, sameFold;
            Check(PaperLearningMath.TryPaperDial(topic, 0, 0, out a, out b, out fold), "paper dial topic supported");
            Check(PaperLearningMath.TryPaperDial(topic, .001, .0002, out sameA, out sameB, out sameFold), "sub-bin paper jitter accepted");
            Near(a, sameA, 0, "rotation jitter quantized"); Near(b, sameB, 0, "translation jitter quantized"); Near(fold, sameFold, 0, "fold jitter quantized");
            double upperA, upperB, upperFold, hugeA, hugeB, hugeFold;
            Check(PaperLearningMath.TryPaperDial(topic, Math.PI / 2, .2, out upperA, out upperB, out upperFold), "upper dial endpoint");
            Check(PaperLearningMath.TryPaperDial(topic, 1e200, 1e200, out hugeA, out hugeB, out hugeFold), "extreme finite dial input clipped");
            Near(upperA, hugeA, 1e-12, "extreme rotation clips"); Near(upperB, hugeB, 1e-12, "extreme translation clips"); Near(upperFold, hugeFold, 1e-12, "extreme fold clips");
            Check(!PaperLearningMath.TryPaperDial(topic, double.NaN, 0, out a, out b, out fold), "NaN rotation rejected");
            Check(!PaperLearningMath.TryPaperDial(topic, 0, double.PositiveInfinity, out a, out b, out fold), "infinite translation rejected");
        }
        double dialA, dialB, dialFold;
        PaperLearningMath.TryPaperDial(1, -Math.PI / 2, 0, out dialA, out dialB, out dialFold); Near(dialFold, 0, 0, "paper folds cube closed");
        PaperLearningMath.TryPaperDial(1, Math.PI / 2, .2, out dialA, out dialB, out dialFold); Near(dialFold, 1, 0, "paper unfolds cube completely");
        PaperLearningMath.TryPaperDial(7, -Math.PI / 2, 0, out dialA, out dialB, out dialFold); Near(dialA, 0, 0, "paper dial exact p0");
        PaperLearningMath.TryPaperDial(7, Math.PI / 2, .2, out dialA, out dialB, out dialFold); Near(dialA, 1, 0, "paper dial exact p1");
        PaperLearningMath.TryPaperDial(5, Math.PI / 2, .2, out dialA, out dialB, out dialFold); Near(dialB, 1000, 1e-12, "paper rotation circuit resistance");
        Console.WriteLine("PASS " + count + " independent mathematical checks; implementation-only, not device evidence");
    }
}
#endif
