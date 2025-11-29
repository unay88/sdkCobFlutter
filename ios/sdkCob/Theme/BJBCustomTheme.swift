import UIKit
import DigitalIdentity

public class BJBThemeHelper {
    public static func createCustomTheme() -> DigitalIdentityKYCVerificationFlowTheme {
        let yellowThemeColor = DigitalIdentityColorToken(
            name: "",
            light: DigitalIdentityThemeColor(red: 255, green: 201, blue: 69),
            dark: DigitalIdentityThemeColor(red: 255, green: 201, blue: 69)
        )
        
        let deepBlueThemeColor = DigitalIdentityColorToken(
            name: "",
            light: DigitalIdentityThemeColor(red: 26, green: 90, blue: 134),
            dark: DigitalIdentityThemeColor(red: 26, green: 90, blue: 134)
        )
        
        let lightGreyThemeColor = DigitalIdentityColorToken(
            name: "",
            light: DigitalIdentityThemeColor(red: 241, green: 242, blue: 244),
            dark: DigitalIdentityThemeColor(red: 241, green: 242, blue: 244)
        )
        
        let whiteThemeColor = DigitalIdentityColorToken(
            name: "Artboard/Light/Surface Default",
            light: DigitalIdentityThemeColor(red: 255, green: 255, blue: 255),
            dark: DigitalIdentityThemeColor(red: 255, green: 255, blue: 255)
        )
        
        let blackThemeColor = DigitalIdentityColorToken(
            name: "",
            light: DigitalIdentityThemeColor(red: 0, green: 0, blue: 0),
            dark: DigitalIdentityThemeColor(red: 0, green: 0, blue: 0)
        )
        
        let descriptionTextColor = DigitalIdentityColorToken(
            name: "",
            light: DigitalIdentityThemeColor(red: 73, green: 74, blue: 74, alpha: 1),
            dark: DigitalIdentityThemeColor(red: 73, green: 74, blue: 74, alpha: 1)
        )
        
        let shadowLowColor = DigitalIdentityColorToken(
            name: "shadow_low_color",
            light: DigitalIdentityThemeColor((0.0, 0.0, 0.0, 0.149)),
            dark: DigitalIdentityThemeColor((0.0, 0.0, 0.0, 0.149)),
            lightHC: DigitalIdentityThemeColor((0.0, 0.0, 0.0, 0.149)),
            darkHC: DigitalIdentityThemeColor((0.0, 0.0, 0.0, 0.149))
        )
        
        let shadowLowToken = DigitalIdentityShadowToken(
            name: "shadow_low",
            blur: 4,
            color: shadowLowColor,
            x: 0,
            y: 0
        )
        
        func getPrimaryCTATheme() -> DigitalIdentityThemeToken {
            return DigitalIdentityThemeToken(
                textColor: deepBlueThemeColor,
                backgroundColor: yellowThemeColor
            )
        }
        
        func getSecondaryCTATheme() -> DigitalIdentityThemeToken {
            return DigitalIdentityThemeToken(
                textColor: deepBlueThemeColor,
                backgroundColor: whiteThemeColor,
                borderColor: yellowThemeColor
            )
        }
        
        func getCloseButtonTheme() -> DigitalIdentityThemeToken {
            return DigitalIdentityThemeToken(
                backgroundColor: whiteThemeColor,
                tintColor: descriptionTextColor,
                shadowColor: shadowLowToken
            )
        }
        
        func getDialogTheme() -> DigitalIdentityDialogTheme {
            return DigitalIdentityDialogTheme(
                closeButton: getCloseButtonTheme(),
                card: DigitalIdentityThemeToken(backgroundColor: whiteThemeColor),
                title: DigitalIdentityThemeToken(textColor: blackThemeColor),
                description: DigitalIdentityThemeToken(textColor: descriptionTextColor),
                primaryCTA: getPrimaryCTATheme(),
                secondaryCTA: getSecondaryCTATheme()
            )
        }
        
        func getGuidelineTheme() -> DigitalIdentityGuidelineScreenTheme {
            return DigitalIdentityGuidelineScreenTheme(
                background: DigitalIdentityThemeToken(backgroundColor: whiteThemeColor),
                closeButton: getCloseButtonTheme(),
                guideline: DigitalIdentityGuidelineScreenTheme.Guideline(
                    autoCaptureTitle: DigitalIdentityThemeToken(textColor: blackThemeColor),
                    manualCaptureTitle: DigitalIdentityThemeToken(textColor: blackThemeColor),
                    autoCaptureInfoView: DigitalIdentityThemeToken(backgroundColor: lightGreyThemeColor),
                    autoCaptureInfoTitle: DigitalIdentityThemeToken(textColor: blackThemeColor),
                    autoCaptureInfoDescription: DigitalIdentityThemeToken(textColor: blackThemeColor),
                    autoCaptureInstructions: DigitalIdentityThemeToken(textColor: blackThemeColor),
                    manualCaptureInstructions: DigitalIdentityThemeToken(textColor: blackThemeColor),
                    bulletPoint: DigitalIdentityThemeToken(tintColor: lightGreyThemeColor)
                )
            )
        }
        
        let termsTitle = DigitalIdentityThemeToken(textColor: descriptionTextColor, highlightTextColor: deepBlueThemeColor)
        
        let onboardingScreenTheme = DigitalIdentityOnboardingScreenTheme(
            background: DigitalIdentityThemeToken(backgroundColor: lightGreyThemeColor),
            backButton: getCloseButtonTheme(),
            card: DigitalIdentityThemeToken(backgroundColor: whiteThemeColor, shadowColor: shadowLowToken),
            title: DigitalIdentityThemeToken(textColor: blackThemeColor),
            ktpInstructionImage: DigitalIdentityThemeToken(backgroundColor: lightGreyThemeColor),
            otherInstructions: [
                DigitalIdentityKYCWidgetInstructionTheme(background: DigitalIdentityThemeToken(
                    backgroundColor: whiteThemeColor,
                    borderColor: lightGreyThemeColor
                ), description: DigitalIdentityThemeToken(textColor: descriptionTextColor)),
                DigitalIdentityKYCWidgetInstructionTheme(background: DigitalIdentityThemeToken(
                    backgroundColor: whiteThemeColor,
                    borderColor: lightGreyThemeColor
                ), description: DigitalIdentityThemeToken(textColor: descriptionTextColor))
            ],
            footerView: DigitalIdentityThemeToken(
                backgroundColor: whiteThemeColor,
                shadowColor: shadowLowToken
            ),
            termsInfo: DigitalIdentityTermsAndPrivacyPolicyTheme(
                title: termsTitle,
                termsUrl: "",
                privacyUrl: ""
            ),
            captureButton: getPrimaryCTATheme()
        )
        
        let changeCaptureModeTheme = getDialogTheme()
        
        let selfieTheme = DigitalIdentitySelfieCameraScreenTheme(
            viewGuide: DigitalIdentityThemeToken(textColor: deepBlueThemeColor),
            prepareCard: DigitalIdentitySelfiePrepareCardTheme(
                background: DigitalIdentityThemeToken(backgroundColor: whiteThemeColor),
                title: DigitalIdentityThemeToken(textColor: blackThemeColor),
                infoItems: [
                    DigitalIdentityThemeToken(textColor: blackThemeColor),
                    DigitalIdentityThemeToken(textColor: blackThemeColor),
                    DigitalIdentityThemeToken(textColor: blackThemeColor)
                ],
                defaultCTA: getPrimaryCTATheme(),
                primaryCTA: getPrimaryCTATheme(),
                secondaryCTA: getSecondaryCTATheme()
            ),
            captureExhausted: DigitalIdentitySelfieCaptureExhaustedCardTheme(
                closeButton: getCloseButtonTheme(),
                background: DigitalIdentityThemeToken(backgroundColor: whiteThemeColor),
                title: DigitalIdentityThemeToken(textColor: blackThemeColor),
                infoItems: [
                    DigitalIdentityThemeToken(textColor: blackThemeColor),
                    DigitalIdentityThemeToken(textColor: blackThemeColor),
                    DigitalIdentityThemeToken(textColor: blackThemeColor)
                ],
                primaryCTA: getPrimaryCTATheme(),
                secondaryCTA: getSecondaryCTATheme()
            )
        )
        
        let cameraTheme = DigitalIdentityCameraScreenTheme(
            progressBar: DigitalIdentityThemeToken(tintColor: yellowThemeColor),
            ktp: DigitalIdentityKTPCameraScreenTheme(
                background: DigitalIdentityThemeToken(backgroundColor: blackThemeColor),
                changeCaptureMode: changeCaptureModeTheme
            ),
            selfie: selfieTheme
        )
        
        let nonRetryableErrorTheme = getDialogTheme()
        let retryableErrorTheme = getDialogTheme()
        let noInternetTheme = getDialogTheme()
        let cameraHardwareErrorTheme = getDialogTheme()
        let cameraPermissionTheme = getDialogTheme()
        
        return DigitalIdentityKYCVerificationFlowTheme(
            onboarding: onboardingScreenTheme,
            camera: cameraTheme,
            ktpGuideline: getGuidelineTheme(),
            selfieGuideline: getGuidelineTheme(),
            uploadStatus: DigitalIdentityDocumentUploadStatusScreenTheme(
                uploadingCard: DigitalIdentityDocumentUploadStatusCard(spinner: DigitalIdentityThemeToken(tintColor: deepBlueThemeColor))),
            commonDialog: DigitalIdentityCommonDialogTheme(
                nonretryableError: nonRetryableErrorTheme,
                retryableError: retryableErrorTheme,
                noInternet: noInternetTheme,
                cameraHardwareError: cameraHardwareErrorTheme,
                cameraSetupProgress: DigitalIdentityProgressCardTheme(
                    closeButton: getCloseButtonTheme(),
                    card: DigitalIdentityThemeToken(backgroundColor: whiteThemeColor),
                    title: DigitalIdentityThemeToken(textColor: blackThemeColor),
                    description: DigitalIdentityThemeToken(textColor: descriptionTextColor),
                    progressBar: DigitalIdentityThemeToken(tintColor: yellowThemeColor)
                ),
                cameraPermission: cameraPermissionTheme
            ),
            loadingSpinnerColor: deepBlueThemeColor
        )
    }
}
