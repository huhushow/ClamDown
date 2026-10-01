import AppKit
import CoreGraphics
import IOKit
import IOKit.pwr_mgt

struct SystemMonitor {
    var isAnyKeyPressed: Bool {
        (0...127).contains { keyCode in
            CGEventSource.keyState(
                .combinedSessionState,
                key: CGKeyCode(keyCode)
            )
        }
    }

    var isLidClosed: Bool {
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPMrootDomain")
        )
        guard service != 0 else { return false }
        defer { IOObjectRelease(service) }

        return IORegistryEntryCreateCFProperty(
            service,
            "AppleClamshellState" as CFString,
            kCFAllocatorDefault,
            0
        )?.takeRetainedValue() as? Bool ?? false
    }

    var hasExternalDisplay: Bool {
        NSScreen.screens.contains { screen in
            guard let screenNumber = screen.deviceDescription[
                NSDeviceDescriptionKey("NSScreenNumber")
            ] as? NSNumber else {
                return false
            }

            return CGDisplayIsBuiltin(CGDirectDisplayID(screenNumber.uint32Value)) == 0
        }
    }

    func requestSystemSleep() -> LocalizedStringResource? {
        let connection = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
        guard connection != 0 else {
            return "Clam Down could not connect to macOS power management."
        }
        defer { IOServiceClose(connection) }

        let result = IOPMSleepSystem(connection)
        guard result == kIOReturnSuccess else {
            return "macOS refused the sleep request (error \(result))."
        }

        return nil
    }
}
