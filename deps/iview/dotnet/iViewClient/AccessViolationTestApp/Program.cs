using iViewClient;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace AccessViolationTestApp
{
    class Program
    {
        static void Main(string[] args)
        {
            var parameters = new RecorderParameters();

            parameters.SendAddress = "192.168.1.2";
            parameters.SendPort = 4444;
            parameters.ReceiveAddress = "192.168.1.1";
            parameters.ReceivePort = 5555;

            var recorder = new Recorder(parameters);

            recorder.Start();

            var allData = new List<double[][]>();

            for (int i = 0; i < 10000000; i++)
            {
                // Thread.Sleep(1000);
                var data = recorder.GatherData();
            }

            recorder.Stop();
        }
    }
}
