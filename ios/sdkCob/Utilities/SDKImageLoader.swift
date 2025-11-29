import SwiftUI

private class SDKBundleMarker {}

@available(iOS 13.0, *)
public func SDKImage(_ name: String) -> Image {
    // Try resource bundle first
    let bundlePath = Bundle(for: SDKBundleMarker.self).path(forResource: "bjb_cob_sdk_assets", ofType: "bundle")
    let resourceBundle = bundlePath.flatMap(Bundle.init(path:))
    
    // Fallback to main bundle if resource bundle not found
    let bundle = resourceBundle ?? Bundle.main
    return Image(name, bundle: bundle)
}
