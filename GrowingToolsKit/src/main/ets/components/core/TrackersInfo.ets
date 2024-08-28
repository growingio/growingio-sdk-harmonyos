import { GTKConfig } from '../utils/Constants'

interface _TrackersInfo {
  trackerId: string
  config: GTKConfig
}

export default class TrackersInfo {
  static info: Array<_TrackersInfo> = []

  static push(trackerId: string, config: GTKConfig) {
    TrackersInfo.info.push({
      trackerId: trackerId,
      config: config
    })
  }
}