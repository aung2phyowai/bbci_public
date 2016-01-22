using System.Collections.Generic;
using System.Linq;
using System.Runtime;

namespace iViewClient
{
    public class Recorder
    {
        private readonly Client _client;
        private readonly Storage _storage = new Storage();

        public Recorder(RecorderParameters recorderParameters)
        {
            _client = new Client(recorderParameters.SendAddress, recorderParameters.SendPort, recorderParameters.ReceiveAddress, recorderParameters.ReceivePort);
        }

        public void Start()
        {
            _client.Connect();
            storeSingleSample();
            _client.RegisterCallback(_storage.Store);
        }

        private void storeSingleSample()
        {
            GazeSample sample;

            try
            {
                sample = _client.GetSample();
            }
            catch (iViewException ex)
            {
                if (ex.Code == 2)
                {
                    long timestamp = _client.GetTimestamp();
                    sample = new GazeSample { Timestamp = timestamp };
                }
                else
                {
                    throw;
                }
            }

            _storage.Store(sample);
        }

        public void Stop()
        {
            _client.Disconnect();
            _storage.Clear();
        }

        public double[][] GatherData()
        {
            IEnumerable<GazeSample> samples = _storage.GatherData();
            IEnumerable<double[]> rawSamples = samples.Select(x => 
                new[] {
                    x.Timestamp,
                    x.LeftEyeGazeX,
                    x.LeftEyeGazeY,
                    x.LeftEyeDiameter,
                    x.RightEyeGazeX,
                    x.RightEyeGazeY,
                    x.RightEyeDiameter
                }
            );
            double[][] sampleMatrix = rawSamples.ToArray();

            return sampleMatrix;
        }
    }
}