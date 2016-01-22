namespace iViewClient
{
    public struct GazeSample
    {
        public long Timestamp { get; set; }
        public double LeftEyeGazeY { get; set; }
        public double LeftEyeGazeX { get; set; }
        public double LeftEyeDiameter { get; set; }
        public double RightEyeGazeX { get; set; }
        public double RightEyeGazeY { get; set; }
        public double RightEyeDiameter { get; set; }
    }
}
