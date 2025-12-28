# Prompt Set

[English](#english) | [简体中文](#chinese)

---

<a name="english"></a>

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

---

<a name="chinese"></a>

## 简体中文

Prompt Set 是一款基于 Flutter 开发的桌面原生应用，专为 Prompt 工程师和 AI 开发者设计，用于提示词的存储、调试和管理。它提供了一个安全、高效的环境，助您快速迭代大模型指令。

### 🌟 核心特性

*   **🔒 安全本地存储**: 所有数据均存储在经 **SQLCipher** 加密的本地 SQLite 数据库中。除了请求您配置的模型供应商，您的 API 密钥和提示词永远不会离开您的设备。
*   **🧠 深度模型支持**:
    *   **流式输出**: 实时显示模型响应，提供丝滑的打字机体验。
    *   **思考过程展示**: 完美支持 DeepSeek-R1 (包含 `<think>` 标签) 和 OpenAI o1 系列模型的思考链路显示。
    *   **手动终止**: 随时停止正在运行的请求，节省 Token 和时间。
*   **📸 提示词快照**: 为单个提示词创建多个版本（快照），方便对比不同指令的效果。
*   **⚙️ 多模型独立配置**: 支持为不同模型（如 OpenAI 官方、DeepSeek、本地 Ollama 等）配置独立的 API Key 和接口地址。
*   **🧩 动态参数管理**: 支持在 Prompt 中使用 `{{变量名}}` 语法。参数将自动提取至右侧面板，支持实时编辑与自动保存。
*   **📤 数据管理**: 支持通过 JSON 格式进行完整的备份导出与导入。
*   **💻 桌面原生体验**: 纯正的 macOS 风格 UI，包含毛玻璃效果、原生右键菜单及自定义窗口控制。支持深色和浅色模式切换。

### 🚀 快速上手

#### 环境要求
*   Flutter SDK (^3.10.1)
*   Dart SDK

#### 安装运行
1. 克隆仓库:
   ```bash
   git clone https://github.com/your-repo/prompt-set-client.git
   ```
2. 安装依赖:
   ```bash
   flutter pub get
   ```
3. 运行应用:
   ```bash
   flutter run -d macos # 或 windows
   ```
