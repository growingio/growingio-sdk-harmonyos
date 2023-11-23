export default interface EventBuilder {
  setUserId(userId: string): EventBuilder
  setUserKey(userKey: string): EventBuilder
  setSessionId(sessionId: string): EventBuilder
  setEventSequenceId(eventSequenceId: number): EventBuilder
  setNetworkState(networkState: string): EventBuilder
  setTimestamp(timestamp: number): EventBuilder
  setLatitude(latitude: number): EventBuilder
  setLongitude(longitude: number): EventBuilder
  setSdkVersion(sdkVersion: string): EventBuilder
  setDataSourceId(dataSourceId: string): EventBuilder
  build<T extends EventBuilder>(this: T): T
}