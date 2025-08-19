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
import taskpool from '@ohos.taskpool'
import collections from '@arkts.collections'

import EventPersistence from './EventPersistence'
import { DATABASE_NAME } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import RequestPersistence from '../network/RequestPersistence'

export default class EventDatabase {
  static store: relationalStore.RdbStore
  static context: Context
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
    EventDatabase.context = appContext

    try {
      let store = await relationalStore.getRdbStore(appContext, config)
      await store.executeSql(SQL_CREATE_TABLE_EVENTS)
      await EventDatabase.cleanExpiredEventIfNeeded(store)
      await store.executeSql(SQL_CREATE_TABLE_REQUESTS)
      await EventDatabase.cleanExpiredRequestIfNeeded(store)
      EventDatabase.store = store
      await EventDatabase.flushCacheIfNeeded()
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
        let events = [...EventDatabase.eventsCache]
        EventDatabase.eventsCache = []
        await taskpool.execute(batchInsertEventsTask, EventDatabase.tableEvents, events, EventDatabase.context, DATABASE_NAME)
      }
      if (EventDatabase.requestsCache.length > 0) {
        let requests = [...EventDatabase.requestsCache]
        EventDatabase.requestsCache = []
        await taskpool.execute(batchInsertRequestsTask, EventDatabase.tableRequests, requests, EventDatabase.context, DATABASE_NAME)
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
      await taskpool.execute(insertSingleEventTask, EventDatabase.tableEvents, valueBucket, EventDatabase.context, DATABASE_NAME)
      LogUtil.info(() => `Wrote single event to disk in background thread`)
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
    try {
      const events = await taskpool.execute(
        queryEventsTask,
        EventDatabase.tableEvents,
        count,
        EventDatabase.context,
        DATABASE_NAME,
        createAt,
        accountId,
        dataSourceId,
        eventTypes
      ) as EventPersistence[]

      if (events.length > 0) {
        LogUtil.info(() => `Retrieved ${events.length} events from disk in background thread`)
      }
      return events
    } catch (e) {
      LogUtil.error(() => "Failed to get events from disk. code = " + e.code + ", message = " + e.message)
      return []
    }
  }

  static async updateEventsDidSend(events: string[]) {
    if (!EventDatabase.store || events.length === 0) {
      return
    }

    try {
      await taskpool.execute(updateEventsSendStatusTask, EventDatabase.tableEvents, events, EventDatabase.context, DATABASE_NAME)
      LogUtil.info(() => `Updated ${events.length} events send status in background thread`)
    } catch (e) {
      LogUtil.error(() => "Failed to update events from disk. code = " + e.code + ", message = " + e.message)
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
      await taskpool.execute(cleanExpiredEventsTask, EventDatabase.tableEvents, daysAgo, EventDatabase.context, DATABASE_NAME)
      LogUtil.info(() => `Cleaned expired events older than ${daysAgo} in background thread`)
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

    let request_blob = new collections.Uint8Array(request.requestBody)
    valueBucket['REQUEST_BLOB'] = Uint8Array.from(request_blob)

    if (request.responseBody) {
      let response_blob = new collections.Uint8Array(request.responseBody)
      valueBucket['RESPONSE_BLOB'] = Uint8Array.from(response_blob)
    }

    if (!EventDatabase.store) {
      EventDatabase.requestsCache.push(valueBucket)
      return
    }

    try {
      await EventDatabase.flushCacheIfNeeded()
      await taskpool.execute(insertSingleRequestTask, EventDatabase.tableRequests, valueBucket, EventDatabase.context, DATABASE_NAME)
      LogUtil.info(() => `Wrote single request to disk in background thread`)
    } catch (e) {
      LogUtil.error(() => "Failed to write request to disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async getRequestsByCount(
    count: number,
    createAt?: number
  ): Promise<RequestPersistence[]> {
    try {
      const requests = await taskpool.execute(
        queryRequestsTask,
        EventDatabase.tableRequests,
        count,
        EventDatabase.context,
        DATABASE_NAME,
        createAt
      ) as RequestPersistence[]

      if (requests.length > 0) {
        LogUtil.info(() => `Retrieved ${requests.length} requests from disk in background thread`)
      }
      return requests
    } catch (e) {
      LogUtil.error(() => "Failed to get requests from disk. code = " + e.code + ", message = " + e.message)
      return []
    }
  }

  static async removeAllRequests() {
    await EventDatabase.cleanExpiredRequestIfNeeded(EventDatabase.store, Date.now())
  }

  static async cleanExpiredRequestIfNeeded(store: relationalStore.RdbStore, daysAgo: number = Date.now() - 30 * 86400000) {
    if (!store) {
      return
    }

    try {
      await taskpool.execute(cleanExpiredRequestsTask, EventDatabase.tableRequests, daysAgo, EventDatabase.context, DATABASE_NAME)
      LogUtil.info(() => `Cleaned expired requests older than ${daysAgo} in background thread`)
    } catch (e) {
      LogUtil.error(() => "Failed to remove request from disk. code = " + e.code + ", message = " + e.message)
    }
  }
}

@Concurrent
async function batchInsertEventsTask(
  tableName: string, 
  events: relationalStore.ValuesBucket[],
  context: Context,
  dbName: string
): Promise<void> {
  if (events.length === 0) {
    return
  }

  const config: relationalStore.StoreConfig = {
    name: dbName + '.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  }

  try {
    let store = await relationalStore.getRdbStore(context, config)
    await store.batchInsert(tableName, events)
  } catch (e) {
    LogUtil.error(() => "Failed to batch insert events. code = " + e.code + ", message = " + e.message)
    throw new Error(`Database insert failed: ${e.message}`)
  }
}

@Concurrent
async function batchInsertRequestsTask(
  tableName: string, 
  requests: relationalStore.ValuesBucket[],
  context: Context,
  dbName: string
): Promise<void> {
  if (requests.length === 0) {
    return
  }

  const config: relationalStore.StoreConfig = {
    name: dbName + '.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  }

  try {
    let store = await relationalStore.getRdbStore(context, config)
    await store.batchInsert(tableName, requests)
  } catch (e) {
    LogUtil.error(() => "Failed to batch insert requests. code = " + e.code + ", message = " + e.message)
    throw new Error(`Database insert failed: ${e.message}`)
  }
}

@Concurrent
async function queryEventsTask(
  tableName: string,
  count: number,
  context: Context,
  dbName: string,
  createAt?: number,
  accountId?: string,
  dataSourceId?: string,
  eventTypes?: string[]
): Promise<EventPersistence[]> {
  const events: EventPersistence[] = []
  
  const config: relationalStore.StoreConfig = {
    name: dbName + '.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  }

  try {
    let store = await relationalStore.getRdbStore(context, config)
    let predicates = new relationalStore.RdbPredicates(tableName)
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
    
    let r = await store.query(predicates)
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
        uuid, data, eventType, accountId, dataSourceId, eventScene, createAt, isSend == 1)
      events.push(e)
    }
    r.close()
  } catch (e) {
    LogUtil.error(() => "Failed to query events from disk. code = " + e.code + ", message = " + e.message)
  }

  return events
}

@Concurrent
async function insertSingleEventTask(
  tableName: string,
  valueBucket: relationalStore.ValuesBucket,
  context: Context,
  dbName: string
): Promise<void> {
  const config: relationalStore.StoreConfig = {
    name: dbName + '.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  }

  try {
    let store = await relationalStore.getRdbStore(context, config)
    await store.insert(tableName, valueBucket)
  } catch (e) {
    LogUtil.error(() => "Failed to insert single event. code = " + e.code + ", message = " + e.message)
    throw new Error(`Database insert failed: ${e.message}`)
  }
}

@Concurrent
async function updateEventsSendStatusTask(
  tableName: string,
  eventUuids: string[],
  context: Context,
  dbName: string
): Promise<void> {
  if (eventUuids.length === 0) {
    return
  }

  const config: relationalStore.StoreConfig = {
    name: dbName + '.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  }

  try {
    let store = await relationalStore.getRdbStore(context, config)
    let transaction = await store.createTransaction()
    try {
      for (let uuid of eventUuids) {
        await transaction.execute(
          `UPDATE ${tableName} SET IS_SEND = 1 WHERE EVENT_UUID = ?`,
          [uuid]
        )
      }
      await transaction.commit()
    } catch (e) {
      await transaction.rollback()
      throw new Error(`Database transaction commit failed: ${e.message}`)
    }
  } catch (e) {
    LogUtil.error(() => "Failed to update events send status. code = " + e.code + ", message = " + e.message)
    throw new Error(`Database update failed: ${e.message}`)
  }
}

@Concurrent
async function insertSingleRequestTask(
  tableName: string,
  valueBucket: relationalStore.ValuesBucket,
  context: Context,
  dbName: string
): Promise<void> {
  const config: relationalStore.StoreConfig = {
    name: dbName + '.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  }

  try {
    let store = await relationalStore.getRdbStore(context, config)
    await store.insert(tableName, valueBucket)
  } catch (e) {
    LogUtil.error(() => "Failed to insert single request. code = " + e.code + ", message = " + e.message)
    throw new Error(`Database insert failed: ${e.message}`)
  }
}

@Concurrent
async function queryRequestsTask(
  tableName: string,
  count: number,
  context: Context,
  dbName: string,
  createAt?: number
): Promise<RequestPersistence[]> {
  const requests: RequestPersistence[] = []
  
  const config: relationalStore.StoreConfig = {
    name: dbName + '.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  }

  try {
    let store = await relationalStore.getRdbStore(context, config)
    let predicates = new relationalStore.RdbPredicates(tableName)
    if (createAt && createAt > 0) {
      predicates.lessThan('CREATE_AT', createAt)
    }
    predicates.orderByDesc('CREATE_AT')
    
    let r = await store.query(predicates)
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
    LogUtil.error(() => "Failed to query requests from disk. code = " + e.code + ", message = " + e.message)
  }

  return requests
}

@Concurrent
async function cleanExpiredEventsTask(
  tableName: string,
  daysAgo: number,
  context: Context,
  dbName: string
): Promise<void> {
  const config: relationalStore.StoreConfig = {
    name: dbName + '.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  }

  try {
    let store = await relationalStore.getRdbStore(context, config)
    let predicates = new relationalStore.RdbPredicates(tableName)
    predicates.lessThanOrEqualTo('CREATE_AT', daysAgo)
    await store.delete(predicates)
  } catch (e) {
    LogUtil.error(() => "Failed to clean expired events. code = " + e.code + ", message = " + e.message)
    throw new Error(`Database cleanup failed: ${e.message}`)
  }
}

@Concurrent
async function cleanExpiredRequestsTask(
  tableName: string,
  daysAgo: number,
  context: Context,
  dbName: string
): Promise<void> {
  const config: relationalStore.StoreConfig = {
    name: dbName + '.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  }

  try {
    let store = await relationalStore.getRdbStore(context, config)
    let predicates = new relationalStore.RdbPredicates(tableName)
    predicates.lessThanOrEqualTo('CREATE_AT', daysAgo)
    await store.delete(predicates)
  } catch (e) {
    LogUtil.error(() => "Failed to clean expired requests. code = " + e.code + ", message = " + e.message)
    throw new Error(`Database cleanup failed: ${e.message}`)
  }
}