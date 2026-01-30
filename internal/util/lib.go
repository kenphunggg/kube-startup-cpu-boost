// --- Global Instance for "Static" usage ---
var LazyLog = &lazyLogger{}

// --- Implementation ---
type lazyLogger struct{}

// ANSI Color Codes
const (
	ColorReset  = "\033[0m"
	ColorRed    = "\033[31m" // Error
	ColorGreen  = "\033[32m" // Info
	ColorYellow = "\033[33m" // Warning
)

// Info prints a green log message
func (l *lazyLogger) Info(v ...interface{}) {
	l.printWithColor(ColorGreen, "[INFO] ", v...)
}

// Warning prints a yellow log message
func (l *lazyLogger) Warning(v ...interface{}) {
	l.printWithColor(ColorYellow, "[WARN] ", v...)
}

// Error prints a red log message
func (l *lazyLogger) Error(v ...interface{}) {
	l.printWithColor(ColorRed, "[ERR]  ", v...)
}

// Normal prints a standard log message
func (l *lazyLogger) Normal(v ...interface{}) {
	fmt.Println(v...)
}
