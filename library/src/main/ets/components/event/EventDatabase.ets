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

import EventPersistence from './EventPersistence'
import { DATABASE_EXPIRATION_TIME, DATABASE_NAME } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'
import GrowingContext from '../core/Context'

export default class EventDatabase {
  static store: relationalStore.RdbStore
  static tableName: string = 'EVENTS'

  static async initDatabase(context: Context) {
    const config: relationalStore.StoreConfig = {
      name: DATABASE_NAME + '.db',
      securityLevel: relationalStore.SecurityLevel.S1
    }

    const SQL_CREATE_TABLE = 'CREATE TABLE IF NOT EXISTS'
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

    try {
      let store = await relationalStore.getRdbStore(appContext, config)
      await store.executeSql(SQL_CREATE_TABLE)
      EventDatabase.store = store
    } catch (e) {
      LogUtil.error("Failed to create database. code = " + e.code + ", message = " + e.message)
    }

    await EventDatabase.cleanExpiredEventIfNeeded()
  }

  static async writeEvent(event: EventPersistence) {
    if (!EventDatabase.store) {
      return
    }

    const valueBucket: relationalStore.ValuesBucket = {
      'EVENT_UUID': event.uuid,
      'DATA': event.data,
      'TYPE': event.eventType,
      'CREATE_AT': Date.now(),
      'SDK_VERSION': event.sdkVersion,
      'ACCOUNT_ID': event.accountId,
      'DATASOURCE_ID': event.dataSourceId
    }

    try {
      await EventDatabase.store.insert(EventDatabase.tableName, valueBucket)
      LogUtil.info('Write event to disk = ' + event.data)
    } catch (e) {
      LogUtil.error("Failed to write event to disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async getEventsByCount(count: number, size: number, context: GrowingContext): Promise<EventPersistence[]> {
    let events: EventPersistence[] = []

    if (!EventDatabase.store) {
      return events
    }

    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableName)
      predicates.orderByAsc('CREATE_AT')
      predicates.equalTo('ACCOUNT_ID', context.config.accountId)
      predicates.equalTo('DATASOURCE_ID', context.config.dataSourceId)
      let eventsSize = 0
      let r = await EventDatabase.store.query(predicates)
      while (r.goToNextRow() && events.length < count && eventsSize < size) {
        const uuid = r.getString(r.getColumnIndex('EVENT_UUID'))
        const data = r.getString(r.getColumnIndex('DATA'))
        const eventType = r.getString(r.getColumnIndex('TYPE'))
        const sdkVersion = r.getString(r.getColumnIndex('SDK_VERSION'))
        const accountId = r.getString(r.getColumnIndex('ACCOUNT_ID'))
        const dataSourceId = r.getString(r.getColumnIndex('DATASOURCE_ID'))
        let e = EventPersistence.fromDatabase(uuid, data, eventType, sdkVersion, accountId, dataSourceId)
        events.push(e)
        eventsSize += data.length
      }
      r.close()
    } catch (e) {
      LogUtil.error("Failed to get event from disk. code = " + e.code + ", message = " + e.message)
    }

    return events
  }

  static async removeEvents(events: EventPersistence[]) {
    if (!EventDatabase.store) {
      return
    }

    while (events.length > 0) {
      let event = events.shift()
      if (event) {
        try {
          let predicates = new relationalStore.RdbPredicates(EventDatabase.tableName)
          predicates.equalTo('EVENT_UUID', event.uuid)
          await EventDatabase.store.delete(predicates)
        } catch (e) {
          LogUtil.error("Failed to remove event from disk. code = " + e.code + ", message = " + e.message)
        }
      }
    }
  }

  static async countOfEvents(context: GrowingContext): Promise<number> {
    if (!EventDatabase.store) {
      return 0
    }

    let count = 0
    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableName)
      predicates.equalTo('ACCOUNT_ID', context.config.accountId)
      predicates.equalTo('DATASOURCE_ID', context.config.dataSourceId)
      let r = await EventDatabase.store.query(predicates)
      count = r.rowCount
      r.close()
    } catch (e) {
      LogUtil.error("Failed to get event count from disk. code = " + e.code + ", message = " + e.message)
    }

    return count
  }

  static async cleanExpiredEventIfNeeded() {
    if (!EventDatabase.store) {
      return
    }

    let daysAgo = Date.now() - DATABASE_EXPIRATION_TIME

    try {
      let predicates = new relationalStore.RdbPredicates(EventDatabase.tableName)
      predicates.lessThanOrEqualTo('CREATE_AT', daysAgo)
      await EventDatabase.store.delete(predicates)
    } catch (e) {
      LogUtil.error("Failed to clean expired event from disk. code = " + e.code + ", message = " + e.message)
    }
  }
}