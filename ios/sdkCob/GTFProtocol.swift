import UIKit

public protocol GTFLauncherProtocol {
    func launchGTF(from viewController: UIViewController, completion: @escaping (Bool) -> Void)
}
