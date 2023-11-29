export class GrowingConfig {
  accountId: string
  dataSourceId: string
  dataCollectionServerHost: string
  urlScheme: string

  debugEnabled: boolean = false
  sessionInterval: number = 30
  dataCollectionEnabled: boolean = true
  idMappingEnabled: boolean = true
  encryptEnabled: boolean = false
}