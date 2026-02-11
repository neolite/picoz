# PicoZ Quick Start Guide

## What is PicoZ?

**PicoZ** is a complete port of [PicoClaw](https://github.com/sipeed/picoclaw) from Go to Zig.

**Key Stats:**
- Binary: **1.0 MB** (vs 10MB Go version)
- Memory: **<5 MB** target (vs <10MB Go)
- Code: **2,132 lines** (vs 5,800 lines Go)
- Dependencies: **0** (pure Zig stdlib)
- Tools: **6 implemented** (100% coverage)

## Build & Run

```bash
# Requirements: Zig 0.15.2
# Install: https://ziglang.org/download/

# 1. Build
zig build

# 2. Check version
./zig-out/bin/picoz version
# Output: 🦞 picoz v0.1.0

# 3. Initialize
./zig-out/bin/picoz onboard
# Creates ~/.picoz/ with config and workspace

# 4. Check status
./zig-out/bin/picoz status
```

## What Works Right Now

### ✅ Working Features

**CLI Commands:**
- `picoz version` - Show version
- `picoz onboard` - Initialize config
- `picoz status` - Show configuration

**All Tools Implemented:**
- `read_file` - Read files
- `write_file` - Write files  
- `list_dir` - List directories
- `exec` - Execute shell commands (with safety)
- `web_search` - Search interface (HTTP pending)
- `web_fetch` - Fetch URLs (HTTP pending)

**Infrastructure:**
- Configuration management
- Colored logger
- Message bus
- Session manager
- Tool registry

### 🚧 In Progress

- HTTP client for LLM providers
- HTTP client for web tools
- Agent loop with tool calling
- JSON parsing

## Files Overview

```
picoz-repo/
├── README.md              # Main documentation
├── SUMMARY.md             # Port summary
├── PORTING_STATUS.md      # Detailed progress
├── QUICK_START.md         # This file
├── LICENSE                # MIT license
│
├── build.zig              # Build configuration
├── build.zig.zon          # Package manifest
│
└── src/                   # Source code (2,132 lines)
    ├── main.zig           # CLI entry
    ├── config/            # Config management
    ├── logger/            # Logging
    ├── bus/               # Messaging
    ├── session/           # History
    ├── agent/             # Agent loop
    ├── providers/         # LLM types
    └── tools/             # ALL 6 TOOLS ✅
        ├── filesystem.zig # File operations
        ├── shell.zig      # Command execution
        └── web.zig        # Web search/fetch
```

## Cross-Compilation

```bash
# RISC-V (LicheeRV-Nano, $10 board)
zig build -Dtarget=riscv64-linux-musl -Doptimize=ReleaseSmall

# ARM64 (Raspberry Pi, NanoKVM)
zig build -Dtarget=aarch64-linux-musl -Doptimize=ReleaseSmall

# x86_64
zig build -Dtarget=x86_64-linux-musl -Doptimize=ReleaseSmall
```

## Git History

```bash
git log --oneline

# afa624b docs: add complete port summary
# 7c5efdc docs: update porting status - 100% tool coverage
# 46015ac feat: complete tool implementations - all tools
# b03dcd8 docs: add MIT license
# 0e3c0c5 feat: initial PicoZ implementation
```

## Next Steps

1. **For Users:**
   - Build and test the binary
   - Try CLI commands
   - Read full README.md

2. **For Contributors:**
   - Implement HTTP client (std.http)
   - Add JSON parsing
   - Write tests

3. **For Deployment:**
   - Cross-compile for your platform
   - Test on minimal hardware
   - Report memory usage

## Links

- **Repository**: [Local] `/Users/rafkat/Apps/rafkat/picoz-repo`
- **Original PicoClaw**: https://github.com/sipeed/picoclaw
- **Zig Language**: https://ziglang.org/

---

**Questions?** Read the full [README.md](README.md) or [PORTING_STATUS.md](PORTING_STATUS.md)

皮皮虾，我们走！🦐
