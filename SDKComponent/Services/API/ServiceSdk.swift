//
//  ServiceSdk.swift
//  NubariumSDK
//
//  Created by Amilcar Flores on 01/02/23.
//  Copyright © 2023 Nuabrium SA de CV. All rights reserved.
//

import Foundation
import Siesta

// Depending on your taste, a Service can be a global var, a static var singleton, or a piece of more carefully
// controlled shared state passed between pieces of the app.
let ServiceSdk = _ServiceSdk()

class _ServiceSdk{
    
    private let service = Service(
        baseURL: "https://api.sdk.nubarium.com",
        standardTransformers: [.text, .image])  // No .json because we use Swift 4 JSONDecoder instead of older JSONSerialization
    fileprivate init() {
        
#if DEBUG
        // Bare-bones logging of which network calls Siesta makes:
        SiestaLog.Category.enabled = [.network]
        
        // For more info about how Siesta decides whether to make a network call,
        // and which state updates it broadcasts to the app:
        //SiestaLog.Category.enabled = .common
        // For the gory details of what Siesta’s up to:
        //SiestaLog.Category.enabled = .detailed
        // To dump all requests and responses:
        // (Warning: may cause Xcode console overheating)
        //SiestaLog.Category.enabled = .all
#endif
        
        // –––––– Global configuration ––––––
        let jsonDecoder = JSONDecoder()
        
        service.configure {
            // Custom transformers can change any response into any other — including errors.
            // Here we replace the default error message with the one provided by the GitHub API (if present).
            $0.pipeline[.cleanup].add(
                ErrorMessageExtractor(jsonDecoder: jsonDecoder))
        }

        // –––––– Auth configuration ––––––
        // Note the "**" pattern, which makes this config apply only to subpaths of baseURL.
        // This prevents accidental credential leakage to untrusted servers.
        service.configure("**") {
            // This header configuration gets reapplied whenever the user logs in or out.
            // How? See the basicAuthHeader property’s didSet.
            $0.headers["Authorization"] = self.basicAuthHeader
        }
        
        service.configureTransformer("/ocr/v1/biometric_request") {
            try jsonDecoder.decode(RequestModel.self, from: $0.content)
        }
                
        service.configureTransformer("/face/v1/check_features") {
            try jsonDecoder.decode(FaceFeaturesModel.self, from: $0.content)
        }

        service.configureTransformer("/ocr/v1/validate_id_screen_attack_simple") {
            try jsonDecoder.decode(ValidateIdModel.self, from: $0.content)
        }
        
        service.configureTransformer("/ocr/v1/validate_face_features") {
            try jsonDecoder.decode(FaceFeaturesModel.self, from: $0.content)
        }
        
        service.configureTransformer("/face/v1/validate_simple_ios") {
            try jsonDecoder.decode(ValidateFaceModel.self, from: $0.content)
        }
        
        service.configureTransformer("/ocr/v1/biometric_validate_token") {
            try jsonDecoder.decode(ValidateTokenModel.self, from: $0.content)
        }
        
        /*
        // Note that you can use Siesta without these sorts of model mappings. By default, Siesta parses JSON, text,
        // and images based on content type — and a resource will contain whatever the server happened to return, in a
        // parsed but unstructured form (string, dictionary, etc.). If you prefer to work with raw dictionaries instead
        // of models (good for rapid prototyping), then no additional transformer config is necessary.
        //
        // If you do apply a path-based mapping like the ones above, then any request for that path that does not return
        // the expected type becomes an error. For example, "/users/foo" _must_ return a JSON response because that's
        // what jsonDecoder.decode(…) expects.
         */
    }
    
    // MARK: - Authentication
    func logIn(username: String, password: String) {
        if let auth = "\(username):\(password)".data(using: String.Encoding.utf8) {
            basicAuthHeader = "Basic \(auth.base64EncodedString())"
            print("basicAuthHeader")
            print(basicAuthHeader!)
        }
    }
    
    func logOut() {
        basicAuthHeader = nil
    }
    
    var isAuthenticated: Bool {
        return basicAuthHeader != nil
    }
    
    private var basicAuthHeader: String? {
        didSet {
            // These two calls are almost always necessary when you have changing auth for your API:
            service.invalidateConfiguration()  // So that future requests for existing resources pick up config change
            service.wipeResources()            // Scrub all unauthenticated data
            // Note that wipeResources() broadcasts a “no data” event to all observers of all resources.
            // Therefore, if your UI diligently observes all the resources it displays, this call prevents sensitive
            // data from lingering in the UI after logout.
        }
    }
    
    // MARK: - Endpoint Accessors
    // You can turn your REST API into a nice Swift API using lightweight wrappers that return Siesta resources.
    //
    // Note that this class keeps its Service private, making these methods the only entry points for the API.
    // You could also choose to subclass Service, which makes methods like service.resource(…) available to
    // your whole app. That approach is sometimes better for quick and dirty prototyping.
    //
    // If this section gets too long for your taste, you can move it to a separate file by putting a helper method
    // in an extension.
    var activeRepositories: Resource {
        return service
            .resource("/search/repositories")
            .withParams([
                "q": "stars:>0",
                "sort": "updated",
                "order": "desc"
            ])
    }

    func createRequest(component: String, version:String, device:String, tag:[String: Any], info:[String : Any]) -> Request {
        return service
            .resource("/ocr/v1/biometric_request").request(.post, json: ["component": component, "device":device, "tag":tag, "version":version, "class":"native_ios"])
    }
    
    func validateToken(token: String, device:String, force_request:Bool, component: String,version: String) -> Request {
        print("BODY", ["token": token, "device":device, "force_request":force_request, "component": component, "version": version, "class" :"native_ios"])
        return service
            .resource("/ocr/v1/biometric_validate_token").request(.post, json: ["token": token, "device":device, "force_request":force_request, "component": component, "version": version, "class" :"native_ios"])
    }
    
    func validateId(image: String, second:String, last:String, token:String, side: String, documentId:String) -> Request {
        return service
            .resource("/ocr/v1/validate_id_screen_attack_simple").request(.post, json: ["image": image, "second":second, "last":last, "token":token, "side":side, "document_id": documentId])
    }

    func validateFace(id:String, face: String, level: AntispoofingLevel, allow:[String], deny:[String], order:[String]) -> Request {
        var allowFacemask: Bool = false
        if(allow.contains("facemask")){
            allowFacemask = true
        }
        let forceFacemask: Bool = false
        var allowGlasses: Bool = false
        if(allow.contains("glasses")){
            allowGlasses = true
        }
        print(["id":id, "data":["antispoofingLevel":level.value, "allowGlasses":allowGlasses, "allowFacemask": allowFacemask,"forceFacemask":false ]])
        return service
            .resource("/face/v1/validate_simple_ios").request(.post, json: ["id":id, "face": face,"data":["antispoofingLevel":level.value, "allowGlasses":allowGlasses, "allowFacemask": allowFacemask,"forceFacemask":false ]])
    }
    
    func checkFaceFeatures(id: String, face: String) -> Request {
        return service
            .resource("/face/v1/check_features").request(.post, json: ["id": id, "face": face])
    }

}


// MARK: - Custom transformers
/// If the response is JSON and has a "message" value, use it as the user-visible error message.
private struct ErrorMessageExtractor: ResponseTransformer {
    let jsonDecoder: JSONDecoder

    func process(_ response: Response) -> Response {
        guard case .failure(var error) = response,     // Unless the response is a failure...
          let errorData: Data = error.typedContent(),  // ...with data...
          let apiError = try? jsonDecoder.decode(   // ...that encodes a standard error envelope...
            ApiErrorEnvelope.self, from: errorData)
        else {
          return response                              // ...just leave it untouched.
        }

        error.userMessage = apiError.message        // GitHub provided an error message. Show it to the user!
        return .failure(error)
    }

    private struct ApiErrorEnvelope: Decodable {
        let message: String
    }
}
