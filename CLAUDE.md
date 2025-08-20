# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **GrowingIO HarmonyOS NEXT SDK** repository, a data analytics SDK for HarmonyOS applications. The project contains:

- **GrowingAnalytics**: Core analytics SDK module for event tracking and data collection
- **GrowingToolsKit**: Developer tools and debugging utilities for the SDK
- **entry**: Demo application showcasing SDK integration and usage

The SDK supports HarmonyOS with OpenHarmony API 12 and provides automatic event collection plus manual tracking APIs.

## Build System & Commands

This project uses HarmonyOS's **hvigor** build system with the following key commands:

### Development Commands
```bash
# Build in debug mode(Default)
# entry
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon

# GrowingAnalytics
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p product=default -p module=GrowingAnalytics@default assembleHar --analyze=normal --parallel --incremental --daemon

# GrowingToolsKit
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js --mode module -p product=default -p module=GrowingToolsKit@default assembleHar --analyze=normal --parallel --incremental --daemon

# Clean build artifacts
/Applications/DevEco-Studio.app/Contents/tools/node/bin/node /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw.js -p product=default clean --analyze=normal --parallel --incremental --daemon
```

> add `-p buildMode=release` for building in release mode

### Package Management
```bash
# Install dependencies via OHPM (OpenHarmony Package Manager)
ohpm install

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
- **Auto-tracking**: `src/main/ets/components/autotrack/` - automatic UI event collection

#### GrowingToolsKit (`/GrowingToolsKit/`)
- **Debug Tools**: Developer debugging utilities (network monitoring, event inspection)
- **Integration**: Plugin-based integration with main SDK
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
```typescript
// Standard initialization in AbilityStage
let config = new GrowingConfig().NewSaaS(
  'Your AccountId',
  'Your DataSourceId', 
  'Your UrlScheme',
  'Your DataCollectionServerHost<Optional>'
)
GrowingAnalytics.start(this.context, config)

// Multi-instance support
GrowingAnalytics.startSubTracker(trackerId, config)
let subTracker = GrowingAnalytics.tracker('subTrackerId')
```

## Key Dependencies

- **snappyjs**: Data compression
- **@ohos/protobufjs**: Protocol buffer serialization