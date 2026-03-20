/**
 * @license
 * Copyright (C) 2023 Beijing Yishu Technology Co., Ltd.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { sendablePreferences } from '@kit.ArkData'
import ArkTSUtils from '@arkts.utils'
import emitter from '@ohos.events.emitter'

import EventPersistence from './EventPersistence'
import GrowingContext from '../core/Context'
import { DATABASE_NAME, EMIT_EVENT_DATABASE_FLUSH } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import Util from '../utils/Util'

const MAX_EVENT_COUNT = 10000
const PREFERENCES_NAME = DATABASE_NAME

// key 格式：{createAt:016d}_{accountId}_{dataSourceId}_{eventType}_{sdkVersion}_{uuid}
// 字典序 = 时间序，无需解析 value 即可排序、过滤、清理过期事件
const KEY_CREATEAT_PAD = 16

interface ParsedKey {
  createAt: number
  accountId: string
  dataSourceId: string
  eventType: string
  sdkVersion: string
  uuid: string
}

interface FilteredKey {
  key: string
  parsed: ParsedKey
}

function buildKey(
  createAt: number,
  accountId: string,
  dataSourceId: string,
  eventType: string,
  sdkVersion: string,
  uuid: string
): string {
  return createAt.toString().padStart(KEY_CREATEAT_PAD, '0')
    + '_' + accountId
    + '_' + dataSourceId
    + '_' + eventType
    + '_' + sdkVersion
    + '_' + uuid
}

function parseKey(key: string): ParsedKey {
  let i0 = key.indexOf('_')
  let i1 = key.indexOf('_', i0 + 1)
  let i2 = key.indexOf('_', i1 + 1)
  let i3 = key.indexOf('_', i2 + 1)
  let i4 = key.indexOf('_', i3 + 1)
  return {
    createAt: parseInt(key.substring(0, i0)),
    accountId: key.substring(i0 + 1, i1),
    dataSourceId: key.substring(i1 + 1, i2),
    eventType: key.substring(i2 + 1, i3),
    sdkVersion: key.substring(i3 + 1, i4),
    uuid: key.substring(i4 + 1)
  }
}

@Sendable
class PreferencesHolder {
  prefs: sendablePreferences.Preferences | null = null
}

const _holder = new PreferencesHolder()
const _lock = new ArkTSUtils.locks.AsyncLock()

export default class EventDatabase {
  static async initDatabase(context: Context) {
    try {
      let appContext = context.getApplicationContext()
      let options: sendablePreferences.Options = { name: PREFERENCES_NAME }
      let prefs = sendablePreferences.getPreferencesSync(appContext, options)
      _holder.prefs = prefs

      await EventDatabase.cleanExpiredEventIfNeeded()
      emitter.emit(EMIT_EVENT_DATABASE_FLUSH)
      LogUtil.info(() => 'EventDatabase (sendablePreferences) initialized')
    } catch (e) {
      LogUtil.error(() => 'Failed to initialize EventDatabase. code = ' + (e as Error).message)
    }
  }

  static async writeEvent(event: EventPersistence) {
    await _lock.lockAsync(async () => {
      try {
        let prefs = _holder.prefs
        if (!prefs) {
          LogUtil.error(() => 'EventDatabase not initialized, dropping event')
          return
        }

        let all = prefs.getAllSync() as Record<string, Object>
        let keys = Object.keys(all)
        if (keys.length >= MAX_EVENT_COUNT) {
          // key 字典序 = 时间序，直接排序后取最旧的淘汰，无需 JSON.parse
          keys.sort()
          let evictCount = keys.length - MAX_EVENT_COUNT + 1
          for (let i = 0; i < evictCount; i++) {
            prefs.deleteSync(keys[i])
          }
          LogUtil.info(() => `EventDatabase capacity exceeded, evicted ${evictCount} oldest event(s)`)
        }

        let createAt = Date.now()
        let key = buildKey(createAt, event.accountId, event.dataSourceId, event.eventType, event.sdkVersion, event.uuid)
        prefs.putSync(key, event.data)
        await prefs.flush()

        LogUtil.info(() => 'Write event to disk = ' + JSON.stringify(JSON.parse(event.data), null, 4))
      } catch (e) {
        LogUtil.error(() => 'Failed to write event to disk. ' + (e as Error).message)
      }
    })
  }

  static async getEventsByCount(
    count: number,
    size: number,
    context: GrowingContext,
    eventTypes?: string[]
  ): Promise<EventPersistence[]> {
    return _lock.lockAsync(async () => {
      try {
        let prefs = _holder.prefs
        if (!prefs) {
          return []
        }

        let all = prefs.getAllSync() as Record<string, Object>
        let keys = Object.keys(all)
        let accountId = context.config.accountId
        let dataSourceId = context.config.dataSourceId

        // key 字典序 = 时间序，排序后直接按时间顺序过滤，无需解析 value
        keys.sort()

        let filtered: FilteredKey[] = []
        for (let key of keys) {
          let parsed = parseKey(key)
          if (parsed.accountId !== accountId) {
            continue
          }
          if (parsed.dataSourceId !== dataSourceId) {
            continue
          }
          if (eventTypes && eventTypes.length > 0 && !eventTypes.includes(parsed.eventType)) {
            continue
          }
          let item: FilteredKey = { key: key, parsed: parsed }
          filtered.push(item)
        }

        // 只对最终入选的事件读取 value
        let events: EventPersistence[] = []
        let totalSize = 0
        for (let item of filtered) {
          if (events.length >= count) {
            break
          }
          let data = all[item.key] as string
          let dataSize = Util.sizeOfEventString(data)
          if (totalSize + dataSize > size) {
            break
          }
          events.push(EventPersistence.fromDatabase(
            item.key,
            data,
            item.parsed.eventType,
            item.parsed.sdkVersion,
            item.parsed.accountId,
            item.parsed.dataSourceId
          ))
          totalSize += dataSize
        }

        if (events.length > 0) {
          LogUtil.info(() => `Retrieved ${events.length} events from disk`)
        }
        return events
      } catch (e) {
        LogUtil.error(() => 'Failed to get events from disk. ' + (e as Error).message)
        return []
      }
    })
  }

  static async removeEvents(events: EventPersistence[]) {
    if (events.length === 0) {
      return
    }

    await _lock.lockAsync(async () => {
      try {
        let prefs = _holder.prefs
        if (!prefs) {
          return
        }
        for (let event of events) {
          // event.uuid 存储的是从 DB 读取时的完整 compound key
          prefs.deleteSync(event.uuid)
        }
        await prefs.flush()
        LogUtil.info(() => `Batch deleted ${events.length} events from disk`)
      } catch (e) {
        LogUtil.error(() => 'Failed to remove events from disk. ' + (e as Error).message)
      }
    })
  }

  static async countOfEvents(context: GrowingContext, eventTypes?: string[]): Promise<number> {
    return _lock.lockAsync(async () => {
      try {
        let prefs = _holder.prefs
        if (!prefs) {
          return 0
        }

        let all = prefs.getAllSync() as Record<string, Object>
        let keys = Object.keys(all)
        let accountId = context.config.accountId
        let dataSourceId = context.config.dataSourceId

        // 只解析 key 字符串，不读 value
        let count = 0
        for (let key of keys) {
          let parsed = parseKey(key)
          if (parsed.accountId !== accountId) {
            continue
          }
          if (parsed.dataSourceId !== dataSourceId) {
            continue
          }
          if (eventTypes && eventTypes.length > 0 && !eventTypes.includes(parsed.eventType)) {
            continue
          }
          count++
        }
        return count
      } catch (e) {
        LogUtil.error(() => 'Failed to count events from disk. ' + (e as Error).message)
        return 0
      }
    })
  }

  static async cleanExpiredEventIfNeeded() {
    try {
      let prefs = _holder.prefs
      if (!prefs) {
        return
      }

      // 按各 tracker 自身的 _dataValidityPeriod 清理，key 中已含 accountId/dataSourceId
      let now = Date.now()
      let expiryMap: Map<string, number> = new Map()
      for (let ctx of GrowingContext.contexts.values()) {
        let mapKey = ctx.config.accountId + '_' + ctx.config.dataSourceId
        expiryMap.set(mapKey, now - ctx.config._dataValidityPeriod)
      }
      if (expiryMap.size === 0) {
        return
      }

      let all = prefs.getAllSync() as Record<string, Object>
      let keys = Object.keys(all)
      let deleted = 0
      for (let key of keys) {
        let parsed = parseKey(key)
        let mapKey = parsed.accountId + '_' + parsed.dataSourceId
        let threshold = expiryMap.get(mapKey)
        if (threshold === undefined) {
          // 不属于任何已注册 tracker 的孤立事件，用主 tracker 的阈值兜底
          let defaultCtx = GrowingContext.getDefaultContext()
          if (!defaultCtx) {
            continue
          }
          threshold = now - defaultCtx.config._dataValidityPeriod
        }
        if (parsed.createAt <= threshold) {
          prefs.deleteSync(key)
          deleted++
        }
      }
      if (deleted > 0) {
        await prefs.flush()
        LogUtil.info(() => `Cleaned ${deleted} expired event(s) from disk`)
      }
    } catch (e) {
      LogUtil.error(() => 'Failed to clean expired events. ' + (e as Error).message)
    }
  }
}
