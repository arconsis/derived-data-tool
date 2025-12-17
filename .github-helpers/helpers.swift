
import Foundation

// MARK: - GitHub Summary Helper
public func updateSummary(_ message: String, logOutput: Bool = true) {
	if logOutput {
		if let summaryPath = ProcessInfo.processInfo.environment["GITHUB_STEP_SUMMARY"] {
			let entry = message + "\n"
			if let data = entry.data(using: .utf8) {
				if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: summaryPath)) {
					handle.seekToEndOfFile()
					handle.write(data)
					handle.closeFile()
				} else {
					try? entry.write(toFile: summaryPath, atomically: true, encoding: .utf8)
				}
			}
		}
	}
}

// MARK: - Logging
public func log(_ message: String, prefix: String = "[action]", logOutput: Bool = true) {
	print("\(prefix) \(message)")
}

// MARK: - Error Handling
public func writeStandardError(_ message: String) {
	if let data = (message + "\n").data(using: .utf8) {
		FileHandle.standardError.write(data)
	}
}

public func exitWithError(_ message: String, prefix: String = "[action]") -> Never {
	writeStandardError("❌ \(message)")
	updateSummary("❌ \(message)")
	exit(1)
}

// MARK: - Shell Helpers
@discardableResult
public func system(_ command: String) -> Int32 {
	let task = Process()
	task.executableURL = URL(fileURLWithPath: "/bin/bash")
	task.arguments = ["-c", command]
	try? task.run()
	task.waitUntilExit()
	return task.terminationStatus
}

public func shellOutput(_ command: String) -> String {
	let task = Process()
	task.launchPath = "/bin/bash"
	task.arguments = ["-c", command]
	let pipe = Pipe()
	task.standardOutput = pipe
	task.launch()
	let data = pipe.fileHandleForReading.readDataToEndOfFile()
	task.waitUntilExit()
	return String(data: data, encoding: .utf8) ?? ""
}

// MARK: - Run Shell with Summary
public func runShell(_ command: String, logOutput: Bool = true) {
	let task = Process()
	task.executableURL = URL(fileURLWithPath: "/bin/bash")
	task.arguments = ["-c", command]
	try? task.run()
	task.waitUntilExit()
	if task.terminationStatus == 0 {
		updateSummary("✅ \(command)", logOutput: logOutput)
	} else {
		updateSummary("❌ Command failed: \(command)", logOutput: logOutput)
		exitWithError("Command failed: \(command)")
	}
}

