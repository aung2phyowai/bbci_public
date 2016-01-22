using FluentAssertions;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using Xunit;

namespace iViewClient.Tests
{
    public class RecorderTests
    {
        private readonly RecorderParameters _parameters;

        public RecorderTests()
        {
            _parameters = new RecorderParameters();

            _parameters.SendAddress = "192.168.1.2";
            _parameters.SendPort = 4444;
            _parameters.ReceiveAddress = "192.168.1.1";
            _parameters.ReceivePort = 5555;
        }

        [Fact]
        public void Start_ShouldStartRecording()
        {
            var recorder = new Recorder(_parameters);

            recorder.Start();

            var allData = new List<double[][]>();

            for (int i = 0; i < 20; i++) {
                Thread.Sleep(1000);
                var data = recorder.GatherData();
                allData.Add(data);
            }

            recorder.Stop();

            var flattenedData = allData.SelectMany(x => x);
            var notNull = flattenedData.Where(x => x[1] != 0);
            notNull.Should().NotBeEmpty();
        }

        [Fact]
        public void GatherData_ShouldNotThrowAccessViolation()
        {
            var recorder = new Recorder(_parameters);

            recorder.Start();

            var allData = new List<double[][]>();

            for (int i = 0; i < 10000000; i++)
            {
                // Thread.Sleep(1000);
                var data = recorder.GatherData();
            }

            recorder.Stop();
        }

        [Fact]
        public void Start_ShouldCollectDataInOrder()
        {
            var recorder = new Recorder(_parameters);

            recorder.Start();

            Thread.Sleep(10000);

            var data = recorder.GatherData();

            recorder.Stop();

            data.Should().BeInAscendingOrder(x => x[0]);
        }

        [Fact]
        public void Start_ShouldThrowIfNoConnection()
        {
            var recorder = new Recorder(new RecorderParameters());

            Assert.Throws<iViewException>(() => recorder.Start());
        }
    }
}
