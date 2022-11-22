import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        
        application.isIdleTimerDisabled = true
        Task {
            let configuration = Printer.Configuration(
                xAxis: Printer.Configuration.GearAxis(
                    motor: Printer.Configuration.Motor(
                        port: .C,
                        speed: 75
                    ),
                    ratio: 24,
                    camLength: Measurement(value: 8, unit: .millimeters),
                    resolution: Measurement(value: 180, unit: .degrees),
                    backlash: Measurement(value: 50, unit: .degrees)
                ),
                yAxis: Printer.Configuration.GearAxis(
                    motor: Printer.Configuration.Motor(
                        port: .E,
                        speed: 75
                    ),
                    ratio: 24,
                    camLength: Measurement(value: 8, unit: .millimeters),
                    resolution: Measurement(value: 180, unit: .degrees),
                    backlash: Measurement(value: 50, unit: .degrees)
                ),
                penAxis: Printer.Configuration.CamAxis(
                    motor: Printer.Configuration.Motor(
                        port: .A,
                        speed: 30
                    ),
                    camLength: Measurement(value: 8, unit: .millimeters),
                    startAngle: Measurement(value: 290, unit: .degrees),
                    endAngle: Measurement(value: 330, unit: .degrees),
                    backlashAngle: Measurement(value: 0, unit: .degrees)
                )
            )
            let printer = await Printer(configuration: configuration)
            let viewController = MainViewController(printer: printer)
            let window = UIWindow()
            window.rootViewController = viewController
            window.makeKeyAndVisible()
            self.window = window
        }
        return true
    }

}

