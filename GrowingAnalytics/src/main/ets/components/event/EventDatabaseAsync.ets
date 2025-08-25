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

import relationalStore from '@ohos.data.relationalStore'
import sendableRelationalStore from '@ohos.data.sendableRelationalStore'
import sendableContextManager from '@ohos.app.ability.sendableContextManager'
import collections from '@arkts.collections'

import EventPersistence from './EventPersistence'
import { LogUtil } from '../utils/LogUtil'
import Util from '../utils/Util'

@Concurrent
export async function insertTask(
  tableName: string,
  event: sendableRelationalStore.ValuesBucket,
  context: sendableContextManager.SendableContext,
  dbName: string
): Promise<void> {
  const config: relationalStore.StoreConfig = {
    name: dbName + '.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  }

  try {
    let appContext = sendableContextManager.convertToApplicationContext(context)
    let store = await relationalStore.getRdbStore(appContext, config)
    let nonSendableEvent = sendableRelationalStore.fromSendableValuesBucket(event)
    await store.insert(tableName, nonSendableEvent)
  } catch (e) {
    LogUtil.error(() => "Failed to insert event to disk. code = " + e.code + ", message = " + e.message)
    throw new Error(`Database insert failed: ${e.message}`)
  }
}

@Concurrent
export async function batchInsertTask(
  tableName: string,
  events: collections.Array<sendableRelationalStore.ValuesBucket>,
  context: sendableContextManager.SendableContext,
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
    let appContext = sendableContextManager.convertToApplicationContext(context)
    let store = await relationalStore.getRdbStore(appContext, config)
    let nonSendableEvents: relationalStore.ValuesBucket[] = []
    for (let e of events) {
      nonSendableEvents.push(sendableRelationalStore.fromSendableValuesBucket(e))
    }
    await store.batchInsert(tableName, nonSendableEvents)
  } catch (e) {
    LogUtil.error(() => "Failed to batch insert events to disk. code = " + e.code + ", message = " + e.message)
    throw new Error(`Database batch insert failed: ${e.message}`)
  }
}

@Concurrent
export async function batchDeleteTask(
  tableName: string,
  uuids: string[],
  context: sendableContextManager.SendableContext,
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
    let appContext = sendableContextManager.convertToApplicationContext(context)
    let store = await relationalStore.getRdbStore(appContext, config)
    let predicates = new relationalStore.RdbPredicates(tableName)
    predicates.in('EVENT_UUID', uuids)
    await store.delete(predicates)
  } catch (e) {
    LogUtil.error(() => "Failed to batch delete events from disk. code = " + e.code + ", message = " + e.message)
    throw new Error(`Database batch delete failed: ${e.message}`)
  }
}

@Concurrent
export async function queryEventsTask(
  tableName: string,
  count: number,
  size: number,
  accountId: string,
  dataSourceId: string,
  context: sendableContextManager.SendableContext,
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
    let appContext = sendableContextManager.convertToApplicationContext(context)
    let store = await relationalStore.getRdbStore(appContext, config)
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
    throw new Error(`Database query failed: ${e.message}`)
  }

  return events
}

@Concurrent
export async function countOfEventsTask(
  tableName: string,
  accountId: string,
  dataSourceId: string,
  context: sendableContextManager.SendableContext,
  dbName: string,
  eventTypes?: string[]
): Promise<number> {
  let count = 0

  const config: relationalStore.StoreConfig = {
    name: dbName + '.db',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true
  }

  try {
    let appContext = sendableContextManager.convertToApplicationContext(context)
    let store = await relationalStore.getRdbStore(appContext, config)
    let predicates = new relationalStore.RdbPredicates(tableName)
    if (eventTypes && eventTypes.length > 0) {
      predicates.in('TYPE', eventTypes)
    }
    predicates.equalTo('ACCOUNT_ID', accountId)
    predicates.equalTo('DATASOURCE_ID', dataSourceId)
    let r = await store.query(predicates)
    count = r.rowCount
    r.close()
  } catch (e) {
    LogUtil.error(() => "Failed to get event count from disk. code = " + e.code + ", message = " + e.message)
    throw new Error(`Database count query failed: ${e.message}`)
  }

  return count
}