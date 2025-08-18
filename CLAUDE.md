# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **GrowingIO HarmonyOS NEXT SDK** - an analytics SDK for HarmonyOS applications that automatically tracks user interactions and supports manual event tracking. It's based on OpenHarmony API 12 and supports HarmonyOS NEXT.

该项目使用 ArkTS 语言编写，如果出现编译错误，特别是语法错误，可以查看 docs/typescript-to-arkts-migration-guide.md 了解 TypeScript 与 ArkTS 之间的不同。

## Build System & Project Structure

This is a **HarmonyOS** project using the **hvigor** build system. The project follows HarmonyOS module structure:

- **Root project**: Contains build configuration and dependencies
- **GrowingAnalytics**: Main SDK module (HAR library)
- **GrowingToolsKit**: Developer tools and debugging utilities (HAR library) 
- **entry**: Example application demonstrating SDK usage

### Key Build Files
- `hvigorfile.ts`: Main build configuration
- `build-profile.json5`: Project-level build profiles defining modules and build modes
- `oh-package.json5`: HarmonyOS package manager configuration (equivalent to package.json)

## Common Commands

### Building the Project
```bash
# Build in debug mode(Default)
# entry
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon

# GrowingAnalytics
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p product=default -p module=GrowingAnalytics@default assembleHar --analyze=normal --parallel --incremental --daemon

# GrowingToolsKit
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p product=default -p module=GrowingToolsKit@default assembleHar --analyze=normal --parallel --incremental --daemon
```

> add `-p buildMode=release` for building in release mode


### Development Tools
```bash
# Clean build artifacts
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js -p product=default clean --analyze=normal --parallel --incremental --daemon
```

## Architecture Overview

### Core SDK Architecture (GrowingAnalytics)

**Event Flow**: User Action → Autotrack/Manual Track → Event Creation → Database Storage → Network Upload

**Key Components**:

1. **Core System** (`src/main/ets/components/core/`):
   - `AnalyticsCore.ets`: Main SDK entry point and lifecycle management
   - `Context.ets`: Configuration and runtime context management  
   - `Session.ets`: User session tracking and management
   - `EventTimer.ets`: Event timing functionality
   - `Network.ets`: HTTP request handling and data upload

2. **Event System** (`src/main/ets/components/event/`):
   - `EventDatabase.ets`: SQLite-based event persistence with caching
   - `EventSender.ets`: Batched event upload with retry logic
   - `Event.ets`: Base event types and event builder pattern
   - Event types: `VisitEvent`, `PageEvent`, `CustomEvent`, `ViewElementEvent`

3. **Auto-tracking** (`src/main/ets/components/autotrack/`):
   - `Autotrack.ets`: Automatic user interaction tracking
   - `AutotrackPage.ets`: Page view tracking
   - `AutotrackClick.ets`: Click event tracking

4. **Multi-tracker Support**:
   - Main tracker + sub-trackers with independent configurations
   - Event forwarding between trackers via `sendTo` parameter

### Tools & Debugging (GrowingToolsKit)

Developer utilities for SDK debugging:
- Real-time event monitoring
- Network request inspection  
- SDK configuration viewer
- Event database browser

### Dependencies

**Core Dependencies**:
- `@ohos/protobufjs`: Protocol buffer serialization
- `snappyjs`: Data compression
- `long`: 64-bit integer support

## Development Notes

### File Naming Conventions
- `.ets` files: ArkTS (HarmonyOS TypeScript variant)
- `.ts` files: Standard TypeScript utilities
- `BuildProfile.ets`: Module build configuration

### Testing Structure
- `src/ohosTest/`: Integration tests
- `src/test/`: Unit tests  
- Uses `@ohos/hypium` testing framework

### Configuration
- Module configurations in `module.json5`
- Permissions defined in module manifests
- Build variants: debug/release

### SDK Integration Pattern
```typescript
// Initialize in AbilityStage.onCreate()
let config = new GrowingConfig().NewSaaS(accountId, dataSourceId, urlScheme)
GrowingAnalytics.start(this.context, config)

// Track custom events
GrowingAnalytics.track('eventName', { key: 'value' })
```

### Hybrid Integration
- WebView integration for H5 tracking
- JavaScript bridge via `createHybridProxy()`
- Requires corresponding Web JS SDK integration