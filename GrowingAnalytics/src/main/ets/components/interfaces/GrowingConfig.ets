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

  constructor(
    accountId: string,
    dataSourceId: string,
    urlScheme: string,
    dataCollectionServerHost: string = 'https://napi.growingio.com'
  ) {
    this.accountId = accountId
    this.dataSourceId = dataSourceId
    this.urlScheme = urlScheme
    this.dataCollectionServerHost = dataCollectionServerHost
  }

  copy(): GrowingConfig {
    var config = new GrowingConfig(
      this.accountId,
      this.dataSourceId,
      this.urlScheme,
      this.dataCollectionServerHost)

    config.debugEnabled = this.debugEnabled
    config.sessionInterval = this.sessionInterval
    config.dataCollectionEnabled = this.dataCollectionEnabled
    config.idMappingEnabled = this.idMappingEnabled
    config.encryptEnabled = this.encryptEnabled

    return config
  }
}