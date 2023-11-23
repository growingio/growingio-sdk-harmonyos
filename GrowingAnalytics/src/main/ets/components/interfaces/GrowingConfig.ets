export class GrowingConfig {
  accountId: string
  dataSourceId: string
  dataCollectionServerHost: string

  debugEnabled: boolean = false
  sessionInterval: number = 30
  dataCollectionEnabled: boolean = true
  idMappingEnabled: boolean = false
  urlScheme: string
  encryptEnabled: boolean = false
}