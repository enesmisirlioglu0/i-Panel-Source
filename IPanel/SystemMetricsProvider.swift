//
//  SystemMetricsProvider.swift
//  i-Panel
//
//  Reads public, local macOS system statistics. No network connection,
//  account, hardware-control command, or user-granted privacy permission is
//  required for these read-only measurements.
//

import Darwin
import Foundation
import IOKit.ps

struct SystemMetricsSnapshot {
    let cpuUsage: Double?
    let memory: CapacityMetrics?
    let disk: CapacityMetrics?
    let battery: BatteryState
    let network: NetworkRateMetrics?
}

struct CapacityMetrics {
    let usedBytes: Int64
    let totalBytes: Int64

    var usageFraction: Double {
        guard totalBytes > 0 else {
            return 0
        }

        return min(max(Double(usedBytes) / Double(totalBytes), 0), 1)
    }
}

struct BatteryMetrics {
    let level: Double
    let status: String
}

enum BatteryState {
    case available(BatteryMetrics)
    case notPresent
    case unavailable
}

struct NetworkRateMetrics {
    let downloadBytesPerSecond: Double
    let uploadBytesPerSecond: Double
}

struct SystemMetricsProvider {
    private var previousCPUCounters: CPUCounters?
    private var previousNetworkCounters: NetworkCounters?
    private var previousNetworkUptime: TimeInterval?

    mutating func sample() -> SystemMetricsSnapshot {
        SystemMetricsSnapshot(
            cpuUsage: cpuUsage(),
            memory: memoryMetrics(),
            disk: diskMetrics(),
            battery: batteryState(),
            network: networkRateMetrics()
        )
    }

    private mutating func cpuUsage() -> Double? {
        guard let current = cpuCounters() else {
            return nil
        }

        defer {
            previousCPUCounters = current
        }

        guard let previous = previousCPUCounters,
              let totalDelta = current.total.subtracting(previous.total),
              let idleDelta = current.idle.subtracting(previous.idle),
              totalDelta > 0 else {
            return nil
        }

        let busyDelta = totalDelta > idleDelta ? totalDelta - idleDelta : 0
        return min(max(Double(busyDelta) / Double(totalDelta), 0), 1)
    }

    private func cpuCounters() -> CPUCounters? {
        var info = host_cpu_load_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<host_cpu_load_info_data_t>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return nil
        }

        return CPUCounters(
            user: UInt64(info.cpu_ticks.0),
            system: UInt64(info.cpu_ticks.1),
            idle: UInt64(info.cpu_ticks.2),
            nice: UInt64(info.cpu_ticks.3)
        )
    }

    private func memoryMetrics() -> CapacityMetrics? {
        var statistics = vm_statistics64_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64_data_t>.size / MemoryLayout<integer_t>.size
        )

        let result = withUnsafeMutablePointer(to: &statistics) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        guard result == KERN_SUCCESS else {
            return nil
        }

        let totalBytes = ProcessInfo.processInfo.physicalMemory
        let usedPages = UInt64(statistics.active_count)
            + UInt64(statistics.inactive_count)
            + UInt64(statistics.wire_count)
            + UInt64(statistics.compressor_page_count)
        let usedBytes = min(usedPages * UInt64(vm_kernel_page_size), totalBytes)

        return CapacityMetrics(
            usedBytes: Int64(usedBytes),
            totalBytes: Int64(totalBytes)
        )
    }

    private func diskMetrics() -> CapacityMetrics? {
        let homeURL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)

        if let values = try? homeURL.resourceValues(
            forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ]
        ),
           let total = values.volumeTotalCapacity,
           let available = values.volumeAvailableCapacityForImportantUsage {
            return capacityMetrics(total: Int64(total), available: Int64(available))
        }

        guard let attributes = try? FileManager.default.attributesOfFileSystem(
            forPath: NSHomeDirectory()
        ),
              let total = (attributes[.systemSize] as? NSNumber)?.int64Value,
              let available = (attributes[.systemFreeSize] as? NSNumber)?.int64Value else {
            return nil
        }

        return capacityMetrics(total: total, available: available)
    }

    private func capacityMetrics(total: Int64, available: Int64) -> CapacityMetrics? {
        guard total > 0 else {
            return nil
        }

        let used = min(max(total - available, 0), total)
        return CapacityMetrics(usedBytes: used, totalBytes: total)
    }

    private func batteryState() -> BatteryState {
        guard let powerSourcesInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let powerSources = IOPSCopyPowerSourcesList(powerSourcesInfo)?
                .takeRetainedValue() as? [CFTypeRef] else {
            return .unavailable
        }

        for powerSource in powerSources {
            guard let description = IOPSGetPowerSourceDescription(powerSourcesInfo, powerSource)?
                .takeUnretainedValue() as? NSDictionary,
                  description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType,
                  let currentCapacity = (description[kIOPSCurrentCapacityKey] as? NSNumber)?.doubleValue,
                  let maximumCapacity = (description[kIOPSMaxCapacityKey] as? NSNumber)?.doubleValue,
                  maximumCapacity > 0 else {
                continue
            }

            let level = min(max(currentCapacity / maximumCapacity, 0), 1)
            let isCharging = (description[kIOPSIsChargingKey] as? NSNumber)?.boolValue ?? false
            let isCharged = (description[kIOPSIsChargedKey] as? NSNumber)?.boolValue ?? false
            let sourceState = description[kIOPSPowerSourceStateKey] as? String

            let status: String
            if isCharging {
                status = "Şarj oluyor"
            } else if isCharged {
                status = "Tam dolu"
            } else if sourceState == kIOPSACPowerValue {
                status = "Güç adaptörü"
            } else if sourceState == kIOPSBatteryPowerValue {
                status = "Batarya kullanılıyor"
            } else {
                status = "Bağlı"
            }

            return .available(BatteryMetrics(level: level, status: status))
        }

        return .notPresent
    }

    private mutating func networkRateMetrics() -> NetworkRateMetrics? {
        guard let current = networkCounters() else {
            return nil
        }

        let currentUptime = ProcessInfo.processInfo.systemUptime
        defer {
            previousNetworkCounters = current
            previousNetworkUptime = currentUptime
        }

        guard let previous = previousNetworkCounters,
              let previousUptime = previousNetworkUptime,
              currentUptime > previousUptime,
              let receivedDelta = current.received.subtracting(previous.received),
              let sentDelta = current.sent.subtracting(previous.sent) else {
            return nil
        }

        let elapsed = currentUptime - previousUptime
        return NetworkRateMetrics(
            downloadBytesPerSecond: Double(receivedDelta) / elapsed,
            uploadBytesPerSecond: Double(sentDelta) / elapsed
        )
    }

    private func networkCounters() -> NetworkCounters? {
        var interfaces: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&interfaces) == 0,
              let firstInterface = interfaces else {
            return nil
        }

        defer {
            freeifaddrs(firstInterface)
        }

        var received: UInt64 = 0
        var sent: UInt64 = 0
        var currentInterface: UnsafeMutablePointer<ifaddrs>? = firstInterface

        while let interface = currentInterface {
            let entry = interface.pointee
            let flags = Int32(entry.ifa_flags)

            if entry.ifa_addr?.pointee.sa_family == UInt8(AF_LINK),
               (flags & IFF_UP) != 0,
               (flags & IFF_LOOPBACK) == 0,
               let data = entry.ifa_data {
                let interfaceData = data.assumingMemoryBound(to: if_data.self).pointee
                received += UInt64(interfaceData.ifi_ibytes)
                sent += UInt64(interfaceData.ifi_obytes)
            }

            currentInterface = entry.ifa_next
        }

        return NetworkCounters(received: received, sent: sent)
    }
}

private struct CPUCounters {
    let user: UInt64
    let system: UInt64
    let idle: UInt64
    let nice: UInt64

    var total: UInt64 {
        user + system + idle + nice
    }
}

private struct NetworkCounters {
    let received: UInt64
    let sent: UInt64
}

private extension UInt64 {
    func subtracting(_ previous: UInt64) -> UInt64? {
        guard self >= previous else {
            return nil
        }

        return self - previous
    }
}
