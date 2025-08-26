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

import relationalStore from '@ohos.data.relationalStore'
import emitter from '@ohos.events.emitter'
import taskpool from '@ohos.taskpool'

import EventPersistence from './EventPersistence'
import GrowingContext from '../core/Context'
import { DATABASE_NAME, EMIT_EVENT_DATABASE_FLUSH } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import Util from '../utils/Util'

export default class EventDatabase {
  static store: relationalStore.RdbStore
  static context: Context
  static eventsCache: relationalStore.ValuesBucket[] = []
  static tableName: string = 'EVENTS'

  static async initDatabase(context: Context) {
    const config: relationalStore.StoreConfig = {
      name: DATABASE_NAME + '.db',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true
    }

    const SQL_CREATE_TABLE = 'CREATE TABLE IF NOT EXISTS '
      + EventDatabase.tableName + '('
      + 'ID INTEGER PRIMARY KEY AUTOINCREMENT, '
      + 'EVENT_UUID TEXT NOT NULL, '
      + 'DATA TEXT NOT NULL, '
      + 'TYPE TEXT NOT NULL, '
      + 'CREATE_AT INTEGER NOT NULL, '
      + 'ACCOUNT_ID TEXT NOT NULL, '
      + 'DATASOURCE_ID TEXT NOT NULL, '
      + 'SDK_VERSION TEXT NOT NULL)'

    let appContext = context.getApplicationContext()
    EventDatabase.context = appContext

    try {
      let store = await relationalStore.getRdbStore(appContext, config)
      await store.executeSql(SQL_CREATE_TABLE)
      await EventDatabase.cleanExpiredEventIfNeeded(store)
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

    if (EventDatabase.eventsCache.length == 0) {
      return
    }

    try {
      let events = [...EventDatabase.eventsCache]
      EventDatabase.eventsCache = []
      await taskpool.execute(batchInsertTask, EventDatabase.tableName, events, EventDatabase.context, DATABASE_NAME)
      LogUtil.info(() => 'Write events that were created before database initialization to disk = '
        + JSON.stringify(
        JSON.parse('[' + events.map((e: relationalStore.ValuesBucket) => {
          return e['DATA'] as string
        }).join(',') + ']'), null, 4))
      emitter.emit(EMIT_EVENT_DATABASE_FLUSH)
    } catch (e) {
      LogUtil.error(() => "Failed to write cached events to disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async writeEvent(event: EventPersistence) {
    const valueBucket: relationalStore.ValuesBucket = {
      'EVENT_UUID': event.uuid,
      'DATA': event.data,
      'TYPE': event.eventType,
      'CREATE_AT': Date.now(),
      'SDK_VERSION': event.sdkVersion,
      'ACCOUNT_ID': event.accountId,
      'DATASOURCE_ID': event.dataSourceId
    }

    if (!EventDatabase.store) {
      EventDatabase.eventsCache.push(valueBucket)
      return
    }

    try {
      await EventDatabase.flushCacheIfNeeded()
      await EventDatabase.store.insert(EventDatabase.tableName, valueBucket)
      LogUtil.info(() => 'Write event to disk = ' + JSON.stringify(JSON.parse(event.data), null, 4))
    } catch (e) {
      LogUtil.error(() => "Failed to write event to disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async getEventsByCount(
    count: number,
    size: number,
    context: GrowingContext,
    eventTypes?: string[]
  ): Promise<EventPersistence[]> {
    try {
      const events = await taskpool.execute(
        queryEventsTask,
        EventDatabase.tableName,
        count,
        size,
        context.config.accountId,
        context.config.dataSourceId,
        EventDatabase.context,
        DATABASE_NAME,
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

  static async removeEvents(events: EventPersistence[]) {
    if (!EventDatabase.store || events.length === 0) {
      return
    }

    try {
      const uuids: string[] = []
      for (const event of events) {
        uuids.push(event.uuid)
      }
      
      await taskpool.execute(batchDeleteTask, EventDatabase.tableName, uuids, EventDatabase.context, DATABASE_NAME)
      LogUtil.info(() => `Batch deleted ${events.length} events from disk in background thread`)
    } catch (e) {
      LogUtil.error(() => "Failed to batch remove events from disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async countOfEvents(context: GrowingContext, eventTypes?: string[]): Promise<number> {
    if (!EventDatabase.store) {
      return 0
    }

    let count = 0
    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableName)
      if (eventTypes && eventTypes.length > 0) {
        predicates.in('TYPE', eventTypes)
      }
      predicates.equalTo('ACCOUNT_ID', context.config.accountId)
      predicates.equalTo('DATASOURCE_ID', context.config.dataSourceId)
      let r = await EventDatabase.store.query(predicates)
      count = r.rowCount
      r.close()
    } catch (e) {
      LogUtil.error(() => "Failed to get event count from disk. code = " + e.code + ", message = " + e.message)
    }

    return count
  }

  static async cleanExpiredEventIfNeeded(store: relationalStore.RdbStore) {
    if (!store) {
      return
    }

    let context = GrowingContext.getDefaultContext() as GrowingContext
    let daysAgo = Date.now() - context.config._dataValidityPeriod

    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableName)
      predicates.lessThanOrEqualTo('CREATE_AT', daysAgo)
      await store.delete(predicates)
    } catch (e) {
      LogUtil.error(() => "Failed to clean expired event from disk. code = " + e.code + ", message = " + e.message)
    }
  }
}

@Concurrent
async function batchInsertTask(
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
async function batchDeleteTask(
  tableName: string, 
  uuids: string[],
  context: Context,
  dbName: string
): Promise<void> {
  if (uuids.length === 0) {
    return
  }

  const config: relationalStore.StoreConfig = {
    name: dbName + '.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  }

  try {
    let store = await relationalStore.getRdbStore(context, config)
    let predicates = new relationalStore.RdbPredicates(tableName)
    predicates.in('EVENT_UUID', uuids)
    await store.delete(predicates)
  } catch (e) {
    LogUtil.error(() => "Failed to batch delete events. code = " + e.code + ", message = " + e.message)
    throw new Error(`Database delete failed: ${e.message}`)
  }
}

@Concurrent
async function queryEventsTask(
  tableName: string,
  count: number,
  size: number,
  accountId: string,
  dataSourceId: string,
  context: Context,
  dbName: string,
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
    predicates.orderByAsc('CREATE_AT')
    predicates.equalTo('ACCOUNT_ID', accountId)
    predicates.equalTo('DATASOURCE_ID', dataSourceId)
    
    let eventsSize = 0
    let r = await store.query(predicates)
    while (r.goToNextRow() && events.length < count && eventsSize < size) {
      const uuid = r.getString(r.getColumnIndex('EVENT_UUID'))
      const data = r.getString(r.getColumnIndex('DATA'))
      const eventType = r.getString(r.getColumnIndex('TYPE'))
      const sdkVersion = r.getString(r.getColumnIndex('SDK_VERSION'))
      const accountId = r.getString(r.getColumnIndex('ACCOUNT_ID'))
      const dataSourceId = r.getString(r.getColumnIndex('DATASOURCE_ID'))
      let e = EventPersistence.fromDatabase(uuid, data, eventType, sdkVersion, accountId, dataSourceId)
      events.push(e)
      eventsSize += Util.sizeOfEventString(String(data))
    }
    r.close()
  } catch (e) {
    LogUtil.error(() => "Failed to query events from disk. code = " + e.code + ", message = " + e.message)
  }

  return events
}