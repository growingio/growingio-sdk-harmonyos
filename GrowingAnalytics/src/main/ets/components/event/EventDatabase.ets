import relationalStore from '@ohos.data.relationalStore'

import EventPersistence from './EventPersistence'
import { DATABASE_EXPIRATION_TIME, DATABASE_NAME } from '../utils/Constants'
import { LogUtil } from '../utils/LogUtil'

export default class EventDatabase {
  static store: relationalStore.RdbStore

  static async initDatabase(context: Context) {
    const config: relationalStore.StoreConfig = {
      name: DATABASE_NAME + '.db',
      securityLevel: relationalStore.SecurityLevel.S1
    }

    const SQL_CREATE_TABLE = 'CREATE TABLE IF NOT EXISTS EVENT ('
    + 'ID INTEGER PRIMARY KEY AUTOINCREMENT, '
    + 'EVENT_UUID TEXT NOT NULL, '
    + 'DATA TEXT NOT NULL, '
    + 'TYPE TEXT NOT NULL, '
    + 'CREATE_AT INTEGER NOT NULL, '
    + 'SDK_VERSION TEXT NOT NULL)'

    let appContext = context.getApplicationContext()

    try {
      let store = await relationalStore.getRdbStore(appContext, config)
      await store.executeSql(SQL_CREATE_TABLE)
      this.store = store
    } catch (e) {
      LogUtil.error("Failed to create database. code = " + e.code + ", message = " + e.message)
    }

    await this.cleanExpiredEventIfNeeded()
  }

  static async writeEvent(event: EventPersistence) {
    if (!this.store) {
      return
    }

    const valueBucket = {
      'EVENT_UUID': event.uuid,
      'DATA': event.data,
      'TYPE': event.eventType,
      'CREATE_AT': Date.now(),
      'SDK_VERSION': event.sdkVersion
    }

    try {
      await this.store.insert('EVENT', valueBucket)
      LogUtil.info('Write event to disk = ' + event.data)
    } catch (e) {
      LogUtil.error("Failed to write event to disk. code = " + e.code + ", message = " + e.message)
    }
  }

  static async getEventsByCount(count: number): Promise<EventPersistence[]> {
    let events: EventPersistence[] = []

    if (!this.store) {
      return events
    }

    try {
      let predicates = new relationalStore.RdbPredicates('EVENT')
      predicates.orderByAsc('CREATE_AT')
      let r = await this.store.query(predicates, ['EVENT_UUID', 'DATA', 'TYPE', 'SDK_VERSION'])
      while (r.goToNextRow() && events.length < count) {
        const uuid = r.getString(r.getColumnIndex('EVENT_UUID'))
        const data = r.getString(r.getColumnIndex('DATA'))
        const eventType = r.getString(r.getColumnIndex('TYPE'))
        const sdkVersion = r.getString(r.getColumnIndex('SDK_VERSION'))
        let e = EventPersistence.fromDatabase(uuid, data, eventType, sdkVersion)
        events.push(e)
      }
      r.close()
    } catch (e) {
      LogUtil.error("Failed to get event from disk. code = " + e.code + ", message = " + e.message)
    }

    return events
  }

  static async removeEvents(events: EventPersistence[]) {
    if (!this.store) {
      return
    }

    while (events.length > 0) {
      let event = events.shift()
      try {
        let predicates = new relationalStore.RdbPredicates('EVENT')
        predicates.equalTo('EVENT_UUID', event.uuid)
        await this.store.delete(predicates)
      } catch (e) {
        LogUtil.error("Failed to remove event from disk. code = " + e.code + ", message = " + e.message)
      }
    }
  }

  static async countOfEvents(): Promise<number> {
    if (!this.store) {
      return 0
    }

    const SQL_GET_COUNT = 'SELECT COUNT(*) FROM EVENT'
    let count = 0

    try {
      let r = await this.store.querySql(SQL_GET_COUNT)
      r.goToFirstRow()
      count = r.getLong(r.getColumnIndex('COUNT(*)'))
      r.close()
    } catch (e) {
      LogUtil.error("Failed to get event count from disk. code = " + e.code + ", message = " + e.message)
    }

    return count
  }

  static async cleanExpiredEventIfNeeded() {
    if (!this.store) {
      return
    }

    let daysAgo = Date.now() - DATABASE_EXPIRATION_TIME

    try {
      let predicates = new relationalStore.RdbPredicates('EVENT')
      predicates.lessThanOrEqualTo('CREATE_AT', daysAgo)
      await this.store.delete(predicates)
    } catch (e) {
      LogUtil.error("Failed to clean expired event from disk. code = " + e.code + ", message = " + e.message)
    }
  }
}