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

export default class EventDatabase {
  static store: relationalStore.RdbStore
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
      + 'EVENT_SCENE INTEGER NOT NULL, '
      + 'CREATE_AT INTEGER NOT NULL, '
      + 'IS_SEND INTEGER NOT NULL)'

    let appContext = context.getApplicationContext()

    try {
      let store = await relationalStore.getRdbStore(appContext, config)
      await store.executeSql(SQL_CREATE_TABLE)
      await EventDatabase.cleanExpiredEventIfNeeded(store)
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

    if (EventDatabase.eventsCache.length == 0) {
      return
    }

    try {
      await EventDatabase.store.batchInsert(EventDatabase.tableName, EventDatabase.eventsCache)
      EventDatabase.eventsCache = []
    } catch (e) {
      LogUtil.error(() => "Failed to write cached events to disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async writeEvent(event: EventPersistence) {
    const valueBucket: relationalStore.ValuesBucket = {
      'EVENT_UUID': event.uuid,
      'DATA': event.data,
      'TYPE': event.eventType,
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
      await EventDatabase.store.insert(EventDatabase.tableName, valueBucket)
    } catch (e) {
      LogUtil.error(() => "Failed to write event to disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async getEventsByCount(
    count: number,
    createAt?: number,
    eventTypes?: string[]
  ): Promise<EventPersistence[]> {
    let events: EventPersistence[] = []

    if (!EventDatabase.store) {
      return events
    }

    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableName)
      if (eventTypes && eventTypes.length > 0) {
        predicates.in('TYPE', eventTypes)
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
        const eventScene = r.getDouble(r.getColumnIndex('EVENT_SCENE'))
        const createAt = r.getDouble(r.getColumnIndex('CREATE_AT'))
        const isSend = r.getValue(r.getColumnIndex('IS_SEND'))
        let e = EventPersistence.fromDatabase(uuid, data, eventType, eventScene, createAt, isSend as boolean)
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
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableName)
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
    EventDatabase.cleanExpiredEventIfNeeded(EventDatabase.store, Date.now())
  }

  static async cleanExpiredEventIfNeeded(store: relationalStore.RdbStore, daysAgo: number = Date.now() - 30 * 86400000) {
    if (!store) {
      return
    }

    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableName)
      predicates.lessThanOrEqualTo('CREATE_AT', daysAgo)
      await store.delete(predicates)
    } catch (e) {
      LogUtil.error(() => "Failed to remove event from disk. code = " + e.code + ", message = " + e.message)
    }
  }
}