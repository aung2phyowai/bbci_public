using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Threading.Tasks;

namespace iViewClient.Api
{

    // API Struct definition. See the manual for further description. 

    public enum ETDevice
    {
        NONE = 0,
        RED = 1,
        REDm = 2,
        HiSpeed = 3,
        MRI = 4,
        HED = 5,
        Custom = 7
    };

    public enum ETApplication
    {
        iViewX = 0,
        iViewXOEM = 1
    };

    public enum FilterType
    {
        Average = 0
    };

    public enum FilterAction
    {
        Query = 0,
        Set = 1
    };

    public enum CalibrationStatusEnum
    {
        calibrationUnknown = 0,
        calibrationInvalid = 1,
        calibrationValid = 2,
        calibrationInProgress = 3
    };

    public enum REDGeometryEnum
    {
        monitorIntegrated = 0,
        standalone = 1
    };

    public struct SystemInfoStruct
    {
        public int samplerate;
        public int iV_MajorVersion;
        public int iV_MinorVersion;
        public int iV_Buildnumber;
        public int API_MajorVersion;
        public int API_MinorVersion;
        public int API_Buildnumber;
        public ETDevice iV_ETSystem;
    };

    public struct CalibrationPointStruct
    {
        public int number;
        public int positionX;
        public int positionY;
    };


    public struct EyeDataStruct
    {
        public double gazeX;
        public double gazeY;
        public double diam;
        public double eyePositionX;
        public double eyePositionY;
        public double eyePositionZ;
    };


    public struct SampleStruct
    {
        public Int64 timestamp;
        public EyeDataStruct leftEye;
        public EyeDataStruct rightEye;
        public int planeNumber;
    };


    public struct EventStruct
    {
        public char eventType;
        public char eye;
        public Int64 startTime;
        public Int64 endTime;
        public Int64 duration;
        public double positionX;
        public double positionY;
    };

    public struct EyePositionStruct
    {
        public int validity;
        public double relativePositionX;
        public double relativePositionY;
        public double relativePositionZ;
        public double positionRatingX;
        public double positionRatingY;
        public double positionRatingZ;
    };

    public struct TrackingStatusStruct
    {
        public Int64 timestamp;
        public EyePositionStruct leftEye;
        public EyePositionStruct rightEye;
        public EyePositionStruct total;
    };

    public struct AccuracyStruct
    {
        public double deviationXLeft;
        public double deviationYLeft;
        public double deviationXRight;
        public double deviationYRight;
    };

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct CalibrationStruct
    {
        public int method;
        public int visualization;
        public int displayDevice;
        public int speed;
        public int autoAccept;
        public int foregroundColor;
        public int backgroundColor;
        public int targetShape;
        public int targetSize;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string targetFilename;
    };

    public struct REDGeometryStruct
    {
        public REDGeometryEnum redGeometry;
        public int monitorSize;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string setupName;
        public int stimX;
        public int stimY;
        public int stimHeightOverFloor;
        public int redHeightOverFloor;
        public int redStimDist;
        public int redInclAngle;
        public int redStimDistHeight;
        public int redStimDistDepth;
    };

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct ImageStruct
    {
        public int imageHeight;
        public int imageWidth;
        public int imageSize;
        public IntPtr imageBuffer;
    };

    public struct DateStruct
    {
        public int day;
        public int month;
        public int year;
    };

    public struct AOIRectangleStruct
    {
        public int x1;
        public int x2;
        public int y1;
        public int y2;
    };

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Ansi)]
    public struct AOIStruct
    {
        public int enabled;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string aoiName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string aoiGroup;
        public AOIRectangleStruct position;
        public int fixationHit;
        public int outputValue;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string outputMessage;
        public char eye;
    };
}
