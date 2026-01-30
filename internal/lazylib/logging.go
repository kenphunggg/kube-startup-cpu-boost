package lazylib

import "fmt"

// --- ANSI Color Codes (Private constants) ---
const (
	colorReset  = "\033[0m"
	colorRed    = "\033[31m" // Error
	colorGreen  = "\033[32m" // Info
	colorYellow = "\033[33m" // Warning
)

// LogInfo prints a green log message
// Usage: LazyLib.LogInfo("System ready")
func LogInfo(v ...interface{}) {
	printWithColor(colorGreen, "[INFO] ", v...)
}

// LogWarning prints a yellow log message
// Usage: LazyLib.LogWarning("Disk almost full")
func LogWarning(v ...interface{}) {
	printWithColor(colorYellow, "[WARN] ", v...)
}

// LogError prints a red log message
// Usage: LazyLib.LogError("Connection failed")
func LogError(v ...interface{}) {
	printWithColor(colorRed, "[ERR]  ", v...)
}

// LogNormal prints a standard log message without color
// Usage: LazyLib.LogNormal("Just a normal message")
func LogNormal(v ...interface{}) {
	fmt.Println(v...)
}

// --- Internal Helper (Private) ---
// This function is not exported (lowercase 'p'), so it can only be used inside this file.
func printWithColor(colorCode string, prefix string, v ...interface{}) {
	// Sprintln handles the spacing between arguments automatically
	msg := fmt.Sprintln(v...)

	// Remove the extra newline added by Sprintln so we can control the reset code
	if len(msg) > 0 {
		msg = msg[:len(msg)-1]
	}

	fmt.Println(colorCode + prefix + msg + colorReset)
}
