/**
 * @license
 * Copyright (C) 2025 Beijing Yishu Technology Co., Ltd.
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

// @doc-impl Utils.md

import buffer from '@ohos.buffer'

import EventPersistence from "../event/EventPersistence"
import { LogUtil } from './LogUtil'
import snappy from 'snappyjs'
import { event_pb } from './protobuf/event_pb'

/**
 * processEvents 的返回结果：请求体与实际用于序列化的发送副本
 */
export interface ProcessEventsResult {
  serialize: ArrayBuffer
  sentEvents: EventPersistence[]
}

interface DeviceIdHolder {
  deviceId: string
}

@Concurrent
export function processEvents(
  events: EventPersistence[],
  useProtobuf: boolean,
  compressEnabled: boolean,
  mergeSaaSClick: boolean = false,
  pendingDeviceIdReplacement: string = ''
): ProcessEventsResult {
  let serialize: ArrayBuffer = new ArrayBuffer(0)
  // 强制登录未解锁时写入的事件带待替换标志，发送副本替换为有效设备 ID；其他事件原样复用。
  // 只有出现待替换事件时才复制数组；解析结果按下标保存，Protobuf 构造 DTO 时复用，避免重复解析
  let parsedByIndex: Map<number, DeviceIdHolder> | undefined = undefined
  if (pendingDeviceIdReplacement.length > 0) {
    let sentEvents: EventPersistence[] | undefined = undefined
    for (let i = 0; i < events.length; i++) {
      let e = events[i]
      if (!e.forceLoginPending) {
        continue
      }
      try {
        let parsed = JSON.parse(e.data) as DeviceIdHolder
        parsed.deviceId = pendingDeviceIdReplacement
        if (!parsedByIndex) {
          parsedByIndex = new Map<number, DeviceIdHolder>()
        }
        parsedByIndex.set(i, parsed)
        if (!sentEvents) {
          sentEvents = events.slice()
        }
        sentEvents[i] = EventPersistence.fromDatabase(
          e.uuid, JSON.stringify(parsed), e.eventType, e.sdkVersion, e.accountId, e.dataSourceId
        )
      } catch (error) {
        // 替换失败时按入库时的自动生成设备 ID 上报
        LogUtil.error(() => 'Failed to replace pending deviceId: ' + error)
      }
    }
    if (sentEvents) {
      events = sentEvents
    }
  }

  if (useProtobuf) {
    let values: event_pb.EventV3Dto[] = []
    events.forEach((e, i) => {
      try {
        let event = parsedByIndex?.get(i) ?? (JSON.parse(e.data) as DeviceIdHolder)
        let dto = event_pb.EventV3Dto.fromObject(event)
        values.push(dto)
      } catch (error) {
        LogUtil.error(() => 'Failed to parse event data: ' + error)
      }
    })
    try {
      let list = event_pb.EventV3List.create({values: values})
      let arrayBuffer: Uint8Array = event_pb.EventV3List.encode(list).finish()
      serialize = buffer.from(arrayBuffer).buffer
    } catch (error) {
      LogUtil.error(() => 'Failed to create protobuf: ' + error)
    }
  } else {
    try {
      let json: string
      if (mergeSaaSClick) {
        // 按合并 key 分组，提取公共字段到顶层，每条事件的专属字段收入 e 数组
        let groupsMap: Record<string, Array<Record<string, Object>>> = {}
        for (let e of events) {
          let event = JSON.parse(e.data) as Record<string, Object>
          let key = `${event['t']}_${event['u']}_${event['s']}_${event['d']}_${event['p']}_${event['ptm']}`
          if (!groupsMap[key]) {
            groupsMap[key] = []
          }
          groupsMap[key].push(event)
        }
        let result: Array<Record<string, Object>> = []
        for (let key of Object.keys(groupsMap)) {
          let groupEvents = groupsMap[key]
          let first = groupEvents[0]
          let top: Record<string, Object> = {
            't': first['t'],
            'tm': first['tm'],
            'u': first['u'],
            's': first['s'],
            'd': first['d'],
            'p': first['p'],
            'ptm': first['ptm'],
          }
          if (first['cs1'] !== undefined && first['cs1'] !== null && String(first['cs1']).length > 0) {
            top['cs1'] = first['cs1']
          }
          if (first['q'] !== undefined && first['q'] !== null) {
            top['q'] = first['q']
          }
          if (first['lat'] !== undefined && first['lat'] !== null) {
            top['lat'] = first['lat']
          }
          if (first['lng'] !== undefined && first['lng'] !== null) {
            top['lng'] = first['lng']
          }
          top['e'] = groupEvents.map((ev: Record<string, Object>) => {
            let item: Record<string, Object> = {
              'tm': ev['tm'],
              'x': ev['x'],
              'gesid': ev['gesid'],
              'esid': ev['esid'],
            }
            if (ev['v'] !== undefined && ev['v'] !== null) {
              item['v'] = ev['v']
            }
            if (ev['idx'] !== undefined && ev['idx'] !== null) {
              item['idx'] = ev['idx']
            }
            if (ev['h'] !== undefined && ev['h'] !== null) {
              item['h'] = ev['h']
            }
            return item
          })
          result.push(top)
        }
        json = JSON.stringify(result)
      } else {
        json = '[' + events.map(event => String(event.data)).join(',') + ']'
      }
      serialize = buffer.from(json, 'utf-8').buffer
    } catch (error) {
      LogUtil.error(() => 'Failed to create JSON buffer: ' + error)
    }
  }

  if (compressEnabled) {
    try {
      serialize = snappy.compress(serialize) as ArrayBuffer
    } catch (error) {
      LogUtil.error(() => 'Failed to compress data: ' + error)
    }
  }

  let result: ProcessEventsResult = { serialize: serialize, sentEvents: events }
  return result
}