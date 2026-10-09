using System;
// Matches MRUK203 PassthroughCameraAccess.CalcSensorCropRegion. Raw-image row orientation
// and achieved stream geometry still require device acceptance; this is numeric calibration.
public static class MarkerCameraCalibration
{
    static bool Finite(double v) { return !double.IsNaN(v) && !double.IsInfinity(v); }
    public static double[] Intrinsics(double fx, double fy, double cx, double cy, int sensorWidth, int sensorHeight, int width, int height)
    {
        if (!Finite(fx) || !Finite(fy) || !Finite(cx) || !Finite(cy) || fx <= 0 || fy <= 0 || sensorWidth <= 0 || sensorHeight <= 0 || width <= 0 || height <= 0) throw new ArgumentOutOfRangeException("camera intrinsics");
        double resize = Math.Max(width / (double)sensorWidth, height / (double)sensorHeight);
        double cropWidth = width / resize, cropHeight = height / resize;
        double cropX = (sensorWidth - cropWidth) * .5, cropY = (sensorHeight - cropHeight) * .5;
        return new[] { fx * resize, fy * resize, (cx - cropX) * resize, (cy - cropY) * resize };
    }
    public static bool AcceptTimestamp(long epochMicroseconds, long xrTimeNanoseconds, long previousXrTimeNanoseconds, long minimumEpochMicroseconds)
    {
        return epochMicroseconds > 0 && xrTimeNanoseconds > 0 && xrTimeNanoseconds > previousXrTimeNanoseconds && epochMicroseconds >= minimumEpochMicroseconds;
    }
    public static bool ValidPose(double x, double y, double z, double qx, double qy, double qz, double qw)
    {
        if (!Finite(x) || !Finite(y) || !Finite(z) || !Finite(qx) || !Finite(qy) || !Finite(qz) || !Finite(qw)) return false;
        double normSquared = qx * qx + qy * qy + qz * qz + qw * qw;
        return normSquared >= .98 && normSquared <= 1.02;
    }
}
