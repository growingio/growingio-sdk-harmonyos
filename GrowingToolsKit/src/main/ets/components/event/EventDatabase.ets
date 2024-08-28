/**
 * @license
 * Copyright (C) 2024 Beijing Yishu Technology Co., Ltd.
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

import relationalStore from '@ohos.data.relationalStore'

import EventPersistence from './EventPersistence'
import { DATABASE_NAME } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import RequestPersistence from '../network/RequestPersistence'

export default class EventDatabase {
  static store: relationalStore.RdbStore
  static eventsCache: relationalStore.ValuesBucket[] = []
  static tableEvents: string = 'EVENTS'
  static requestsCache: relationalStore.ValuesBucket[] = []
  static tableRequests: string = 'REQUESTS'

  static async initDatabase(context: Context) {
    const config: relationalStore.StoreConfig = {
      name: DATABASE_NAME + '.db',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true
    }

    const SQL_CREATE_TABLE_EVENTS = 'CREATE TABLE IF NOT EXISTS '
      + EventDatabase.tableEvents + '('
      + 'ID INTEGER PRIMARY KEY AUTOINCREMENT, '
      + 'EVENT_UUID TEXT NOT NULL, '
      + 'DATA TEXT NOT NULL, '
      + 'TYPE TEXT NOT NULL, '
      + 'ACCOUNT_ID TEXT NOT NULL, '
      + 'DATASOURCE_ID TEXT NOT NULL, '
      + 'EVENT_SCENE INTEGER NOT NULL, '
      + 'CREATE_AT INTEGER NOT NULL, '
      + 'IS_SEND INTEGER NOT NULL)'

    const SQL_CREATE_TABLE_REQUESTS = 'CREATE TABLE IF NOT EXISTS '
      + EventDatabase.tableRequests + '('
      + 'ID INTEGER PRIMARY KEY AUTOINCREMENT, '
      + 'REQUEST_UUID TEXT NOT NULL, '
      + 'INFO TEXT NOT NULL, '
      + 'REQUEST TEXT DEFAULT NULL, '
      + 'REQUEST_BLOB BLOB DEFAULT NULL, '
      + 'RESPONSE_BLOB BLOB DEFAULT NULL, '
      + 'CREATE_AT INTEGER NOT NULL)'

    let appContext = context.getApplicationContext()

    try {
      let store = await relationalStore.getRdbStore(appContext, config)
      await store.executeSql(SQL_CREATE_TABLE_EVENTS)
      await EventDatabase.cleanExpiredEventIfNeeded(store)
      await store.executeSql(SQL_CREATE_TABLE_REQUESTS)
      await EventDatabase.cleanExpiredRequestIfNeeded(store)
      EventDatabase.store = store
      EventDatabase.flushCacheIfNeeded()
    } catch (e) {
      LogUtil.error(() => "Failed to create database. code = " + e.code + ", message = " + e.message)
    }
  }

  static async flushCacheIfNeeded() {
    if (!EventDatabase.store) {
      return
    }

    try {
      if (EventDatabase.eventsCache.length > 0) {
        await EventDatabase.store.batchInsert(EventDatabase.tableEvents, EventDatabase.eventsCache)
        EventDatabase.eventsCache = []
      }
      if (EventDatabase.requestsCache.length > 0) {
        await EventDatabase.store.batchInsert(EventDatabase.tableRequests, EventDatabase.requestsCache)
        EventDatabase.requestsCache = []
      }
    } catch (e) {
      LogUtil.error(() => "Failed to write cached events to disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async writeEvent(event: EventPersistence) {
    const valueBucket: relationalStore.ValuesBucket = {
      'EVENT_UUID': event.uuid,
      'DATA': event.data,
      'TYPE': event.eventType,
      'ACCOUNT_ID': event.accountId,
      'DATASOURCE_ID': event.dataSourceId,
      'EVENT_SCENE': event.eventScene,
      'CREATE_AT': event.createAt,
      'IS_SEND': event.isSend
    }

    if (!EventDatabase.store) {
      EventDatabase.eventsCache.push(valueBucket)
      return
    }

    try {
      await EventDatabase.flushCacheIfNeeded()
      await EventDatabase.store.insert(EventDatabase.tableEvents, valueBucket)
    } catch (e) {
      LogUtil.error(() => "Failed to write event to disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async getEventsByCount(
    count: number,
    createAt?: number,
    accountId?: string,
    dataSourceId?: string,
    eventTypes?: string[]
  ): Promise<EventPersistence[]> {
    let events: EventPersistence[] = []

    if (!EventDatabase.store) {
      return events
    }

    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableEvents)
      if (eventTypes && eventTypes.length > 0) {
        predicates.in('TYPE', eventTypes)
      }
      if (accountId && accountId.length > 0) {
        predicates.equalTo('ACCOUNT_ID', accountId)
      }
      if (dataSourceId && dataSourceId.length > 0) {
        predicates.equalTo('DATASOURCE_ID', dataSourceId)
      }
      if (createAt && createAt > 0) {
        predicates.lessThan('CREATE_AT', createAt)
      }
      predicates.orderByDesc('CREATE_AT')
      let r = await EventDatabase.store.query(predicates)
      while (r.goToNextRow() && events.length < count) {
        const uuid = r.getString(r.getColumnIndex('EVENT_UUID'))
        const data = r.getString(r.getColumnIndex('DATA'))
        const eventType = r.getString(r.getColumnIndex('TYPE'))
        const accountId = r.getString(r.getColumnIndex('ACCOUNT_ID'))
        const dataSourceId = r.getString(r.getColumnIndex('DATASOURCE_ID'))
        const eventScene = r.getDouble(r.getColumnIndex('EVENT_SCENE'))
        const createAt = r.getDouble(r.getColumnIndex('CREATE_AT'))
        const isSend = r.getValue(r.getColumnIndex('IS_SEND'))
        let e = EventPersistence.fromDatabase(
          uuid, data, eventType, accountId, dataSourceId, eventScene, createAt, isSend as boolean)
        events.push(e)
      }
      r.close()
    } catch (e) {
      LogUtil.error(() => "Failed to get event from disk. code = " + e.code + ", message = " + e.message)
    }

    return events
  }

  static async countOfEvents(eventTypes?: string[]): Promise<number> {
    if (!EventDatabase.store) {
      return 0
    }

    let count = 0
    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableEvents)
      if (eventTypes && eventTypes.length > 0) {
        predicates.in('TYPE', eventTypes)
      }
      let r = await EventDatabase.store.query(predicates)
      count = r.rowCount
      r.close()
    } catch (e) {
      LogUtil.error(() => "Failed to get event count from disk. code = " + e.code + ", message = " + e.message)
    }

    return count
  }

  static async updateEventsDidSend(events: string[]) {
    if (!EventDatabase.store) {
      return
    }

    try {
      EventDatabase.store.beginTransaction()
      for (let uuid of events) {
        await EventDatabase.store.execute(
          'UPDATE Events SET IS_SEND = 1 WHERE EVENT_UUID = ?',
          [uuid]
        )
      }
      EventDatabase.store.commit()
    } catch (e) {
      LogUtil.error(() => "Failed to update event from disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async removeAllEvents() {
    await EventDatabase.cleanExpiredEventIfNeeded(EventDatabase.store, Date.now())
  }

  static async cleanExpiredEventIfNeeded(store: relationalStore.RdbStore, daysAgo: number = Date.now() - 30 * 86400000) {
    if (!store) {
      return
    }

    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableEvents)
      predicates.lessThanOrEqualTo('CREATE_AT', daysAgo)
      await store.delete(predicates)
    } catch (e) {
      LogUtil.error(() => "Failed to remove event from disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async writeRequest(request: RequestPersistence) {
    const valueBucket: relationalStore.ValuesBucket = {
      'REQUEST_UUID': request.uuid,
      'INFO': JSON.stringify(request.info),
      'CREATE_AT': request.info.startTimestamp
    }

    if (typeof request.requestBody == 'string') {
      valueBucket['REQUEST'] = request.requestBody as string
    } else {
      let blob = request.requestBody as ArrayBuffer
      valueBucket['REQUEST_BLOB'] = new Uint8Array(blob)
    }

    if (request.responseBody) {
      let blob = request.responseBody as ArrayBuffer
      valueBucket['RESPONSE_BLOB'] = new Uint8Array(blob)
    }

    if (!EventDatabase.store) {
      EventDatabase.requestsCache.push(valueBucket)
      return
    }

    try {
      await EventDatabase.flushCacheIfNeeded()
      await EventDatabase.store.insert(EventDatabase.tableRequests, valueBucket)
    } catch (e) {
      LogUtil.error(() => "Failed to write request to disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async getRequestsByCount(
    count: number,
    createAt?: number
  ): Promise<RequestPersistence[]> {
    let requests: RequestPersistence[] = []

    if (!EventDatabase.store) {
      return requests
    }

    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableRequests)
      if (createAt && createAt > 0) {
        predicates.lessThan('CREATE_AT', createAt)
      }
      predicates.orderByDesc('CREATE_AT')
      let r = await EventDatabase.store.query(predicates)
      while (r.goToNextRow() && requests.length < count) {
        const info = r.getString(r.getColumnIndex('INFO'))
        const uuid = r.getString(r.getColumnIndex('REQUEST_UUID'))
        const requestBody = r.getString(r.getColumnIndex('REQUEST'))
        const requestBodyBlob = r.getBlob(r.getColumnIndex('REQUEST_BLOB'))
        const responseBodyBlob = r.getBlob(r.getColumnIndex('RESPONSE_BLOB'))
        let req = RequestPersistence.fromDatabase(
          info,
          uuid,
          requestBody && requestBody.length > 0 ? requestBody : (requestBodyBlob.buffer as ArrayBuffer),
          responseBodyBlob.buffer as ArrayBuffer
        )
        requests.push(req)
      }
      r.close()
    } catch (e) {
      LogUtil.error(() => "Failed to get request from disk. code = " + e.code + ", message = " + e.message)
    }

    return requests
  }

  static async countOfRequests(): Promise<number> {
    if (!EventDatabase.store) {
      return 0
    }

    let count = 0
    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableRequests)
      let r = await EventDatabase.store.query(predicates)
      count = r.rowCount
      r.close()
    } catch (e) {
      LogUtil.error(() => "Failed to get request count from disk. code = " + e.code + ", message = " + e.message)
    }

    return count
  }

  static async removeAllRequests() {
    await EventDatabase.cleanExpiredRequestIfNeeded(EventDatabase.store, Date.now())
  }

  static async cleanExpiredRequestIfNeeded(store: relationalStore.RdbStore, daysAgo: number = Date.now() - 30 * 86400000) {
    if (!store) {
      return
    }

    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableRequests)
      predicates.lessThanOrEqualTo('CREATE_AT', daysAgo)
      await store.delete(predicates)
    } catch (e) {
      LogUtil.error(() => "Failed to remove request from disk. code = " + e.code + ", message = " + e.message)
    }
  }
}