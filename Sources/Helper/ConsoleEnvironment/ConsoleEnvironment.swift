//
//  ConsoleEnvironment.swift
//  CodeCoverage
//
//  Created by Moritz Ellerbrock on 20.08.25.
//


// Environment.swift
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif
import Foundation

public typealias CE = ConsoleEnvironment

public enum ConsoleEnvironment {
    /// True when stdout/stderr are attached to an interactive terminal.
    /// (In Xcode this is usually false; in a real terminal it's true unless piped.)
    static var isTTY: Bool {
        let outIsTTY = isatty(fileno(stdout)) != 0
        let errIsTTY = isatty(fileno(stderr)) != 0
        return outIsTTY || errIsTTY
    }

    /// Heuristic: common CI systems set CI=1.
    static var isCI: Bool {
        ProcessInfo.processInfo.environment["CI"] != nil
    }

    /// True if a debugger (e.g. LLDB from Xcode) is attached.
    static var isDebuggerAttached: Bool {
        #if canImport(Darwin)
        // sysctl(KERN_PROC, KERN_PROC_PID, getpid(), ...) → kinfo_proc.kp_proc.p_flag & P_TRACED
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        let mibCount = u_int(mib.count) // <-- precompute to avoid overlapping access
        
        let result = mib.withUnsafeMutableBufferPointer { buf -> Int32 in
            sysctl(buf.baseAddress, mibCount, &info, &size, nil, 0)
        }
        if result != 0 { return false }
        return (info.kp_proc.p_flag & P_TRACED) != 0
        #else
        // Portable fallback: assume no debugger.
        return false
        #endif
    }

    /// Best-effort hint that you were launched by Xcode (not guaranteed).
    /// Useful if you really need to special-case Xcode runs.
    static var probablyFromXcode: Bool {
        let env = ProcessInfo.processInfo.environment
        if env["OS_ACTIVITY_DT_MODE"] == "YES" { return true }          // Xcode often sets this
        if let svc = env["XPC_SERVICE_NAME"], svc.contains("Xcode") { return true }
        return false
    }

    /// Should we show “live” progress (carriage-return updates) instead of plain logs?
    static var shouldUseProgressUI: Bool {
        // Only when interactive, not in CI, and preferably not under a debugger.
        return isTTY && !isCI && !isDebuggerAttached
    }
}
