/**
* @mainpage iViewX API Documentation
*
* The iView X SDK provides an interface for communication between 
* your application and iView X. It uses UDP over Ethernet to provide 
* maximum speed and minimum latency for data transfer. By using 
* iView X SDK the programmer does not have to take care about Ethernet 
* communication specific programming. The iView X SDK provides a large 
* set of functions to control SMI eye tracker's and retrieve data online. 
* It supports a growing number of programming languages and environments, 
* e.g. C/C++, .Net, Matlab, Visual Basic, E-Prime.
*
* Important note: To be able to exchange data between iView X and another 
* application with the iView X SDK an Ethernet connection has to be 
* established. Please consult according documentation on how to establish 
* an Ethernet connection between different computers (e.g. the iView X 
* user manual). Even when using iView X and the application on the same 
* PC an Ethernet connection has to be established. Normally this happens 
* via the so called localhost, 127.0.0.1. Please adjust IP address and 
* port settings in iView X and your application accordingly. 
*
* Important Note: This iView X SDK installer contains Windows 32bit DLLs. 
* Therefore, you can install and run the binaries on Windows 64bit OS, but 
* it is not possible to implement the binaries in Windows 64bit applications. 
*
* @author SMI GmbH
*/ 

/**
* @file iViewXAPI.h
*
* @brief The file contains the prototype declarations for all supported 
* functions and data structs the customer can use to interact with 
* SMI eye tracking devices. 
**/ 

 
#pragma once 


#ifndef CALLBACK
#define CALLBACK __stdcall
#endif

#define DLLExport __declspec(dllexport) 
#define DEPRECATED __declspec(deprecated)

/**
* @name ReturnValues 
* The ReturnValues list defines all possible return codes which can be returned 
* by the API functions. 
* @{
*/ 
#define RET_SUCCESS													1
#define RET_NO_VALID_DATA											2
#define RET_CALIBRATION_ABORTED										3
#define RET_SERVER_IS_RUNNING										4
#define RET_CALIBRATION_NOT_IN_PROGRESS								5
#define RET_WINDOW_IS_OPEN											11
#define RET_WINDOW_IS_CLOSED										12

#define ERR_COULD_NOT_CONNECT										100
#define ERR_NOT_CONNECTED											101
#define ERR_NOT_CALIBRATED											102
#define ERR_NOT_VALIDATED											103
#define ERR_EYETRACKING_APPLICATION_NOT_RUNNING						104
#define ERR_WRONG_COMMUNICATION_PARAMETER							105
#define ERR_WRONG_DEVICE											111
#define ERR_WRONG_PARAMETER											112
#define ERR_WRONG_CALIBRATION_METHOD								113
#define ERR_BIND_SOCKET												123
#define ERR_DELETE_SOCKET											124
#define ERR_NO_RESPONSE_FROM_IVIEWX									131
#define ERR_WRONG_IVIEWX_VERSION									133
#define ERR_ACCESS_TO_FILE											171
#define ERR_EMPTY_DATA_BUFFER										191	
#define ERR_RECORDING_DATA_BUFFER									192	
#define ERR_FULL_DATA_BUFFER										193	
#define ERR_IVIEWX_IS_NOT_READY										194	
#define ERR_PAUSED_DATA_BUFFER										195 
#define ERR_IVIEWX_NOT_FOUND										201	
#define ERR_CAMERA_NOT_FOUND										211
#define ERR_WRONG_CAMERA											212
#define ERR_WRONG_CAMERA_PORT										213
#define ERR_COULD_NOT_OPEN_PORT										220
#define ERR_COULD_NOT_CLOSE_PORT									221
#define ERR_AOI_ACCESS												222
#define ERR_FEATURE_NOT_LICENSED									250
#define ERR_INITIALIZATION											400
/** @} */


/**
* @name LogLevel
* With these defines handed over to the function @ref iV_SetLogger it is possible to 
* setup the internal logging status of the API as well as the content which will be logged. 
* Log levels can be combined (e.g. LOG_BUG | LOG_IV_COMMAND | LOG_ETCOM). 
* With @ref iV_Log it is possible to store additional messages in the internal 
* logfile. 
* @{
*/ 
#define LOG_LEVEL_BUG					1	
#define LOG_LEVEL_iV_FCT				2	
#define LOG_LEVEL_ALL_FCT				4	
#define LOG_LEVEL_IV_COMMAND			8	
#define LOG_LEVEL_RECV_IV_COMMAND		16	
/** @} */


/**
* @name EyeTrackingParameter 
* With ET_PARAM_ and function @ref iV_SetTrackingParameter it is possible 
* to change iView X and eyetracking-server tracking parameters, for example 
* pupil threshold and corneal reflex thresholds, eye image contours, and other 
* parameters. 
* 
* Important note: This function can strongly affect tracking stability of 
* your iView X and eyetracking-server system. Only experienced users should use 
* this function. 
* @{
*/
#define ET_PARAM_EYE_LEFT				0
#define ET_PARAM_EYE_RIGHT				1
#define ET_PARAM_EYE_BOTH				2
#define ET_PARAM_PUPIL_THRESHOLD		0
#define ET_PARAM_REFLEX_THRESHOLD		1
#define ET_PARAM_SHOW_AOI				2
#define ET_PARAM_SHOW_CONTOUR			3
#define ET_PARAM_SHOW_PUPIL				4
#define ET_PARAM_SHOW_REFLEX			5
#define ET_PARAM_DYNAMIC_THRESHOLD		6
#define ET_PARAM_PUPIL_AREA				11
#define ET_PARAM_PUPIL_PERIMETER		12
#define ET_PARAM_PUPIL_DENSITY			13
#define ET_PARAM_REFLEX_PERIMETER		14
#define ET_PARAM_REFLEX_PUPIL_DISTANCE	15
#define ET_PARAM_MONOCULAR				16
#define ET_PARAM_SMARTBINOCULAR			17
#define ET_PARAM_BINOCULAR				18
/** @} */


/** \addtogroup structs Data Types and Enumerations
 *  @{
 */
 

/**
* @enum ETDevice
*
* @brief The enumeration ETDevice can be used in connection with 
* @ref iV_GetSystemInfo to get information about which type of device is 
* connected to iView X or eyetracking-server. It is part of the @ref SystemInfoStruct.
*/
enum ETDevice 
{
	//! if no device is set up while running iView X application 
	NONE = 0, 

	//! iView X based remote eye tracking devices 
	RED = 1, 

	//! eyetracking-server based remote eye tracking devices 
	REDm = 2, 

	//! iView X based hi speed eye tracking devices 
	HiSpeed = 3, 

	//! iView X based MRI eye tracking devices 
	MRI = 4, 

	//! iView X based head mounted eye tracking devices 
	HED = 5, 

	//! iView X based custom devices like the mouse grabber 
	Custom = 7
};


/**
* @enum ETApplication
*
* @brief ETApplication can be used to start iView X or iView X OEM 
* (eyetracking-server) application dependent to the used eye tracking 
* device. Set this as a parameter in @ref iV_Start function. 
*/
enum ETApplication 
{
	//! for iView X based devices like RED, HiSpeed, MRI, HED
	iViewX = 0, 
	
	//! for RED-OEM based devices like RED-m or other customized RED-OEM devices
	iViewXOEM = 1
};


/**
* @enum FilterType
*
* @brief FilterType can be used to select the filter that is used
* with @ref iV_ConfigureFilter
*/
enum FilterType 
{
	//! left and right gaze data channels are averaged
	//! the type of the parameter data from @ref iV_ConfigureFilter has to be converted to int*
	//! The value of data can be [0;1] where 0 means averaging is disabled and 1 means averaging is enabled
	Average = 0 
};


/**
* @enum FilterAction
*
* @brief FilterType can be used to select the action that is performed
* when calling @ref iV_ConfigureFilter
*/
enum FilterAction 
{
	//! query the current filter status
	Query = 0, 
	
	//! configure filter parameters
	Set = 1
};


/**
* @enum CalibrationStatusEnum
*
* @brief This enum provides information about the eyetracking-server calibration status. If the 
* device is not calibrated the eyetracking-server won't deliver valid gaze data. Use the functions 
* @ref iV_GetCalibrationStatus to retrieve the calibration status and 
* @ref iV_Calibrate to perform a calibration. 
*/ 
enum CalibrationStatusEnum 
{
	//! calibration status is unknown (i.e. if the connection is not established) 
	calibrationUnknown = 0, 
	
	//! the device is not calibrated and will not deliver valid gaze data 
	calibrationInvalid = 1, 
	
	//! the device is calibrated and will deliver valid gaze data 
	calibrationValid = 2, 
	
	//! the device is currently performing a calibration 
	calibrationInProgress = 3 
};

/**
* @enum REDGeometryEnum
* 
* @brief uses to the define the content of @ref REDGeometryStruct
*/
enum REDGeometryEnum
{
	//! use monitor integrated mode
	monitorIntegrated = 0,

	//! use standalone mode
	standalone = 1
};

/**
* @struct SystemInfoStruct
*
* @brief This struct provides information about the iView X (eyetracking-server) version 
* and the API version in use. To update data in @ref SystemInfoStruct use the function 
* @ref iV_GetSystemInfo. 
*/ 
struct SystemInfoStruct
{
	//! sample rate of eye tracking device in use 
	int samplerate;					
	
	//! major version number of iView X (eyetracking-server) in use
	int iV_MajorVersion;			
	
	//! minor version number of iView X (eyetracking-server) in use 
	int iV_MinorVersion;			
	
	//! build number of iView X (eyetracking-server) in use
	int iV_Buildnumber;				
	
	//! major version number of iView X SDK in use 
	int API_MajorVersion;			
	
	//! minor version number of iView X SDK in use 
	int API_MinorVersion;			
	
	//! build number of iView X SDK in use
	int API_Buildnumber;			
	
	//! type of eye tracking device 
	enum ETDevice iV_ETDevice;		
};


/**
* @struct CalibrationPointStruct
*
* @brief This struct provides information about the position of calibration points. To 
* update information in @ref CalibrationPointStruct during a calibration or validation 
* use function @ref iV_GetCurrentCalibrationPoint. Before or after the calibration use 
* @ref iV_GetCalibrationPoint. 
*/ 
struct CalibrationPointStruct
{
	//! number of calibration point
	int number;							

	//! horizontal position of calibration point [pixel] 
	int positionX;						

	//! vertical position of calibration point [pixel] 
	int positionY;						
};


/**
* @struct EyeDataStruct
*
* @brief This struct provides numerical information about eye data. 
* @ref EyeDataStruct is part of @ref SampleStruct. To update information 
* in @ref SampleStruct use function @ref iV_GetSample or set the sample 
* callback with @ref iV_SetSampleCallback. 
*/ 
struct EyeDataStruct
{
	//! horizontal gaze position on screen [pixel] 
	double gazeX;					

	//! vertical gaze position on screen [pixel] 
	double gazeY;					

	//! pupil diameter [mm] 
	double diam;					

	//! horizontal eye position relative to camera [mm] 
	double eyePositionX;			

	//! vertical eye position relative to camera [mm] 
	double eyePositionY;			

	//! distance to camera [mm] 
	double eyePositionZ;			
};


/**
* @struct SampleStruct
*
* @brief This struct provides information about an eye data sample. 
* To update information in @ref SampleStruct use the function 
* @ref iV_GetSample or set the sample callback with @ref iV_SetSampleCallback. 
*/ 
struct SampleStruct
{
	//! timestamp of current gaze data sample [microseconds] 
	long long timestamp;				

	//! stores information of the left eye (see @ref EyeDataStruct for more information) 
	struct EyeDataStruct leftEye;				

	//! stores information of the right eye (see @ref EyeDataStruct for more information) 
	struct EyeDataStruct rightEye;				

	//! plane number of gaze data sample (only for HED HT) 
	int	planeNumber;					
};


/**
* @struct SampleStruct32
*
* @brief This struct provides information about a eye data samples. 
* To update information in @ref SampleStruct32 use the function 
* @ref iV_GetSample32. The difference to @ref SampleStruct is that 
* the timestamp will be stored in milliseconds instead of microseconds. 
*/ 
struct SampleStruct32
{
	//! timestamp of current gaze data sample [milliseconds] 
	double timestamp;					

	//! stores information of the left eye (see @ref EyeDataStruct for more information) 
	struct EyeDataStruct leftEye;				

	//! stores information of the right eye (see @ref EyeDataStruct for more information) 
	struct EyeDataStruct rightEye;				

	//! plane number of gaze data sample
	int	planeNumber;					
};


/**
* @struct EventStruct
*
* @brief This struct provides information about the last eye event that has 
* been calculated. 
* To update information in @ref EventStruct use function @ref iV_GetEvent or set 
* the event callback with with @ref iV_SetEventCallback. 
*/ 
struct EventStruct
{
	//! type of eye event, 'F' for fixation (only fixations are supported) 
	char eventType;						

	//! related eye, 'l' for left eye, 'r' for right eye 
	char eye;							

	//! start time of the event [microseconds] 
	long long startTime;				

	//! end time of the event [microseconds] 
	long long endTime;					

	//! duration of the event [microseconds] 
	long long duration;					

	//! horizontal position of the fixation event [pixel] 
	double positionX;					

	//! vertical position of the fixation event [pixel] 
	double positionY;					
};


/**
* @struct EventStruct32
*
* @brief This struct provides information about the last eye event that has 
* been calculated.
* The difference to @ref EventStruct is that the timestamp will be stored in 
* milliseconds instead of microseconds and the order of the components are different. 
* To update information in @ref EventStruct32 use function @ref iV_GetEvent32. 
*/ 
struct EventStruct32
{
	//! start time of the event [milliseconds] 
	double startTime;					

	//! end time of the event [milliseconds] 
	double endTime;						

	//! duration of the event [milliseconds] 
	double duration;					

	//! horizontal position of the fixation event [pixel] 
	double positionX;					

	//! vertical position of the fixation event [pixel] 
	double positionY;					

	//! type of eye event, 'F' for fixation (only fixations are supported) 
	char eventType;						

	//! related eye, 'l' for left eye, 'r' for right eye 
	char eye;							
};


/**
* @struct EyePositionStruct
*
* @brief This value represents the relative position of the eye in the tracking box. 
* The 0 is defined at the center position. The value +1 defines the upper/right/far 
* maximum while the value -1 the lower/left/near maximum. 
* The position rating is related to the tracking monitor and represents how critical 
* the tracking and the position is, related to the border of the tracking box. The 0 
* is defined as the best eye position to be tracked while the value +1 defines that 
* the eye is almost not being tracked due to extreme upper/right/far position. The 
* value -1 defines that the eye is almost not being tracked due to extreme 
* lower/left/near position. 
* If the eye isn't tracked at all the validity flag goes to 0 and all values for the 
* represented eye will be set to 0. 
*/ 
struct EyePositionStruct
{
	//! confidence of position and rating values [0; 1]
	int validity; 

	//! horizontal position [-1; +1] 
	double relativePositionX; 

	//! vertical position [-1; +1] 
	double relativePositionY; 

	//! depth/distance position [-1; +1] 
	double relativePositionZ; 

	//! horizontal rating [-1; +1] 
	double positionRatingX;

	//! vertical rating [-1; +1] 
	double positionRatingY;

	//! distance rating [-1; +1] 
	double positionRatingZ;
};


/**
* @struct TrackingStatusStruct
*
* @brief This struct provides information about the relative eye ball position 
* within the tracking box. The information will be provided for each eye individually 
* as well as for the geographical center between both eyes. To update information in 
* @ref TrackingStatusStruct use the function @ref iV_GetTrackingStatus. 
*/ 
struct TrackingStatusStruct 
{
	//! timestamp of current tracking status sample [microseconds] 
	long long timestamp; 

	//! stores information of the left eye (see EyePositionStruct for more information) 
	struct EyePositionStruct leftEye; 

	//! stores information of the right eye (see EyePositionStruct for more information) 
	struct EyePositionStruct rightEye; 

	//! stores information of the geometric average of both eyes (see EyePositionStruct for more information)  
	struct EyePositionStruct total; 
};


/**
* @struct AccuracyStruct
*
* @brief This struct provides information about the last validation. 
* Therefore a valid validation must be successfully completed before the AccuracyStruct can be 
* updated. To update information in @ref AccuracyStruct use function @ref iV_GetAccuracy. 
*/ 
struct AccuracyStruct
{
	//! horizontal calculated deviation for left eye [degree]
	double deviationLX;				

	//! vertical calculated deviation for left eye [degree]
	double deviationLY;				

	//! horizontal calculated deviation for right eye [degree]
	double deviationRX;				

	//! vertical calculated deviation for right eye [degree]
	double deviationRY;				
};


/**
* @struct CalibrationStruct
*
* @brief Use this struct to customize the calibration and validation behavior. 
* To set calibration parameters with @ref CalibrationStruct use function 
* @ref iV_SetupCalibration before a calibration or validation is started. 
*/ 
struct CalibrationStruct
{
	//! select calibration method (default: 5) 
	int method;	

	//! draw calibration/validation [0: no API visualization , 1: API visualization (default)] 
	int visualization;	

	//! set display device [0: primary device (default), 1: secondary device] 
	int displayDevice;	

	//! set calibration/validation speed [0: slow (default), 1: fast] 
	int speed;	

	//! set calibration/validation point acceptance [0: manual, 1: semi automatic (default), 2: full automatic] 
	int autoAccept;	

	//! set calibration/validation target brightness [0..255] (default: 250) 
	int foregroundBrightness;

	//! set calibration/validation background brightness [0..255] (default: 220) 
	int backgroundBrightness;

	//! set calibration/validation target shape [IMAGE = 0, CIRCLE1 = 1, CIRCLE2 = 2 (default), CROSS = 3] 
	int targetShape;

	//! set calibration/validation target size (default: 20 pixels) 
	int targetSize;	

	//! select custom calibration/validation target (only if targetShape = 0) 
	char targetFilename[256];
};


/**
* @struct REDGeometryStruct 
*
* @brief Use this struct to customize the RED and RED-m geometry. 
* See chapter @ref redgeometry in the iView X SDK Manual for details. 
* For setting up the RED or RED-m geometry parameters with 
* @ref REDGeometryStruct use function @ref iV_SetREDGeometry. 
*/ 
struct REDGeometryStruct
{
	//! defines which parameter is used.
	enum REDGeometryEnum redGeometry;

	//! monitor size [inch]
	//! can be set to 19 or 22
	//! used if @ref redGeometry is set to @ref monitorIntegrated only
	//! applicable for RED devices only
	int	monitorSize;

	//! name of the profile 
	//! used if @ref redGeometry is set to @ref standalone only
	//! applicable for RED and RED-m devices
	char setupName[256];

	//! horizontal stimulus calibration size [mm] 
	//! used if @ref redGeometry is set to @ref standalone only
	//! applicable for RED and RED-m devices
	int stimX;

	//! vertical stimulus calibration size [mm] 
	//! used if @ref redGeometry is set to @ref standalone only
	//! applicable for RED and RED-m devices
	int stimY;

	//! distance floor to stimulus screen [mm] 
	//! used if @ref redGeometry is set to @ref standalone only
	//! applicable for RED only
	int stimHeightOverFloor;

	//! distance floor to RED [mm] 
	//! used if @ref redGeometry is set to @ref standalone only
	//! applicable for RED only
	int redHeightOverFloor;

	//! distance RED to stimulus screen [mm] 
	//! used if @ref redGeometry is set to @ref standalone only
	//! applicable for RED only
	int redStimDist;

	//! RED or RED-m inclination angle [degree]
	//! used if @ref redGeometry is set to @ref standalone only
	//! applicable for RED and RED-m devices
	int redInclAngle;

	//! vertical distance RED-m to stimulus screen [mm]
	//! used if @ref redGeometry is set to @ref standalone only
	//! applicable for RED-m only
	int redStimDistHeight;

	//! horizontal distance RED-m to stimulus screen [mm]
	//! used if @ref redGeometry is set to @ref standalone only
	//! applicable for RED-m only
	int redStimDistDepth;
};


/**
* @struct ImageStruct
*
* @brief Use this struct to get raw eye image, raw scene video image, or 
* raw tracking monitor image. For receiving raw eye image (format: monochrome 8bpp) 
* use @ref iV_GetEyeImage, or set the eye image callback with @ref iV_SetEyeImageCallback. 
* For receiving raw scene video image (format: RGB 24bpp) use @ref iV_GetSceneVideo, 
* or set the scene video callback with @ref iV_SetSceneVideoCallback. For receiving 
* raw tracking monitor image (format: RGB 24bpp) use @ref iV_GetTrackingMonitor, or 
* set the tracking monitor callback with @ref iV_SetTrackingMonitorCallback. 
*/ 
struct ImageStruct
{
	//! vertical size of the image [pixel] 
	int imageHeight;

	//! horizontal size of the image [pixel] 
	int imageWidth;

	//! image data size [byte] 
	int imageSize;

	//! pointer to image data
	char* imageBuffer;
};


/**
* @struct DateStruct
*
* @brief Use this struct to get the license due date of the device. Use the 
* function @ref iV_GetLicenseDueDate to update information in @ref DateStruct. 
*/ 
struct DateStruct
{
	//! day of license expiration 
	int day;

	//! month of license expiration 
	int month;

	//! year of license expiration 
	int year;
};


/**
* @struct AOIRectangleStruct
*
* @brief Use this struct to customize the AOI position on screen. @ref AOIRectangleStruct 
* is a part of @ref AOIStruct and can be defined with @ref iV_DefineAOI. 	
*/ 
struct AOIRectangleStruct
{
	//! x-coordinate of left border of the AOI [pixel] 
	int x1;

	//! x-coordinate of right border of the AOI [pixel] 
	int x2;

	//! y-coordinate of upper border of the AOI [pixel] 
	int y1;

	//! y-coordinate of lower border of the AOI [pixel] 
	int y2;
};


/**
* @struct AOIStruct
*
* @brief Use this struct to customize trigger AOIs. To define AOIs on screen, trigger 
* parameter and trigger values use @ref iV_DefineAOIPort and @ref iV_DefineAOI functions. 			
*/ 
struct AOIStruct
{
	//! enable/disable trigger functionality [1: enabled, 0: disabled] 
	int enabled;

	//! name of AOI 
	char aoiName[256];

	//! group name of AOI 
	char aoiGroup[256];

	//! position of AOI 
	struct AOIRectangleStruct position;

	//! uses fixations or raw data as trigger  [1: fixation hit, 0: raw data hit]
	int fixationHit;

	//! TTL output value 
	int outputValue;

	//! message in idf data stream 
	char outputMessage[256];

	//! ['l', 'r']
	char eye;
};



/**
* @brief	calibration callback function type
*/
typedef int (CALLBACK *pDLLSetCalibrationPoint)(struct CalibrationPointStruct calibrationPoint); 


/**
* @brief	AOI hit callback function type
*/
typedef int (CALLBACK *pDLLSetAOIHit)(int digitalOutoutValue); 


/**
* @brief	sample callback function type
*/
typedef int (CALLBACK *pDLLSetSample)(struct SampleStruct rawDataSample);


/**
* @brief	event callback function type
*/
typedef int (CALLBACK *pDLLSetEvent)(struct EventStruct eventDataSample);

/**
* @brief	eye image callback function type
*/
typedef int (CALLBACK *pDLLSetEyeImage)(struct ImageStruct eyeImage);

/**
* @brief	scene image callback function type
*/
typedef int (CALLBACK *pDLLSetSceneVideo)(struct ImageStruct sceneVideo);

/**
* @brief	tracking monitor image callback function type
*/
typedef int (CALLBACK *pDLLSetTrackingMonitor)(struct ImageStruct trackingMonitor);


/** @}*/

/** \addtogroup functions Functions
 *  @{
 */

/**
* @brief	Aborts a calibration or validation if one is in progress. If the calibration or 
*			validation function is visualizing the calibration area the @ref iV_Calibrate or 
*			@ref iV_Validate function will return with RET_CALIBRATION_ABORTED. 
* 			See also @listcalibration
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_CALIBRATION_NOT_IN_PROGRESS					calibration or validation is not in progress
* @retval	ERR_NOT_CONNECTED								no connection established
**/ 
DLLExport int __stdcall iV_AbortCalibration();


/**
* @brief	Accepts a calibration or validation point if the calibration or validation is in progress. 
*			The participant needs to be tracked and has to fixate the calibration or validation point. 
* 			See also @listcalibration
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_CALIBRATION_NOT_IN_PROGRESS					calibration or validation is not in progress
* @retval	ERR_NOT_CONNECTED								no connection established
**/ 
DLLExport int __stdcall iV_AcceptCalibrationPoint();


/**
* @brief 	Starts a calibration process. To proceed, the participant needs to be tracked and 
*			has to fixate the calibration point. Depending on the calibration settings (which can 
*			be changed using @ref iV_SetupCalibration and by @ref iV_SetUseCalibrationKeys) the user can 
*			accept the calibration points manually (by pressing SPACE or calling @ref iV_AcceptCalibrationPoint) 
*			or abort the calibration (by pressing ESC or calling @ref iV_AbortCalibration)<BR> 
*			If the calibration is visualized by the API (CalibrationStruct::visualization is set to 1) 
*			the function won't return until the calibration has been finished (closed automatically) 
*			or aborted.<BR>
*			If the CalibrationStruct::visualization is set to 0, iV_Calibrate returns
*			immediately. The user has to care about the visualization of calibration points. Information
*			about the current calibration point can be retrieved with @ref iV_GetCurrentCalibrationPoint 
*			or with setting up the calibration callback using @ref iV_SetCalibrationCallback.<BR>
* 			See also @listcalibration
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_CALIBRATION_ABORTED							calibration was aborted during progress 
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_DEVICE 								eye tracking device required for this function 
*															is not connected
* @retval	ERR_WRONG_CALIBRATION_METHOD					eye tracking device required for this 
*															calibration method is not connected
**/
DLLExport int __stdcall iV_Calibrate();


/**
* @brief	Changes the position of a calibration point. This has to be done before the calibration 
*			process is started. The parameter number refers to the calibration method used. 
*			If this function is used with a RED or RED-m device, the change is applied to the
*			currently selected profile.
* 			See also @listcalibration
* 
* @param	number											selected calibration point
* @param	positionX										new X position on screen [pixel] 
* @param	positionY										new Y position on screen [pixel] 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_PARAMETER 							parameter out of range
**/ 
DLLExport int __stdcall iV_ChangeCalibrationPoint(int number, int positionX, int positionY);


/**
* @brief	Removes all trigger AOIs. 
* 			See also @listaoi
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_AOI_ACCESS									failed to access AOI data 
**/ 
DLLExport int __stdcall iV_ClearAOI();


/**
* @brief 	Clears the recorded data buffer. The recording buffer needs to be stopped using "iV_StopRecording" 
*			before it can be cleared. 
*			If you are using an "HED", the scene video buffer is cleared, too.
*			See also @listeyedatarecording
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this function 
*															is not connected
* @retval	ERR_EMPTY_DATA_BUFFER							recording buffer is empty 
* @retval	ERR_RECORDING_DATA_BUFFER						recording is activated 
* @retval	ERR_PAUSED_DATA_BUFFER							recording buffer is paused 
**/
DLLExport int __stdcall iV_ClearRecordingBuffer();


/**
* @brief	Queries or sets filter parameters. The usage of the parameter data depends on the parameter type. 
*
* @param	filter											filter type which will be is configured. See @ref FilterType
* @param	action											type of action to modify the corresponding filter. See @ref FilterAction
* @param	data											a void pointer that can be casted to a data type depending on filter type. 
*															Please refer to @ref FilterType for details.
*															Content of the parameter depends on filter action, see @ref FilterType.<BR>
*															@ref FilterAction::Query data is filled with current filter settings.<BR>
*															@ref FilterAction::Set data is passed to cofigure the filter
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_PARAMETER								parameter out of range
* @retval	ERR_WRONG_IVIEWX_VERSION						wrong version of iView X (eyetracking-server) 
**/ 
DLLExport int __stdcall iV_ConfigureFilter(enum FilterType filter, enum FilterAction action, void *data);


/**
* @brief	Establishes a connection to iView X (eyetracking-server). @ref iV_Connect will 
*			not return until a connection has been established. If no connection can be 
*			established, the function will return after the time span defined by
*			@ref iV_SetConnectionTimeout. Default time span is 3 seconds.
*			See also @listsystemstartstop
*
* @param	sendIPAddress									IP address of iView X (eyetracking-server) computer 
* @param	sendPort										port being used by iView X SDK for sending data to iView X (eyetracking-server) 
* @param	recvIPAddress									IP address of local computer 
* @param	receivePort										port being used by iView X SDK for receiving data from iView X (eyetracking-server) 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_EYETRACKING_APPLICATION_NOT_RUNNING 		no eye tracking application running 
* @retval	ERR_WRONG_PARAMETER								parameter out of range
* @retval	ERR_COULD_NOT_CONNECT							failed to establish connection
**/ 
DLLExport int __stdcall iV_Connect(char *sendIPAddress, int sendPort, char *recvIPAddress, int receivePort);


/**
* @brief	Establishes a connection to eyetracking-server only. iV_ConnectLocal will 
*			not return until a connection has been established. If no connection can be 
*			established the function will return after the time span defined by
*			@ref iV_SetConnectionTimeout. Default time span is 3 seconds.<BR>
*			iV_ConnectLocal can only connect with RED-m or RED-OEM devices plugged in to
*			the same PC. 
*			See also @listsystemstartstop
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_EYETRACKING_APPLICATION_NOT_RUNNING			no eye tracking application running 
* @retval	ERR_COULD_NOT_CONNECT							failed to establish connection
**/ 
DLLExport int __stdcall iV_ConnectLocal();


/**
* @brief	Wakes up and enables the eye tracking application from suspend mode to 
*			continue processing gaze data. The application can be set to suspend mode 
*			by calling @ref iV_PauseEyetracking 
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED								no connection established
**/ 
DLLExport int __stdcall iV_ContinueEyetracking();


/**
* @brief	Continues gaze data recording. A HED video recording can neither be paused nor continued. 
*			@ref iV_ContinueRecording does not return until gaze recording is continued. Before 
*			it can be continued, the data needs to be paused using. 
*			@ref iV_PauseRecording. Additionally this function allows a message to be stored inside the 
*			idf data buffer. 
*			See also @listeyedatarecording
*
* @param	etMessage										text message that will be written to data file
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this function 
*															is not connected
* @retval	ERR_EMPTY_DATA_BUFFER							recording buffer is empty 
**/
DLLExport int __stdcall iV_ContinueRecording(char *etMessage);


/**
* @brief	Defines an AOI. The API can handle up to 20 AOIs. 
* 			See also @listaoi
* 
* @param	aoiData see reference information for @ref AOIStruct
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_WRONG_PARAMETER								parameter out of range
**/ 
DLLExport int __stdcall iV_DefineAOI(struct AOIStruct *aoiData);


/**
* @brief	Selects a port for sending out TTL trigger. 
* 			See also @listaoi
* 
* @param	port port address 
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_WRONG_PARAMETER								parameter out of range 
* @retval	ERR_COULD_NOT_OPEN_PORT							failed to open port 
**/ 
DLLExport int __stdcall iV_DefineAOIPort(int port);


/**
* @brief 	Deletes the RED-m geometry setup with the given name. It is not possible 
*			to delete a geometry profile if it is currently in use. See chapter 
*			@ref redgeometry in the iView X SDK Manual. 
*
* @param	setupName										name of the geometry setup which will be deleted 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED									no connection established
* @retval	ERR_WRONG_PARAMETER								parameter out of range
* @retval	ERR_WRONG_DEVICE									eye tracking device required for this function 
*															is not connected
**/
DLLExport int __stdcall iV_DeleteREDGeometry(char *setupName);


/**
* @brief	Disables all AOIs with the given name. 
* 			See also @listaoi
* 
* @param	aoiName 										name of the AOI which will be disabled  
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_NO_VALID_DATA								no data available
* @retval	ERR_AOI_ACCESS									failed to access AOI data
**/ 
DLLExport int __stdcall iV_DisableAOI(char *aoiName);


/**
* @brief	Disables an AOI group. 
* 			See also @listaoi
* 
* @param	aoiGroup 										name of the AOI group which will be disabled  
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_NO_VALID_DATA								no data available
* @retval	ERR_AOI_ACCESS									failed to access AOI data
**/ 
DLLExport int __stdcall iV_DisableAOIGroup(char *aoiGroup);


/**
* @brief 	Disables the raw data filter. The gaze data filter can be enabled 
*			using @ref iV_EnableGazeDataFilter. 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
**/
DLLExport int __stdcall iV_DisableGazeDataFilter();


/**
* @brief 	Disables a CPU high performance mode allowing the CPU to reduce the performance. 
*			See also @ref iV_EnableProcessorHighPerformanceMode
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED								no connection established
**/
DLLExport int __stdcall iV_DisableProcessorHighPerformanceMode();


/**
* @brief	Disconnects from iView X (eyetracking-server). @ref iV_Disconnect will not return 
*			until the connection has been disconnected. After this function has been called 
*			no other function or device can communicate with iView X (eyetracking-server).
*			See also @listsystemstartstop
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_DELETE_SOCKET								failed to delete sockets 
**/ 
DLLExport int __stdcall iV_Disconnect();


/**
* @brief	Enables all AOIs with the given name. 
* 			See also @listaoi
* 
* @param	aoiName name of the AOI which will be enabled 
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_NO_VALID_DATA								no data available
* @retval	ERR_AOI_ACCESS									failed to access AOI data
**/ 
DLLExport int __stdcall iV_EnableAOI(char *aoiName);


/**
* @brief	Enables an AOI group  
* 			See also @listaoi
* 
* @param	aoiGroup name of the AOI group which will be enabled 
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_NO_VALID_DATA								no data available
* @retval	ERR_AOI_ACCESS									failed to access AOI data
**/ 
DLLExport int __stdcall iV_EnableAOIGroup(char *aoiGroup);


/**
* @brief 	Enables a gaze data filter. This API bilateral filter was implemented due 
*			to special HCI application requirements. The gaze data filter can be disabled 
*			using @ref iV_DisableGazeDataFilter. 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
**/
DLLExport int __stdcall iV_EnableGazeDataFilter();


/**
* @brief 	Enables a CPU high performance mode to prevent the CPU from reducing the performance. 
*			See also @ref iV_DisableProcessorHighPerformanceMode
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED								no connection established
**/
DLLExport int __stdcall iV_EnableProcessorHighPerformanceMode();


/**
* @brief 	Updates @ref AccuracyStruct accuracyData with validated accuracy results. Before 
*			accuracy data is accessible the accuracy needs to be validated with 
*			@ref iV_Validate. If the parameter <TT>visualization</TT> is set to <TT>1</TT> the accuracy 
*			data will be visualized in a dialog window. 
*			See also @listvalidation and the chapter @ref validation in the iView X SDK Manual. 
*
* @param	accuracyData									see reference information for @ref AccuracyStruct 
* @param	visualization									0: no visualization 
*															1: accuracy data will be visualized in a dialog window 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_NOT_VALIDATED								system is not validated
* @retval	ERR_WRONG_PARAMETER								parameter out of range
**/
DLLExport int __stdcall iV_GetAccuracy(struct AccuracyStruct *accuracyData, int visualization);


/**
* @brief 	Updates <TT>imageData</TT> struct with drawn accuracy results. Before 
*			accuracy data is accessible the accuracy needs to be validated with 
*			@ref iV_Validate. 
*			See also @listvalidation and the chapter @ref validation in the iView X SDK Manual. 
*
* @param	imageData										see reference information for @ref ImageStruct
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_NOT_VALIDATED								system is not validated
**/
DLLExport int __stdcall iV_GetAccuracyImage(struct ImageStruct *imageData);


/**
* @brief 	Gives back the AOI value 
* 			See also @listaoi
*
* @param	aoiOutputValue									provides the AOI output value 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED								no connection established 
**/
DLLExport int __stdcall iV_GetAOIOutputValue(int *aoiOutputValue);


/**
* @brief	Updates stored <TT>calibrationData</TT> information with currently selected parameters. 
* 			See also @listcalibration
*
* @param	calibrationData									see reference information for @ref CalibrationStruct
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED								no connection established
**/
DLLExport int __stdcall iV_GetCalibrationParameter(struct CalibrationStruct *calibrationData);


/**
* @brief	Delivers information about a calibration point.
* 			See also @listcalibration
*
* @param	calibrationPointNumber							number of requested calibration point 
* @param	calibrationPoint								information of requested calibration point, stored in @ref CalibrationPointStruct 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_NO_VALID_DATA	 							no new data available
* @retval	ERR_NOT_CONNECTED								no connection established 
* @retval	ERR_WRONG_PARAMETER								parameter out of range
**/
DLLExport int __stdcall iV_GetCalibrationPoint(int calibrationPointNumber, struct CalibrationPointStruct *calibrationPoint);


/**
* @brief	Updates <TT>calibrationStatus</TT> information. The client needs to be connected 
*			to the eyetracking-server. 
* 			See also @listcalibration
*
* @param	calibrationStatus								see reference information for @ref CalibrationStatusEnum
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_NO_VALID_DATA	 							no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
**/
DLLExport int __stdcall iV_GetCalibrationStatus(enum CalibrationStatusEnum *calibrationStatus);


/**
* @brief 	Updates data in @ref CalibrationPointStruct <TT>currentCalibrationPoint</TT> 
*			with current calibration point data.
* 			See also @listcalibration
*
* @param	currentCalibrationPoint							information of requested calibration point, stored in @ref CalibrationPointStruct 
*
* @retval	RET_SUCCESS 									intended functionality has been fulfilled 
* @retval	RET_NO_VALID_DATA								no new data available 
* @retval	ERR_NOT_CONNECTED								no connection established 
**/
DLLExport int __stdcall iV_GetCurrentCalibrationPoint(struct CalibrationPointStruct *currentCalibrationPoint);


/**
* @brief	Gets the currently loaded RED geometry. See chapter @ref redgeometry in the iView X SDK Manual
*			and @listgeometry
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established 
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this function 
*															is not connected
**/ 
DLLExport int __stdcall iV_GetCurrentREDGeometry(struct REDGeometryStruct *redGeometry);


/**
* @brief 	Provides the current eye tracker timestamp in microseconds. 
*			See also @listdataacquisition
*
* @param	currentTimestamp								requested time stamp 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
**/
DLLExport int __stdcall iV_GetCurrentTimestamp(long long *currentTimestamp);


/**
* @brief	Updated the device name information of the connected device. 
*
* @param	deviceName										the name of the requested device  
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_IVIEWX_VERSION						wrong version of iView X (eyetracking-server) 
**/
DLLExport int __stdcall iV_GetDeviceName(char deviceName[64]);


/**
* @brief 	Updates data from @ref EventStruct <TT>eventDataSample</TT> with current event data.
*			See also @listdataacquisition
*
* @param	eventDataSample									see reference information for @ref EventStruct
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
**/
DLLExport int __stdcall iV_GetEvent(struct EventStruct *eventDataSample);


/**
* @brief 	Updates data from @ref EventStruct32 <TT>eventDataSample</TT> with current event data.
*			See also @listdataacquisition
*
* @param	eventDataSample									see reference information for @ref EventStruct32
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
**/
DLLExport int __stdcall iV_GetEvent32(struct EventStruct32 *eventDataSample);


/**
* @brief 	Updates <TT>imageData</TT> with current eye image 
*
* @param	imageData										see reference information for @ref ImageStruct
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this function 
*															is not connected
**/
DLLExport int __stdcall iV_GetEyeImage(struct ImageStruct *imageData);


/**
* @brief 	Gets the device specific feature key. Used for RED-OEM devices only. 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED								no connection established 
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this function 
*															is not connected 
* @retval	ERR_WRONG_IVIEWX_VERSION						wrong version of iView X (eyetracking-server) 
**/
DLLExport int __stdcall iV_GetFeatureKey(long long *featureKey);


/**
* @brief 	Gets all available profiles by name. They will be written comma-separated 
*			in the char buffer. The user needs to be sure that the buffer is not smaller 
*			than the needed buffer length. See chapter @ref redgeometry 
*			in the iView X SDK Manual and @listgeometry
*
* @param	maxSize											the length of the string profileNames 
* @param	profileNames									an empty string where profile names will be put in 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_PARAMETER								parameter out of range
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this 
*															function is not connected  
**/
DLLExport int __stdcall iV_GetGeometryProfiles(int maxSize, char *profileNames);


/**
* @brief 	Gets the system license expiration date. The license will not expire if the 
*			license is set to 00.00.0000. 
*			See also @listsystemstartstop
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
**/
DLLExport int __stdcall iV_GetLicenseDueDate(struct DateStruct *licenseDueDate);


/**
* @brief	Gets the geometry data of a requested profile without selecting them. 
*			See chapter @ref redgeometry in the iView X SDK Manual and @listgeometry
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED								no connection established 
* @retval	ERR_WRONG_PARAMETER								parameter out of range 
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this 
*															function is not connected 
**/ 
DLLExport int __stdcall iV_GetREDGeometry(char *profileName, struct REDGeometryStruct *redGeometry);


/**
* @brief 	Updates data in SampleStruct <TT>rawDataSample</TT> with current eye tracking data. 
*			See also @listdataacquisition
*
* @param	rawDataSample									see reference information for @ref SampleStruct
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
**/
DLLExport int __stdcall iV_GetSample(struct SampleStruct *rawDataSample);


/**
* @brief 	Updates data in SampleStruct32 <TT>rawDataSample</TT> with current eye tracking data sample. 
*			See also @listdataacquisition
*
* @param	rawDataSample									see reference information for @ref SampleStruct32
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
**/
DLLExport int __stdcall iV_GetSample32(struct SampleStruct32 *rawDataSample);


/**
* @brief 	Updates @ref ImageStruct <TT>imageData</TT> with current scene video image.
*			This functions is available for HED only. 
*
* @param	imageData										see reference information for @ref ImageStruct
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this function 
*															is not connected
**/
DLLExport int __stdcall iV_GetSceneVideo(struct ImageStruct *imageData);


/**
* @brief	Updated the serial number information of the connected device. 
*			See also @listsystemstartstop
*
* @param	serialNumber									the serial number of the requested device  
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_NO_VALID_DATA								no data available 
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_IVIEWX_VERSION						wrong version of iView X  
**/
DLLExport int __stdcall iV_GetSerialNumber(char serialNumber[64]);


/**
* @brief	Updates @ref SystemInfoStruct systemInfoData with current system information. 
*			See also @listsystemstartstop
*
* @param	systemInfoData									see reference information for @ref SystemInfoStruct
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_NO_VALID_DATA								no data available
**/
DLLExport int __stdcall iV_GetSystemInfo(struct SystemInfoStruct *systemInfoData);


/**
* @brief 	Updates @ref ImageStruct <TT>imageData</TT> with current tracking monitor image 
*
* @param	imageData										see reference information for @ref ImageStruct
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this function 
*															is not connected
**/
DLLExport int __stdcall iV_GetTrackingMonitor(struct ImageStruct *imageData);


/**
* @brief 	Updates TrackingStatusStruct <TT>trackingStatus</TT> with current tracking status.
*
* @param	trackingStatus									see reference information for @ref TrackingStatusStruct 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	RET_NO_VALID_DATA								no new data available
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this function 
*															is not connected
**/
DLLExport int __stdcall iV_GetTrackingStatus(struct TrackingStatusStruct *trackingStatus);


/**
* @brief 	Gets the interaction keys during the calibration and validation process. If enableKeys 
*			is set to zero all available user interaction (SPACE for accepting calibration/validation 
*			points and ESC for aborting calibration/validation) are disabled. 
*			See also @listvalidation @listcalibration
*
**/
DLLExport int __stdcall iV_GetUseCalibrationKeys(int *enableKeys);


/**
* @brief	Hides accuracy monitor window which can be opened by @ref iV_ShowAccuracyMonitor.
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_WINDOW_IS_CLOSED							window is closed 
* @retval	ERR_NOT_CONNECTED								no connection established
**/ 
DLLExport int __stdcall iV_HideAccuracyMonitor();


/**
* @brief	Hides eye image monitor window which can be opened by @ref iV_ShowEyeImageMonitor.
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_WINDOW_IS_CLOSED							window is closed 
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this function 
*															is not connected
**/ 
DLLExport int __stdcall iV_HideEyeImageMonitor();


/**
* @brief	Hides scene video monitor window which can be opened by @ref iV_ShowSceneVideoMonitor.
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_WINDOW_IS_CLOSED							window is closed 
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this function 
*															is not connected
**/ 
DLLExport int __stdcall iV_HideSceneVideoMonitor();


/**
* @brief	Hides tracking monitor window which can be opened by @ref iV_ShowTrackingMonitor.
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_WINDOW_IS_CLOSED							window is closed 
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this function 
*															is not connected
**/ 
DLLExport int __stdcall iV_HideTrackingMonitor();


/**
* @brief	Checks if connection to iView X (eyetracking-server) is still established.	
*			See also @listsystemstartstop
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED								no connection established
**/ 
DLLExport int __stdcall iV_IsConnected();


/**
* @brief 	Loads a previously saved calibration. A calibration has to be saved by using 
*			@ref iV_SaveCalibration. 
* 			See also @listcalibration
*
* @param	name											calibration name / identifier 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED								no connection established 
* @retval	ERR_WRONG_IVIEWX_VERSION						wrong version of iView X  
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this 
*															function is not connected
* @retval	ERR_WRONG_PARAMETER								parameter out of range
**/
DLLExport int __stdcall iV_LoadCalibration(char *name);


/**
* @brief 	Writes <TT>logMessage</TT> into log file 
*
* @param	logMessage										message that shall be written to the log file 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_ACCESS_TO_FILE								failed to access log file 
**/
DLLExport int __stdcall iV_Log(char *logMessage);


/**
* @brief	Suspends the eye tracking application and disables calculation of gaze data. 
*			The application can be reactivated by calling @ref iV_ContinueEyetracking. 
*			See also @listsystemstartstop
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED								no connection established
**/ 
DLLExport int __stdcall iV_PauseEyetracking();


/**
* @brief 	Pauses gaze data recording. A HED video recording can neither be paused nor continued. 
*			@ref iV_PauseRecording does not return until gaze recording is paused. 
*			See also @listeyedatarecording
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this function 
*															is not connected
* @retval	ERR_EMPTY_DATA_BUFFER							recording buffer is empty 
* @retval	ERR_FULL_DATA_BUFFER							data buffer is full 
**/
DLLExport int __stdcall iV_PauseRecording();


/**
* @brief	Disconnects and closes iView X (eyetracking-server). After this function 
*			has been called no other function or application can communicate
*			with iView X (eyetracking-server). 
*			See also @listsystemstartstop
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_DELETE_SOCKET								failed to delete sockets 
* @retval	ERR_WRONG_IVIEWX_VERSION						wrong version of iView X 
**/ 
DLLExport int __stdcall iV_Quit();


/**
* @brief	Releases the port for sending TTL trigger. 
* 			See also @listaoi
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
**/ 
DLLExport int __stdcall iV_ReleaseAOIPort();


/**
* @brief	Removes all AOIs with the given name. 
* 			See also @listaoi
* 
* @param	aoiName											name of the AOI which will be removed 
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	RET_NO_VALID_DATA								no data available
* @retval	ERR_AOI_ACCESS									failed to access AOI data
**/ 
DLLExport int __stdcall iV_RemoveAOI(char *aoiName);


/**
* @brief	Resets all calibration points to its default position. 
* 			See also @listcalibration
* 
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED								no connection established 
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this 
*															function is not connected
**/ 
DLLExport int __stdcall iV_ResetCalibrationPoints();


/**
* @brief 	Saves a calibration with a custom name. To save a calibration 
*			it is required that a successful calibration already has been completed. 
* 			See also @listcalibration
*
* @param	name											calibration name / identifier 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED								no connection established 
* @retval	ERR_WRONG_IVIEWX_VERSION						wrong version of iView X  
* @retval	ERR_WRONG_DEVICE								eye tracking device required for this 
*															function is not connected
* @retval	ERR_WRONG_PARAMETER								parameter out of range
**/
DLLExport int __stdcall iV_SaveCalibration(char *name);


/**
* @brief 	Writes recorded data buffer to disc. The data recording needs to be stopped using 
*			@ref iV_StopRecording before the data buffer can be saved to given location. 
*			The <TT>filename</TT> can include the path. 
*			If the connected eye tracking device is a HED, scene video buffer is written, too.
*			@ref iV_SaveData will not return until the data has been saved. 
*
* @param	filename										filename (incl. path) of data files being created 
*															(.idf: eyetracking data, .avi: scene video data) 
*															If no path is provided, eyetracking server tries to save the file into
*															it's binary path, e.g. <TT>C:\\Program Files\\SMI\\iViewREDm</TT>.
* @param	description										Optional experiment description tag stored in the idf file. 
*															This tag is available in BeGaze and in the text export from an idf file.
* @param	user											Optional name of test person.
*															This tag is available in BeGaze and in the text export from an idf file.
* @param	overwrite										Overwriting policy.
*															0: do not overwrite file <TT>filename</TT> if it already exists 
*															1: overwrite file <TT>filename</TT> if it already exists 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED								no connection established 
* @retval	ERR_WRONG_PARAMETER								parameter out of range
* @retval	ERR_EMPTY_DATA_BUFFER							recording buffer is empty 
* @retval	ERR_RECORDING_DATA_BUFFER 						recording is activated 
* @retval	ERR_PAUSED_DATA_BUFFER							recording buffer is paused 
**/
DLLExport int __stdcall iV_SaveData(char* filename, char* description, char* user, int overwrite);


/**
* @brief	Sends a remote command to iView X (eyetracking-server). Please refer to 
*			the iView X help file for further information about remote commands. 
*			Important Note: This function is temporary and will not be supported 
*			in subsequent versions. 
*			See also @listeyedatarecording
* 
* @param	etMessage										iView X remote command
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED								no connection established
* @retval	ERR_WRONG_PARAMETER								parameter out of range
**/ 
DLLExport int __stdcall iV_SendCommand(char* etMessage);


/**
* @brief 	Sends a text message to iView X idf recording data file. If the <TT>etMessage</TT> 
*			has the suffix ".jpg", ".bmp", ".png", or ".avi" BeGaze will separate the 
*			data buffer automatically into according trials. 
*			See also @listeyedatarecording
*
* @param	etMessage										Any text message to separate trials (image name containing 
*															extensions) or any idf data marker 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED								no connection established
**/
DLLExport int __stdcall iV_SendImageMessage(char* etMessage);


/**
* @brief 	Sets a callback function for the AOI hit functions. The function will be called 
*			if the iView X (eyetracking-server) has calculated an AOI hit. For usage of this 
*			function AOI's needs to be defined. 
* 			See also @listaoi
*			Important note: Algorithms with high processor usage and long calculation time 
*			shouldn't run within this callback due to a higher probability of data loss
*			See also @listdataacquisition
*
* @param	pAOIHitCallbackFunction							pointer to AOIHitCallbackFunction 
*
* @retval	RET_SUCCESS										intended functionality has been fulfilled 
* @retval	ERR_WRONG_PARAMETER								parameter out of range
**/
DLLExport int __stdcall iV_SetAOIHitCallback(pDLLSetAOIHit pAOIHitCallbackFunction); 


/**
* @brief 	Sets a callback function for the calibration and validation process. The callback function 
*			will be called after a calibration or validation point was moved and needs to be redrawn on 
*			the new position, or if the calibration or validation was finished successfully or 
*			unsuccessfully. It's possible to disable the callback by hand over NULL as a parameter. 
* 			See also @listcalibration
*
* @param	pCalibrationCallbackFunction				pointer to CalibrationCallbackFunction
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	ERR_WRONG_PARAMETER							parameter out of range
**/
DLLExport int __stdcall iV_SetCalibrationCallback(pDLLSetCalibrationPoint pCalibrationCallbackFunction); 


/**
* @brief 	Defines a customized timeout for how long @ref iV_Connect tries to connect 
*			to iView X (eyetracking-server).
*			See also @listsystemstartstop
*
* @param	time										the time [sec] iV_Connect is waiting for iView X response 
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	ERR_WRONG_PARAMETER							parameter out of range
**/
DLLExport int __stdcall iV_SetConnectionTimeout(int time);


/**
* @brief 	Selects a predefined geometry profile. See chapter @ref redgeometry 
*			in the iView X SDK Manual and @listgeometry
*
* @param	profileName									name of the selected profile which should be selected 
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED							no connection established
* @retval	ERR_WRONG_PARAMETER							parameter out of range
* @retval	ERR_WRONG_DEVICE							eye tracking device required for this 
*														function is not connected  
**/
DLLExport int __stdcall iV_SelectREDGeometry(char* profileName);


/**
* @brief 	Sets a callback function for the event data. The function will be called if a 
*			real-time detected fixation has been started or ended. 
*			Important note: Algorithms with high processor usage and long calculation time 
*			shouldn't run within this callback due to a higher probability of data loss. 
*			See also @listdataacquisition
*
* @param	pEventCallbackFunction						pointer to EventCallbackFunction
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	ERR_WRONG_PARAMETER							parameter out of range
**/
DLLExport int __stdcall iV_SetEventCallback(pDLLSetEvent pEventCallbackFunction); 


/**
* @brief 	Defines the detection parameter for online fixation detection algorithm. 
*			See also @listdataacquisition
*
* @param	minDuration									minimum fixation duration [ms]
* @param	maxDispersion								maximum dispersion [pixel] for head tracking systems
*														or [deg] for non head tracking systems
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED							no connection established
* @retval	ERR_WRONG_PARAMETER							parameter out of range
**/
DLLExport int __stdcall iV_SetEventDetectionParameter(int minDuration, int maxDispersion);


/**
* @brief 	Sets a callback function for the eye image data. The function will be called if a 
*			new eye image is available. The image format is monochrome 8bpp.
*			Important note: Algorithms with high processor usage and long calculation time 
*			shouldn't run within this callback due to a higher probability of data loss. 
*
* @param	pEyeImageCallbackFunction					pointer to EyeImageCallbackFunction
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	ERR_WRONG_PARAMETER							parameter out of range
**/
DLLExport int __stdcall iV_SetEyeImageCallback(pDLLSetEyeImage pEyeImageCallbackFunction);


/**
* @brief	Validates the customer license (only for OEM devices). 
*			See also @listsystemstartstop
*
* @param	licenseKey									provided license key
* 
* @retval	RET_SUCCESS									intended functionality has been fulfilled 
* @retval	ERR_WRONG_PARAMETER							parameter out of range
**/ 
DLLExport int __stdcall iV_SetLicense(const char* licenseKey);


/**
* @brief 	Defines the logging behavior of iView X SDK 
*
* @param	logLevel									see @ref logLevel in subsection  @ref explaningDefines "Explanations for Defines" in this manual 
*														for further information 
* @param	filename									filename of log file 
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled 
* @retval	ERR_WRONG_PARAMETER							parameter out of range 
* @retval	ERR_ACCESS_TO_FILE							failed to access log file 
**/
DLLExport int __stdcall iV_SetLogger(int logLevel, char* filename);


/**
* @brief 	@ref iV_SetResolution function defines a fixed resolution independent to the screen 
*			resolution of chosen display device defined in @ref iV_SetupCalibration function. 
*
* @param	stimulusWidth								horizontal resolution of stimulus screen [pixel] 
* @param	stimulusHeight								vertical resolution of stimulus screen [pixel] 
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled 
* @retval	ERR_NOT_CONNECTED							no connection established
* @retval	ERR_WRONG_PARAMETER							parameter out of range 
**/
DLLExport int __stdcall iV_SetResolution(int stimulusWidth, int stimulusHeight);


/**
* @brief 	Sets a callback function for the raw sample data. The function will be called 
*			if iView X (eyetracking-server) has calculated a new data sample. 
*			Important note: Algorithms with high processor usage and long calculation time 
*			shouldn't run within this callback due to a higher probability of data loss.
*			See also @listdataacquisition
*
* @param	pSampleCallbackFunction						pointer to SampleCallbackFunction 
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled 
* @retval	ERR_WRONG_PARAMETER							parameter out of range
**/
DLLExport int __stdcall iV_SetSampleCallback(pDLLSetSample pSampleCallbackFunction); 


/**
* @brief 	Sets a callback function for the scene video image data. The function will be 
*			called if a new scene video image is available. The image format is RGB 24bpp. 
*			Important note: Algorithms with high processor usage and long calculation time 
*			shouldn't run within this callback due to a higher probability of data loss. 
*
* @param	pSceneVideoCallbackFunction					pointer to SceneVideoCallbackFunction
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled 
* @retval	ERR_WRONG_PARAMETER							parameter out of range
**/
DLLExport int __stdcall iV_SetSceneVideoCallback(pDLLSetSceneVideo pSceneVideoCallbackFunction);


/**
* @brief 	Sets a callback function for the tracking monitor image data. The function will be 
*			called if a new tracking monitor image was calculated. The image format is RGB 24bpp. 
*			Important note: Algorithms with high processor usage and long calculation time 
*			shouldn't run within this callback due to a higher probability of data loss. 
*
* @param	pTrackingMonitorCallbackFunction			pointer to TrackingMonitorCallbackFunction
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled 
* @retval	ERR_WRONG_PARAMETER							parameter out of range
**/
DLLExport int __stdcall iV_SetTrackingMonitorCallback(pDLLSetTrackingMonitor pTrackingMonitorCallbackFunction);


/**
* @brief	Sets iView X (eyetracking-server) tracking parameters. See @ref trackerParameter subsection and 
*			iView X (eyetracking-server) manual for further explanations. 
*
* @param	ET_PARAM_EYE								select specific eye 
* @param	ET_PARAM									select parameter that shall be set 
* @param	value										new value for selected parameter
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED							no connection established
* @retval	ERR_WRONG_PARAMETER							parameter out of range
**/
DLLExport int __stdcall iV_SetTrackingParameter(int ET_PARAM_EYE, int ET_PARAM, int value);


/**
* @brief 	Sets the calibration and validation visualization parameter. 
* 			See also @listcalibration
*
* @param	calibrationData								see reference information for "CalibrationStruct"
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	ERR_WRONG_PARAMETER							parameter out of range
* @retval	ERR_WRONG_DEVICE							eye tracking device required for this 
*														function is not connected  
* @retval	ERR_WRONG_CALIBRATION_METHOD				eye tracking device required for this 
*														calibration method is not connected
**/
DLLExport int __stdcall iV_SetupCalibration(struct CalibrationStruct *calibrationData);


/**
* @brief 	Sets and resets the interaction keys during the calibration and validation process. If enableKeys 
*			will be set to zero all available user interaction (SPACE for accepting calibration/validation 
*			points and ESC for aborting calibration/validation) will be disabled. If enableKeys will be set to 
*			one (default) the SPACE and ESC buttons are available during the calibration and the validation process. 
*			See also @listvalidation @listcalibration
*
**/
DLLExport int __stdcall iV_SetUseCalibrationKeys(int enableKeys);


/**
* @brief 	Define the RED and RED-m stand alone and monitor integrated geometry. 
*			See chapter @ref redgeometry in the iView X SDK Manual 
*			and @listgeometry for details.
*
* @param	redGeometry									see reference information for @ref REDGeometryStruct
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED							no connection established
* @retval	ERR_WRONG_PARAMETER							parameter out of range
* @retval	ERR_WRONG_DEVICE							eye tracking device required for this function 
*														is not connected
**/
DLLExport int __stdcall iV_SetREDGeometry(struct REDGeometryStruct *redGeometry);


/**
* @brief 	The validated accuracy results will be visualized in a dialog window. Before the 
*			image can be drawn the calibration needs to be performed with @ref iV_Calibrate and 
*			validated with @ref iV_Validate. 
*			See also @listvalidation
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	RET_WINDOW_IS_OPEN							window is open 
* @retval	ERR_NOT_CONNECTED							no connection established
* @retval	ERR_NOT_VALIDATED							system is not validated
**/
DLLExport int __stdcall iV_ShowAccuracyMonitor();

/**
* @brief 	Visualizes eye image in a separate window while the participant will be tracked 
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	RET_WINDOW_IS_OPEN							window is open 
* @retval	ERR_NOT_CONNECTED							no connection established
* @retval	ERR_WRONG_DEVICE							eye tracking device required for this function 
*														is not connected
**/
DLLExport int __stdcall iV_ShowEyeImageMonitor();


/**
* @brief 	Visualizes scene video in separate window (available for HED devices only). 
*			See also @listhedscene
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	RET_WINDOW_IS_OPEN							window is open 
* @retval	ERR_NOT_CONNECTED							no connection established
* @retval	ERR_WRONG_DEVICE							eye tracking device required for this function 
*														is not connected
**/
DLLExport int __stdcall iV_ShowSceneVideoMonitor();


/**
* @brief 	Visualizes RED tracking monitor in a separate dialog window. It shows the position 
*			of the participant related to the eye tracking device and indicates (using arrows) 
*			if the participant is not positioned in the center of the tracking head box. 
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	RET_WINDOW_IS_OPEN							window is open 
* @retval	ERR_NOT_CONNECTED							no connection established
* @retval	ERR_WRONG_DEVICE							eye tracking device required for this function 
*														is not connected
**/
DLLExport int __stdcall iV_ShowTrackingMonitor(); 


/**
* @brief	Starts the iView X (eyetracking-server) application. Depending on the PC, 
*			it may take several seconds to start the iView X (eyetracking-server) application. 
*			The connection needs to be established separately using @ref iV_Connect. The connection 
*			timeout can be extended using @ref iV_SetConnectionTimeout. 
*			See also @listsystemstartstop
* 
* @param	etApplication								the iView X (eyetracking-server) application which will be started 
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled 
* @retval	RET_SERVER_IS_RUNNING						server is running 
* @retval	ERR_IVIEWX_NOT_FOUND						failed to start iView X (eyetracking-server) application 
* @retval	ERR_CAMERA_NOT_FOUND						failed to access device 
* @retval	ERR_WRONG_CAMERA							failed to access device 
* @retval	ERR_WRONG_CAMERA_PORT						failed to access device 
**/ 
DLLExport int __stdcall iV_Start(enum ETApplication etApplication);


/**
* @brief	Starts gaze data recording and scene video recording (if connected eye tracking 
*			device is "HED"). @ref iV_StartRecording does not return until gaze and scene video 
*			recording is started. The data streaming needs to be stopped by using @ref iV_StopRecording 
*			before it can be saved using @ref iV_SaveData. 
*			See also @listeyedatarecording
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED							no connection established
* @retval	ERR_WRONG_DEVICE							eye tracking device required for this 
*														function is not connected
* @retval	ERR_RECORDING_DATA_BUFFER					recording is activated 
**/
DLLExport int __stdcall iV_StartRecording();


/**
* @brief 	Stops gaze data recording and scene video recording (if connected eye tracking 
*			device is "HED"). @ref iV_StopRecording does not return until gaze and scene video 
*			recording is stopped. This function needs to be called before the data can 
*			be saved using @ref iV_SaveData. 
*			See also @listeyedatarecording
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	ERR_NOT_CONNECTED							no connection established
* @retval	ERR_WRONG_DEVICE							eye tracking device required for this function 
*														is not connected
* @retval	ERR_EMPTY_DATA_BUFFER						recording buffer is empty 
* @retval	ERR_FULL_DATA_BUFFER						data buffer is full 
**/
DLLExport int __stdcall iV_StopRecording();


/**
* @brief	Sends a TTL value to defined port. Define a port with @ref iV_DefineAOIPort. 
* 			See also @listaoi
* 
* @param	value										value which will be sends out as TTL signal 
* 
* @retval	RET_SUCCESS									intended functionality has been fulfilled 
* @retval	ERR_WRONG_PARAMETER							parameter out of range
**/ 
DLLExport int __stdcall iV_TestTTL(int value);


/**
* @brief 	Starts a validation process. To proceed, the participant needs to be tracked and 
*			has to fixate on the validation point. Depending on the validation settings (which can 
*			be changed using @ref iV_SetupCalibration and @ref iV_SetUseCalibrationKeys) the user 
*			can accept the validation points manually (by pressing SPACE or calling @ref iV_AcceptCalibrationPoint) 
*			or abort the validation (by pressing ESC or calling @ref iV_AbortCalibration). If the validation 
*			will be visualized by the API (CalibrationStruct::visualization is set to 1) 
*			the function won't return until the validation has been finished (closed automatically) 
*			or aborted (ESC). 
*			If the the CalibrationStruct::visualization is set to 0 iV_Validate returns
*			immediately. The user has to care about the visualization of validation points. Information
*			about the current validation point can be retrieved with @ref iV_GetCurrentCalibrationPoint 
*			or with setting up the calibration callback using @ref iV_SetCalibrationCallback.<BR>
*			See also @listvalidation @listcalibration
*
* @retval	RET_SUCCESS									intended functionality has been fulfilled
* @retval	RET_CALIBRATION_ABORTED						validation was aborted during progress 
* @retval	ERR_NOT_CONNECTED							no connection established
* @retval	ERR_NOT_CALIBRATED							system is not calibrated
* @retval	ERR_WRONG_DEVICE							eye tracking device required for this function is not connected
**/
DLLExport int __stdcall iV_Validate();



/** @}*/



/**
* @struct StandAloneModeGeometryStruct 
*
* @brief Deprecated. Please use @ref REDGeometryStruct instead. 
*/ 
struct StandAloneModeGeometryStruct
{
	char setupName[256];
	int stimX;
	int stimY;
	int stimHeightOverFloor;
	int redHeightOverFloor;
	int redStimDist;
	int redInclAngle;
};

/**
* @struct REDStandAloneModeStruct 
*
* @brief Deprecated. Please use @ref REDGeometryStruct instead. 
*/ 
struct REDStandAloneModeStruct
{
	int stimX;
	int stimY;
	int stimHeightOverFloor;
	int redHeightOverFloor;
	int redStimDist;
	int redInclAngle;
};

/**
* @struct MonitorAttachedGeometryStruct
*
* @brief Deprecated. Please use @ref REDGeometryStruct instead. 
*/ 
struct MonitorAttachedGeometryStruct
{
	char setupName[256];
	int stimX;
	int stimY;
	int redStimDistHeight;
	int redStimDistDepth;
	int redInclAngle;
};

/**
* @struct REDMonitorAttachedGeometryStruct
*
* @brief Deprecated. Please use @ref REDGeometryStruct instead. 
*/ 
struct REDMonitorAttachedGeometryStruct
{
	int stimX;
	int stimY;
	int redStimDistHeight;
	int redStimDistDepth;
	int redInclAngle;
};


/**
* @brief 	Deprecated. Please use @ref iV_SetREDGeometry instead. 
**/
DEPRECATED int __stdcall iV_SetupMonitorAttachedGeometry(struct MonitorAttachedGeometryStruct *monitorAttachedGeometry);

/**
* @brief 	Deprecated. Please use @ref iV_SetREDGeometry instead. 
**/
DEPRECATED int __stdcall iV_SetupStandAloneMode(struct StandAloneModeGeometryStruct *standAloneModeGeometry);

/**
* @brief 	Deprecated. Please use @ref iV_SetREDGeometry instead. 
**/
DEPRECATED int __stdcall iV_SetupREDMonitorAttachedGeometry(struct REDMonitorAttachedGeometryStruct* attachedModeGeometry);

/**
* @brief 	Deprecated. Please use @ref iV_SetREDGeometry instead. 
**/
DEPRECATED int __stdcall iV_SetupREDStandAloneMode(struct REDStandAloneModeStruct* standAloneModeGeometry);

/**
* @brief 	Deprecated. Please use @ref iV_GetREDGeometry instead. 
**/
DEPRECATED int __stdcall iV_GetMonitorAttachedGeometry(char profileName[256], struct MonitorAttachedGeometryStruct *monitorAttachedGeometry);

/**
* @brief 	Deprecated. Please use @ref iV_SelectREDGeometry instead. 
**/
DEPRECATED int __stdcall iV_SetGeometryProfile(char* profileName);

/**
* @brief 	Deprecated. Please use @ref iV_DeleteREDGeometry instead. 
**/
DEPRECATED int __stdcall iV_DeleteMonitorAttachedGeometry(char setupName[256]);

/**
* @brief 	Deprecated. Please use @ref iV_DeleteREDGeometry instead. 
**/
DEPRECATED int __stdcall iV_DeleteStandAloneGeometry(char setupName[256]);


