# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **GrowingIO HarmonyOS SDK** repository, a data analytics SDK for HarmonyOS applications. The project contains:

- **GrowingAnalytics** (`@growingio/analytics` v2.7.1): Core analytics SDK module for event tracking and data collection
- **GrowingToolsKit** (`@growingio/tools` v1.4.0): Developer tools and debugging utilities for the SDK
- **entry**: Demo application showcasing SDK integration and usage

The SDK supports HarmonyOS with OpenHarmony API 12 (compatibleSdkVersion: 5.0.0) and targetSdkVersion 6.0.0(20), providing automatic event collection plus manual tracking APIs.

## Build System & Commands

This project uses HarmonyOS's **hvigor** build system with the following key commands:

### Development Commands
```bash
# Build in debug mode (Default)
# entry
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon

# GrowingAnalytics
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p product=default -p module=GrowingAnalytics@default assembleHar --analyze=normal --parallel --incremental --daemon

# GrowingToolsKit
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p product=default -p module=GrowingToolsKit@default assembleHar --analyze=normal --parallel --incremental --daemon

# Clean build artifacts
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js -p product=default clean --analyze=normal --parallel --incremental --daemon
```

> Add `-p buildMode=release` for building in release mode

### Package Management
```bash
# Install dependencies via OHPM (OpenHarmony Package Manager)
ohpm install

# Install from OHPM registry
ohpm install @growingio/analytics

# Install from local HAR file
ohpm install <path-to-har-file>
```

## Architecture & Module Structure

### Core Modules

#### GrowingAnalytics (`/GrowingAnalytics/`)
- **Main API**: `GrowingAnalytics` class in `src/main/ets/components/interfaces/GrowingAnalytics.ets`
- **Core Engine**: `AnalyticsCore.ets` - central SDK management and lifecycle
- **Event System**: `src/main/ets/components/event/` - event creation, persistence, and sending
- **Database**: `EventDatabase.ets` - SQLite-based event storage with concurrent processing
- **Configuration**: `GrowingConfig.ets` - SDK configuration management
- **Auto-tracking**: `src/main/ets/components/autotrack/` - automatic UI event collection (page views, clicks)
- **Hybrid**: `Hybrid.ets` - WebView integration for H5 page tracking
- **Flutter**: `Flutter.ets` - Flutter platform channel support
- **Circle**: `Circle.ets`, `CircleElement.ets` - Visual circle selection for tracking
- **Mobile Debugger**: `MobileDebugger/` - Real-time debugging via WebSocket

#### GrowingToolsKit (`/GrowingToolsKit/`)
- **Debug Tools**: Developer debugging utilities (network monitoring, event inspection)
- **Event Inspection**: `EventsList.ets` - View tracked events
- **Network Monitoring**: `NetFlow.ets` - Monitor SDK network requests
- **Real-time Events**: `Realtime.ets` - Real-time event stream
- **SDK Info**: `SdkInfo.ets` - Display SDK configuration and status
- **UI Components**: Debug interface pages and views

### Key Technical Components

#### Event Processing Pipeline
1. **Event Creation**: Events created via APIs or auto-tracking
2. **Event Database**: SQLite storage with concurrent task processing using `@ohos.taskpool`
3. **Event Sender**: Network transmission with configurable intervals
4. **Event Persistence**: Protobuf serialization with compression (snappy)

#### Database Layer (`EventDatabase.ets`)
- Uses RelationalStore API with encryption
- Implements concurrent processing with `@Concurrent` decorators
- Background thread operations for query/insert/delete
- Performance optimizations: batch operations, lazy loading

#### Configuration System
- Supports multiple deployment modes: SaaS, CDP, NewSaaS
- Multi-instance tracking with isolated contexts
- Plugin architecture for extensibility

## File Naming Conventions

- **ArkTS files**: `.ets` extension (HarmonyOS TypeScript variant)
- **TypeScript files**: `.ts` extension (utilities and types)
- **Configuration**: `.json5` format for build and package configs
- **Resources**: Organized under `src/main/resources/` with localization support

## Development Guidelines

### Language Constraints
This project uses **ArkTS** (not standard TypeScript) with specific limitations:
- No `any` or `unknown` types - use explicit typing
- No structural typing - use inheritance or interfaces
- No destructuring assignment - use explicit property access
- Limited operator semantics (e.g., unary `+` only for numbers)
- See `docs/typescript-to-arkts-migration-guide.md` for comprehensive migration guide

### Performance Considerations
- Database operations use taskpool for background processing
- Event serialization optimized with lazy loading patterns
- Network requests support compression and encryption
- Concurrent processing implemented for heavy operations

### SDK Integration Patterns

#### Standard Initialization (Two-Stage Pattern)
```typescript
// In AbilityStage's onCreate method
import { GrowingAnalytics, GrowingConfig } from '@growingio/analytics'

// Stage 1: Configure SDK
let config = new GrowingConfig().NewSaaS(
  'Your AccountId',
  'Your DataSourceId', 
  'Your UrlScheme',
  'Your DataCollectionServerHost<Optional>'
)
GrowingAnalytics.configure(config)

// Stage 2: Start analytics (after privacy consent)
GrowingAnalytics.startAnalytics(this.context)

// Or for delayed start (in UIAbility)
GrowingAnalytics.deferStart(getContext(this) as common.UIAbilityContext)
```

#### URL Scheme Handling
```typescript
// In EntryAbility.ets
onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  let uri = want?.uri
  if (uri) {
    GrowingAnalytics.handleOpenURL(uri)
  }
}

onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  let uri = want?.uri
  if (uri) {
    GrowingAnalytics.handleOpenURL(uri)
  }
}
```

#### Multi-instance Support
```typescript
// Initialize sub-tracker
GrowingAnalytics.startSubTracker('subTrackerId', config)

// Use sub-tracker
let subTracker = GrowingAnalytics.tracker('subTrackerId')
subTracker.track('eventName', { key: 'value' })
```

#### Hybrid WebView Integration
```typescript
// Inject hybrid bridge into WebView
Web({ src: url, controller: this.controller })
  .javaScriptAccess(true)
  .domStorageAccess(true)
  .javaScriptProxy(GrowingAnalytics.createHybridProxy(this.controller, webviewId))
  .id(webviewId)
```

## Key Dependencies

- **snappyjs** (0.7.0): Data compression
- **@ohos/protobufjs** (2.1.0): Protocol buffer serialization
- **long** (5.2.1): Long integer support for protobuf

## Module Dependencies

```
entry
├── @growingio/analytics (file:../GrowingAnalytics)
└── @growingio/tools (file:../GrowingToolsKit)

GrowingAnalytics
├── snappyjs: 0.7.0
├── @ohos/protobufjs: 2.1.0
└── long: 5.2.1

GrowingToolsKit
├── snappyjs: 0.7.0
├── @ohos/protobufjs: 2.1.0
└── long: 5.2.1
```

## Build Configuration

- **Model Version**: 5.0.0
- **Compatible SDK Version**: 5.0.0(12)
- **Target SDK Version**: 6.0.0(20)
- **Runtime OS**: HarmonyOS
- **Strict Mode**: useNormalizedOHMUrl enabled

## Testing

The project includes test modules:
- Unit tests in `src/test/` directory
- Integration tests in `src/ohosTest/` directory
- Test runner: `@ohos/hypium` (1.0.17)
- Mock framework: `@ohos/hamock` (1.0.0)
