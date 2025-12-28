# Prompt Set

[简体中文](./README_zh.md)

---

## English

Prompt Set is a native desktop application built with Flutter, designed for professional prompt engineering, debugging, and management. It provides a secure, efficient environment to iterate on your LLM prompts.

### 🌟 Key Features

*   **🔒 Secure Local Storage**: All data is stored in a local SQLite database encrypted with **SQLCipher**. Your API keys and prompts never leave your machine except to the model providers you configure.
*   **🧠 Advanced Model Support**:
    *   **Streaming Output**: Real-time response display for a fluid experience.
    *   **Reasoning Display**: Supports specialized "Thinking" process display for models like DeepSeek-R1 and OpenAI o1.
    *   **Manual Termination**: Stop a running request at any time to save tokens and time.
*   **📸 Prompt Snapshots**: Create multiple versions (snapshots) for a single prompt to compare and iterate.
*   **⚙️ Multi-Model Configuration**: Configure independent API keys and Base URLs for different models (OpenAI, DeepSeek, Ollama, etc.).
*   **🧩 Parameter Management**: Use `{{variable}}` syntax in your prompts. Parameters are automatically extracted, editable in a side panel, and auto-saved.
*   **📤 Data Management**: Export and import your entire library via JSON backups.
*   **💻 Native Desktop Experience**: macOS-style UI with frosted glass effects, context menus, and custom window controls. Supports both Light and Dark modes.

### 🚀 Getting Started

#### Prerequisites
*   Flutter SDK (^3.10.1)
*   Dart SDK

#### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/prompt-set-client.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run -d macos # or windows
   ```
