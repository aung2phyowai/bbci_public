using System.Collections.Generic;
using System.Linq;

namespace iViewClient
{
    internal class Storage
    {
        private const int ExpectedBufferSize = 256;

        private List<GazeSample> _samples = new List<GazeSample>(ExpectedBufferSize);
        private readonly object _lock = new object();

        public void Store(GazeSample sample)
        {
            lock (_lock)
            {
                _samples.Add(sample);
            }
        }

        public IEnumerable<GazeSample> GatherData()
        {
            lock (_lock)
            {
                var samples = _samples;
                var lastSample = samples.Last();

                _samples = new List<GazeSample>(ExpectedBufferSize) { lastSample };

                return samples;
            }
        }

        public void Clear()
        {
            lock (_lock)
            {
                _samples.Clear();
            }
        }
    }
}
