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
import sendableRelationalStore from '@ohos.data.sendableRelationalStore'
import emitter from '@ohos.events.emitter'
import taskpool from '@ohos.taskpool'
import sendableContextManager from '@ohos.app.ability.sendableContextManager'
import collections from '@arkts.collections'

import EventPersistence from './EventPersistence'
import { insertTask, batchInsertTask, batchDeleteTask, queryEventsTask, countOfEventsTask } from './EventDatabaseAsync'
import GrowingContext from '../core/Context'
import { DATABASE_NAME, EMIT_EVENT_DATABASE_FLUSH } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'

"use shared"

@Sendable
export default class EventDatabase {
  static isDatabaseCreated: boolean = false
  static context: sendableContextManager.SendableContext
  static eventsCache: collections.Array<sendableRelationalStore.ValuesBucket> = new collections.Array<sendableRelationalStore.ValuesBucket>()
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
    EventDatabase.context = sendableContextManager.convertFromContext(appContext)

    try {
      let store = await relationalStore.getRdbStore(appContext, config)
      await store.executeSql(SQL_CREATE_TABLE)
      await EventDatabase.cleanExpiredEventIfNeeded(store)
      EventDatabase.isDatabaseCreated = true
      await EventDatabase.flushCacheIfNeeded()
    } catch (e) {
      LogUtil.error(() => "Failed to create database. code = " + e.code + ", message = " + e.message)
    }
  }

  static async flushCacheIfNeeded() {
    if (!EventDatabase.isDatabaseCreated) {
      return
    }

    if (EventDatabase.eventsCache.length == 0) {
      return
    }

    try {
      let events = [...EventDatabase.eventsCache]
      EventDatabase.eventsCache = new collections.Array<sendableRelationalStore.ValuesBucket>()
      await taskpool.execute(batchInsertTask, EventDatabase.tableName, events, EventDatabase.context, DATABASE_NAME)
      LogUtil.info(() => 'Write events that were created before database initialization to disk = '
        + JSON.stringify(
        JSON.parse('[' + events.map((e: sendableRelationalStore.ValuesBucket) => {
          let nonSendableValueBucket = sendableRelationalStore.fromSendableValuesBucket(e)
          return nonSendableValueBucket['DATA'] as string
        }).join(',') + ']'), null, 4))
      emitter.emit(EMIT_EVENT_DATABASE_FLUSH)
    } catch (e) {
      LogUtil.error(() => "Failed to flush cached events: " + e.message)
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

    const sendableValueBucket = sendableRelationalStore.toSendableValuesBucket(valueBucket)

    if (!EventDatabase.isDatabaseCreated) {
      EventDatabase.eventsCache.push(sendableValueBucket)
      return
    }

    try {
      await EventDatabase.flushCacheIfNeeded()
      await taskpool.execute(insertTask, EventDatabase.tableName, sendableValueBucket, EventDatabase.context, DATABASE_NAME)
      LogUtil.info(() => 'Write event to disk = ' + JSON.stringify(JSON.parse(event.data), null, 4))
    } catch (e) {
      LogUtil.error(() => "Failed to write event: " + e.message)
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
      LogUtil.error(() => "Failed to query events: " + e.message)
      return []
    }
  }

  static async removeEvents(events: EventPersistence[]) {
    if (!EventDatabase.isDatabaseCreated || events.length === 0) {
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
      LogUtil.error(() => "Failed to remove events: " + e.message)
    }
  }

  static async countOfEvents(context: GrowingContext, eventTypes?: string[]): Promise<number> {
    if (!EventDatabase.isDatabaseCreated) {
      return 0
    }

    let count = 0
    try {
      count = await taskpool.execute(
        countOfEventsTask,
        EventDatabase.tableName,
        context.config.accountId,
        context.config.dataSourceId,
        EventDatabase.context,
        DATABASE_NAME,
        eventTypes
      ) as number
    } catch (e) {
      LogUtil.error(() => "Failed to count events: " + e.message)
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
      LogUtil.error(() => "Failed to clean expired events: " + e.message)
    }
  }
}