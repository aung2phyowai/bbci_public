using iViewClient.Api;

namespace iViewClient
{
    internal class SampleStructToGazeSampleConverter
    {
        public GazeSample Convert(SampleStruct sample)
        {
            var gazeSample = new GazeSample();

            gazeSample.Timestamp = sample.timestamp;
            gazeSample.LeftEyeGazeX = sample.leftEye.gazeX;
            gazeSample.LeftEyeGazeY = sample.leftEye.gazeY;
            gazeSample.LeftEyeDiameter = sample.leftEye.diam;
            gazeSample.RightEyeGazeX = sample.rightEye.gazeX;
            gazeSample.RightEyeGazeY = sample.rightEye.gazeY;
            gazeSample.RightEyeDiameter = sample.rightEye.diam;

            return gazeSample;
        }
    }
}
