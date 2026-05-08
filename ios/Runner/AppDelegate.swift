import Flutter
import UIKit
import AuthenticationServices

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var webAuthnHandler: WebAuthnHandler?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    let controller = window?.rootViewController as! FlutterViewController
    webAuthnHandler = WebAuthnHandler(controller: controller)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

@available(iOS 16.0, *)
class WebAuthnHandler: NSObject {
  private let channel: FlutterMethodChannel
  private let controller: FlutterViewController
  private var completion: ((Result<[String: Any], Error>) -> Void)?

  init(controller: FlutterViewController) {
    self.controller = controller
    self.channel = FlutterMethodChannel(
      name: "com.moviroo/webauthn",
      binaryMessenger: controller.binaryMessenger
    )
    super.init()
    channel.setMethodCallHandler(handle)
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let options = args["options"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "Missing options", details: nil))
      return
    }

    switch call.method {
    case "register":
      handleRegister(options: options, result: result)
    case "authenticate":
      handleAuthenticate(options: options, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleRegister(options: String, result: @escaping FlutterResult) {
    guard let data = options.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      result(FlutterError(code: "PARSE_ERROR", message: "Invalid options JSON", details: nil))
      return
    }

    let rp = json["rp"] as? [String: Any] ?? [:]
    let user = json["user"] as? [String: Any] ?? [:]
    let challenge = userBase64Decode(user["id"] as? String ?? "") ?? Data()
    let userName = user["name"] as? String ?? ""
    let userDisplayName = user["displayName"] as? String ?? userName
    let rpId = rp["id"] as? String ?? ""
    let challengeData = userBase64Decode(json["challenge"] as? String ?? "") ?? Data()

    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
    let request = provider.createCredentialRegistrationRequest(
      challenge: challengeData,
      name: userName,
      userID: challenge
    )

    self.completion = { res in
      switch res {
      case .success(let dict):
        result(dict)
      case .failure(let error):
        result(FlutterError(code: "REGISTRATION_ERROR", message: error.localizedDescription, details: nil))
      }
    }

    let authController = ASAuthorizationController(authorizationRequests: [request])
    authController.delegate = self
    authController.presentationContextProvider = self
    authController.performRequests()
  }

  private func handleAuthenticate(options: String, result: @escaping FlutterResult) {
    guard let data = options.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      result(FlutterError(code: "PARSE_ERROR", message: "Invalid options JSON", details: nil))
      return
    }

    let rpId = json["rpId"] as? String ?? ""
    let challengeData = userBase64Decode(json["challenge"] as? String ?? "") ?? Data()

    let provider = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
    let request = provider.createCredentialAssertionRequest(challenge: challengeData)

    self.completion = { res in
      switch res {
      case .success(let dict):
        result(dict)
      case .failure(let error):
        result(FlutterError(code: "AUTHENTICATION_ERROR", message: error.localizedDescription, details: nil))
      }
    }

    let authController = ASAuthorizationController(authorizationRequests: [request])
    authController.delegate = self
    authController.presentationContextProvider = self
    authController.performRequests()
  }

  private func userBase64Decode(_ string: String) -> Data? {
    var base64 = string
      .replacingOccurrences(of: "-", with: "+")
      .replacingOccurrences(of: "_", with: "/")
    let padding = 4 - base64.count % 4
    if padding < 4 {
      base64 += String(repeating: "=", count: padding)
    }
    return Data(base64Encoded: base64)
  }
}

@available(iOS 16.0, *)
extension WebAuthnHandler: ASAuthorizationControllerDelegate {
  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialRegistration {
      let response: [String: Any] = [
        "id": credential.credentialID.base64URLEncodedString(),
        "rawId": credential.credentialID.base64URLEncodedString(),
        "type": "public-key",
        "response": [
          "clientDataJSON": credential.rawClientDataJSON.base64URLEncodedString(),
          "attestationObject": credential.rawAttestationObject?.base64URLEncodedString() ?? "",
        ]
      ]
      completion?(.success(response))
    } else if let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion {
      let response: [String: Any] = [
        "id": credential.credentialID.base64URLEncodedString(),
        "rawId": credential.credentialID.base64URLEncodedString(),
        "type": "public-key",
        "response": [
          "clientDataJSON": credential.rawClientDataJSON.base64URLEncodedString(),
          "authenticatorData": credential.rawAuthenticatorData.base64URLEncodedString(),
          "signature": credential.signature.base64URLEncodedString(),
          "userHandle": credential.userID.base64URLEncodedString(),
        ]
      ]
      completion?(.success(response))
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    completion?(.failure(error))
  }
}

@available(iOS 16.0, *)
extension WebAuthnHandler: ASAuthorizationControllerPresentationContextProviding {
  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    return controller.view?.window ?? UIApplication.shared.keyWindow!
  }
}

extension Data {
  func base64URLEncodedString() -> String {
    return self.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }
}
