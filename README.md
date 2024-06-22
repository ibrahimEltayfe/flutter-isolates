# Flutter Isolates

## IsolateExecutor

`IsolateExecutor` provides a high-level API for managing Dart isolates with `Isolate.spawn`. It handles errors gracefully and ensures resources are collected and cleaned up after execution.

### Features

- **Error Handling**: Automatically captures and reports errors occurring within the isolate.
- **Resource Management**: Ensures all resources are properly cleaned up once the isolate finishes execution.
- **Pause and Resume**: Supports pausing and resuming the isolate, allowing for flexible control over its execution.
