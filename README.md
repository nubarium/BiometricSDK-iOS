# BiometricSDK

Nubarium Biometric SDK for IOS  guide for developers.

## SDK compatibility

- Starting iOS 14.0.
- iPhone 8.0 or greater

## Installation

### Swift Package Manager

You can use [Swift Package Manager](https://swift.org/package-manager/) to install `BiometricSDK` by adding the appropriate description to your `Package.swift` file:

```swift
import PackageDescription

let package = Package(
    name: "BiometricSDK",
    dependencies: [
        .package(url: "https://github.com/nubarium/BiometricSDK-ios", .upToNextMajor(from: "1.0.0"))
    ],
    targets: [
        .target(
            name: "BiometricSDK",
            dependencies: ["BiometricSDK"])
    ]
)
```

Then, import `BiometricSDK` wherever you want to use it.

### Manually

You can manually integrate `BiometricSDK` into your project. Simply clone the repository and drag the `Sources` folder into your project.

Integrate

### Before you begin

- You must install Xcode 15, strongly recommend to install latest.
- Get the Nubarium Key or API Credentials. It is required to successfully initialize the SDK.
- The codes in this document are example implementations. Make sure to change the `<NUB_USERNAME>`, `<NUB_PASSWORD>` and other placeholders as needed.
- All the steps in this document are mandatory unless stated otherwise.

## Initializing the iOS SDK

Initialize your component as described above.

### Face Capture

#### **Step 1: Import Nubarium library**

```swift
import FaceCapture
```

In your View Controller, import the Nubarium library:

#### **Step 2: Initialize the SDK**

**Local variables**

It requires to declare the component as local variable.

```swift
private var faceCapture:FaceCapture?
```

**Setup the UIViewController lifecycle methods**

***Initialize with viewDidLoad***

In your `viewDidLoad` method of  the view controller that will handle the `FaceCapture` initialization

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    faceCapture = FaceCapture(viewController: self)
  
    // Setup credentials
    faceCapture!.credentials(username: "<YOURUSERNAME>",password: "<yourpassword>")
  	// Flag to enable/disable antispoofing, is optional - Default: true
  	faceCapture!.livenessRequired = true
  	// Set antispoofing level , is Optional - Default: .medium
    faceCapture!.level = .medium
  	// Flag to enable/disable the Intro view, is optional - Default: true  
    faceCapture!.showIntro = true
  	// Setup execution timeout        
    faceCapture!.timeout = 360
  	// Setup max validations          
    faceCapture!.maxValidations = 4
  	// Flag to enable/disable the component to aloow the user to finish the task even if fails, and retro the result, is is used by users tahat want to use a manual validation process. - Default: false 
    faceCapture!.allowCaptureOnFail = false
  	// Setup the policies for allow or deny special features like glasses and faecmask.  
    faceCapture!.policyRules(allow:[.glasses], deny:[ .facemask], order:[])
		
  	// Setup the camera side view, default value is front and is optional.
    faceCapture!.sideView = .front
        
    // Configure response event listeners
    faceCapture!.onLoad = onLoadFaceCapture
    faceCapture!.onInitError = onInitError
        
    // Configure response event listeners
    faceCapture!.onSuccess = onSuccess
    faceCapture!.onFail = onFail
    faceCapture!.onError = onError
}
```

#### **Step 3: Setting up ViewController result**

*viewWillAppear*

In your `viewWillAppear` method  of  the view controller that will handle return from `FaceCature` view controller and it result.

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    faceCapture!.process()
}
```

*prepare*

In your `prepare` method  of  the view controller that will handle the FaceCapture component initilize the component

```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    faceCapture!.prepare(segue: segue)    
}
```

#### **Step 4: Setting the initialization listener**

Set up event `onLoadFaceCapture` that is triggered when the componente was initilized with the credentials entered. This example start the face capture component to show the View Controller, but it could be executed as explained in the following example.

```swift
func onLoadFaceCapture(id: String){
    // Start and show ViewController component
    faceCapture!.start()
}
```

Set up event `OnInitError` that is triggered when the componente fails on initialziation process.

```swift
func onInitError(error: FaceCaptureInitError, msg: String){
    print("Init Error ->" ,error)
}
```

#### Step 5: Setting a result listener

To receive the images and result of component execution it is necessary to setting up a result listener.

```swift
func onSuccess(result : FaceCaptureResult,face: UIImage, area: UIImage, frame: UIImage){
    print("OnSuccess output")

    // Access Image with the face framed in the capture area.
    print("width", area.size.width)
    print("height", area.size.height)
  
    // Access the Fame Image.
    print("width", face.size.width)
    print("height", face.size.height)
  
    print("Result", result.result)  
    if(result.result == "PASS"){
    // Do something
    	print("Score", result.confidence)
    }
    if(result.result == "FAIL"){      
    // This is used when allowCaptureOnFail is configured
    	print("Score", result.confidence)
    }  
}

func onFail(result : FaceCaptureResult, faceCaptureReasonFail: FaceCaptureReasonFail, reason: String){
    print("OnFail")
    print("Confidence", result.confidence)
    print("Result", result.result)
    print("Fail", faceCaptureReasonFail)
    print("Reason", reason)
}

func onError(faceCaptureReasonError: FaceCaptureReasonError, message: String){
    print("OnError")
    print("Error", faceCaptureReasonError)
    print("Message", message)
}
```

- The `onSuccess()` callback method is invoked if the execution of the component was successful, the method returns the following elements.
  - result: An instance of `FaceCaptureResult` with information like score.
  - face: An `UIImage` with the face cropped.
  - area: An `UIImage` of the area where the face was framed.
- The `onFail()` callback method is invoked when the liveness validation failed for the given configuration, the method returns the following elements.
  - result: An instance of `FaceCaptureResult` with information like score.
  - faceCaptureReasonFail: An `FaceCaptureReasonFail` instance with the reason enumeration.
  - reason: A string with a reason fail.
- The `onError()` callback method is invoked when the component throws an error, the method returns the following elements.
  - faceCaptureReasonError: An `FaceCaptureReasonError`instance with the error enumeration.
  - message: A string with an error message.

#### Step 6: Start component

As in the application the component is declared as a local variable, it can be started in programmatically or in some event such as *on click* button.

***With Pre Initialization***

If you want to prevalidate your credentials and prevent a delay in the start event, just initialize the component after declare the properties and event listeners and before start.

```swift
faceCapture!.initialize();
```

But you can just call the event start.

```swift
faceCapture!.start();
```

### Id Capture

#### **Step 1: Import Nubarium library**

```swift
import IdCapture
```

In your View Controller, import the Nubarium library:

#### **Step 2: Initialize the SDK**

**Local variables**

It requires to declare the component as local variable.

```swift
private var idCapture:IdCapture?
```

**Setup the UIViewController lifecycle methods**

***Initialize with viewDidLoad***

In your `viewDidLoad` method of  the view controller that will handle the `IdCapture` initialization

```swift
override func viewDidLoad() {
    super.viewDidLoad()
    idCapture = IdCapture(viewController: self)
  
    // Setup credentials
    idCapture!.credentials(username: "<YOURUSERNAME>",password: "<yourpassword>")
  	// Flag to enable/disable antispoofing, is optional - Default: true
  	// Flag to enable/disable the Intro view, is optional - Default: true  
    idCapture!.showIntro = true
  	// Setup execution timeout        
    idCapture!.timeout = 360
  	// Setup max validations          
    idCapture!.maxValidations = 4
  	// Flag to enable/disable the component to aloow the user to finish the task even if fails, and retro the result, is is used by users tahat want to use a manual validation process. - Default: false 
    idCapture!.allowCaptureOnFail = false
  	
  	// Setup the camera side view, default value is back and is optional.
    idCapture!.sideView = .back
        
    // Configure initialization listeners
    idCapture!.onLoad = onLoadIdCapture
    idCapture!.onInitError = onInitError
        
    // Configure result listeners
    idCapture!.onSuccess = onSuccess
    idCapture!.onFail = onFail
    idCapture!.onError = onError
}
```

#### **Step 3: Setting up ViewController result**

*viewWillAppear*

In your `viewWillAppear` method  of  the view controller that will handle return from `IdCature` view controller and it result.

```swift
override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    idCapture!.process()
}
```

*prepare*

In your `prepare` method  of  the view controller that will handle the `IdCapture` component initilize the component

```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    idCapture!.prepare(segue: segue)    
}
```

#### **Step 4: Setting the initialization listener**

Set up event `onLoadIdCapture` that is triggered when the componente was initilized with the credentials entered. This example start the face capture component to show the View Controller, but it could be executed as explained in the following example.

```swift
func onLoadIdCapture(id: String){
    // Start and show ViewController component
    idCapture!.start()
}
```

Set up event `OnInitError` that is triggered when the componente fails on initialziation process.

```swift
func onInitError(error: IdCaptureInitError, msg: String){
    print("Init Error ->" ,error)
}
```

#### Step 5: Setting a result listener

To receive the images and result of component execution it is necessary to setting up a result listener.

```swift
func onSuccess(result : IdCaptureResult,front: UIImage, back: UIImage){
    print("OnSuccess output")
    print("Confidence", result.confidence)
    print("Result", result.result)       
}

func onFail(result : IdCaptureResult, idCaptureReasonFail: IdCaptureReasonFail, reason: String){
    print("OnFail")
    print("Confidence", result.confidence)
    print("Result", result.result)
    print("Fail", idCaptureReasonFail)
    print("Reason", reason)
}

func onError(idCaptureError: IdCaptureError, message: String){
    print("OnError")
    print("Error", idCaptureError)
    print("Message", message)
}
```

- The `onSuccess()` callback method is invoked if the execution of the component was successful, the method returns the following elements.
  - result: An instance of `FaceCaptureResult` with information like score.
  - front: An `UIImage` with the front id.
  - back: An `UIImage` with the back id.
- The `onFail()` callback method is invoked when the validation failed for the given configuration, the method returns the following elements.
  - result: An instance of `IdCaptureResult` with information like score.
  - idCaptureReasonFail: An `IdCaptureReasonFail` instance with the reason enumeration.
  - reason: A string with a reason fail.
- The `onError()` callback method is invoked when the component throws an error, the method returns the following elements.
  - idCaptureError: An `IdCaptureError`instance with the error enumeration.
  - message: A string with an error message.

#### Step 6: Start component

As in the application the component is declared as a local variable, it can be started in programmatically or in some event such as *on click* button.

***With Pre Initialization***

If you want to prevalidate your credentials and prevent a delay in the start event, just initialize the component after declare the properties and event listeners and before start.

```swift
idCapture!.initialize();
```

But you can just call the event start.

```swift
idCapture!.start();
```

