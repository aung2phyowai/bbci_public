using System;
using System.Text;
using iViewClient.Api;

namespace iViewClient
{
    internal class Client
    {
        private readonly IDllWrapper _api = ApiFactory.Create();

        private readonly string _sendAddress;
        private readonly int _sendPort;
        private readonly string _receiveAddress;
        private readonly int _receivePort;

        private readonly SampleStructToGazeSampleConverter _converter = new SampleStructToGazeSampleConverter();

        public Client(string sendAddress, int sendPort, string receiveAddress, int receivePort)
        {
            _sendAddress = sendAddress;
            _sendPort = sendPort;
            _receiveAddress = receiveAddress;
            _receivePort = receivePort;
        }

        public void Connect()
        {
            var sendIp = new StringBuilder(_sendAddress);
            var receiveIp = new StringBuilder(_receiveAddress);

            var result = _api.iV_Connect(sendIp, _sendPort, receiveIp, _receivePort);
            assert(result);
        }

        public long GetTimestamp()
        {
            long timestamp = 0;
            var result = _api.iV_GetCurrentTimestamp(ref timestamp);

            assert(result);
            return timestamp;
        }

        public GazeSample GetSample()
        {
            var sampleStruct = new SampleStruct();

            var result = _api.iV_GetSample(ref sampleStruct);
            assert(result);

            var gazeSample = _converter.Convert(sampleStruct);

            return gazeSample;
        }

        public void Disconnect()
        {
            var result = _api.iV_Disconnect();
            assert(result);
        }

        // Store references sending callback to unmanaged code
        private event IViewSampleCallback _callbackPlaceHolder;

        public void RegisterCallback(Action<GazeSample> callback)
        {
            var callbackAdapter = new SampleStructToGazeSampleCallbackAdapter(callback, _converter);
            var multicastDelegate = new IViewSampleCallback(callbackAdapter.Callback);
            _callbackPlaceHolder += multicastDelegate;

            _api.iV_SetSampleCallback(multicastDelegate);
        }

        private void assert(int code)
        {
            if (code != 1)
            {
                throw new iViewException(code);
            }
        }
    }
}
