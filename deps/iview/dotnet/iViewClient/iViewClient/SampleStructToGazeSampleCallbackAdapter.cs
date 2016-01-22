using iViewClient.Api;
using System;

namespace iViewClient
{
    internal class SampleStructToGazeSampleCallbackAdapter
    {
        private readonly SampleStructToGazeSampleConverter _converter;
        private readonly Action<GazeSample> _callback;

        public SampleStructToGazeSampleCallbackAdapter(Action<GazeSample> callback)
            : this(callback,  new SampleStructToGazeSampleConverter())
        {

        }

        public SampleStructToGazeSampleCallbackAdapter(Action<GazeSample> callback, SampleStructToGazeSampleConverter converter)
        {
            if (callback == null)
            {
                throw new ArgumentNullException("callback");
            }
            if(converter == null)
            {
                throw new ArgumentNullException("converter");
            }

            _callback = callback;
            _converter = converter;
        }

        public void Callback(SampleStruct sample)
        {
            var gazeSample = _converter.Convert(sample);
            _callback(gazeSample);
        }
    }
}
