import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        application.isIdleTimerDisabled = true
        Task {
            let configuration = Printer.Configuration(
                xAxis: Printer.Configuration.Axis(
                    port: .F,
                    speed: 10,
                    camLength: Measurement(value: 8, unit: .millimeters),
                    startAngle: Measurement(value: 179, unit: .degrees),
                    endAngle: Measurement(value: 0, unit: .degrees),
                    backlashAngle: Measurement(value: -50, unit: .degrees)
                ),
                yAxis: Printer.Configuration.Axis(
                    port: .D,
                    speed: 10,
                    camLength: Measurement(value: 8, unit: .millimeters),
                    startAngle: Measurement(value: 179, unit: .degrees),
                    endAngle: Measurement(value: 0, unit: .degrees),
                    backlashAngle: Measurement(value: -50, unit: .degrees)
                ),
                penAxis: Printer.Configuration.Axis(
                    port: .B,
                    speed: 30,
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

