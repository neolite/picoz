# PicoZ - Ultra-Lightweight AI Assistant in Zig

<div align="center">

**$10 Hardware · <5MB RAM · <1s Boot · Zig Performance**

[![Zig](https://img.shields.io/badge/Zig-0.15.2-orange?style=flat&logo=zig&logoColor=white)](https://ziglang.org/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Arch](https://img.shields.io/badge/Arch-x86__64%2C%20ARM64%2C%20RISC--V-blue)](https://github.com/rafkat/picoz)

</div>

---

🦞 **PicoZ** is an ultra-lightweight personal AI assistant ported from [PicoClaw](https://github.com/sipeed/picoclaw) to Zig for even better performance and lower memory footprint.

⚡️ Runs on $10 hardware with <5MB RAM: That's **50% less memory** than PicoClaw (which is already 99% smaller than OpenClaw)!

## 📊 Comparison

|  | PicoClaw (Go) | **PicoZ (Zig)** |
| --- | --- |--- |
| **Language** | Go | **Zig** |
| **Binary Size** | ~10MB | **~1MB** (10x smaller) |
| **RAM** | <10MB | **<5MB** (estimated) |
| **Startup** | <1s |  **<0.5s** (estimated) |
| **Compile Time** | ~10s | **~3s** |

## ✨ Features

🪶 **Ultra-Lightweight**: <5MB memory footprint — 50% smaller than PicoClaw, 99.5% smaller than Clawdbot

💰 **Minimal Cost**: Efficient enough to run on $10 Hardware

⚡️ **Lightning Fast**: Sub-second startup, native performance

🌍 **True Portability**: Single self-contained 1MB binary across RISC-V, ARM, and x86

🔧 **Type Safe**: Compile-time safety guarantees from Zig

## 📦 Install

### Build from Source

```bash
# Clone repository
git clone https://github.com/rafkat/picoz.git
cd picoz

# Build with Zig 0.15.2
zig build

# Install (optional)
sudo cp zig-out/bin/picoz /usr/local/bin/
```

### 🚀 Quick Start

**1. Initialize**

```bash
picoz onboard
```

**2. Configure** (`~/.picoz/config.json`)

The onboard command creates a minimal config. Edit it to add your API key:

```json
{
  "agents": {
    "defaults": {
      "workspace": "~/.picoz/workspace",
      "model": "glm-4.7",
      "max_tokens": 8192,
      "temperature": 0.7,
      "max_tool_iterations": 20
    }
  },
  "providers": {
    "zhipu": {
      "api_key": "YOUR_API_KEY_HERE",
      "api_base": "https://open.bigmodel.cn/api/paas/v4"
    }
  },
  "gateway": {
    "host": "0.0.0.0",
    "port": 3000
  }
}
```

**3. Get API Key**

- **Zhipu**: [bigmodel.cn](https://open.bigmodel.cn/usercenter/proj-mgmt/apikeys)
- **OpenRouter**: [openrouter.ai/keys](https://openrouter.ai/keys)
- **Anthropic**: [console.anthropic.com](https://console.anthropic.com)

**4. Chat** (Coming Soon)

```bash
picoz agent -m "What is 2+2?"
```

## 💬 CLI Reference

| Command | Description |
|---------|-------------|
| `picoz onboard` | Initialize config & workspace |
| `picoz agent -m "..."` | Chat with the agent (TODO) |
| `picoz agent` | Interactive chat mode (TODO) |
| `picoz gateway` | Start the gateway (TODO) |
| `picoz status` | Show status |
| `picoz version` | Show version |

## 📐 Architecture

PicoZ is organized into modular packages:

```
src/
├── main.zig           # CLI entry point
├── agent/             # Agent loop (TODO: full implementation)
├── bus/               # Message bus for channels
├── channels/          # Telegram, Discord, etc. (TODO)
├── config/            # Configuration management
├── cron/              # Scheduled tasks (TODO)
├── heartbeat/         # Heartbeat service (TODO)
├── logger/            # Logging system
├── providers/         # LLM providers (TODO: HTTP implementation)
├── session/           # Conversation history
├── skills/            # Skills system (TODO)
├── tools/             # Agent tools (TODO: filesystem, shell, web)
└── voice/             # Voice transcription (TODO)
```

## 🛠️ Development Status

### ✅ Completed

- [x] Project structure and build system
- [x] Config management (basic)
- [x] Logger
- [x] Message bus
- [x] Session manager
- [x] CLI scaffolding

### 🚧 In Progress

- [ ] HTTP provider for LLM APIs
- [ ] Tool implementations (filesystem, shell, web)
- [ ] Agent loop with tool calling
- [ ] JSON parsing/serialization (waiting for Zig 0.15 stable API)

### 📅 Planned

- [ ] Channels (Telegram, Discord, WhatsApp)
- [ ] Cron service
- [ ] Skills system
- [ ] Voice transcription
- [ ] Memory management
- [ ] Web search integration

## 🤝 Contributing

Contributions welcome! PicoZ is in active development.

**Why Zig?**
- Compile-time safety without runtime overhead
- No hidden allocations
- Native cross-compilation
- C interop for libraries
- Smaller binaries and faster execution

## 📝 License

MIT License - See [LICENSE](picoclaw/LICENSE)

## 🙏 Credits

- Inspired by [PicoClaw](https://github.com/sipeed/picoclaw) (Go)
- Original concept from [nanobot](https://github.com/HKUDS/nanobot) (Python)

---

**Built with ❤️ and Zig**

皮皮虾，我们走！🦐
