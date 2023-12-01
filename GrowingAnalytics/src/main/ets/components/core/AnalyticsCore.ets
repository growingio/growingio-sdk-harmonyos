import { GrowingConfig } from '../interfaces/GrowingConfig'
import SharedPreferences from '../utils/SharedPreferences'
import Session from './Session'
import UserIdentifier from './UserIdentifier'
import { AttributesType } from '../utils/Constants'
import DeviceInfo from './DeviceInfo'
import CustomEvent from '../event/CustomEvent'
import EventSender from '../event/EventSender'
import LoginUserAttributesEvent from '../event/LoginUserAttributesEvent'
import GeneralProps from './GeneralProps'

export default class AnalyticsCore {
  preferences: SharedPreferences
  config: GrowingConfig
  session: Session
  location: Location
  generalProps: GeneralProps

  constructor(context: Context, config: GrowingConfig) {
    this.preferences = new SharedPreferences(context)
    this.config = config
    this.location = new Location()
    this.session = new Session()
    this.generalProps = new GeneralProps()
  }

  setDataCollectionEnabled(enabled: boolean) {
    let config = this.config
    if (config.dataCollectionEnabled == enabled) {
      return
    }
    config.dataCollectionEnabled = enabled
    if (enabled) {
      this.session.refreshSession()
      this.session.generateVisit()
    }
  }

  setLoginUserId(
    userId: string,
    userKey: string = ''
  ) {
    UserIdentifier.sharedInstance().setLoginUserId(userId, userKey)
  }

  setLocation(
    latitude: number,
    longitude: number
  ) {
    this.location.latitude = latitude
    this.location.longitude = longitude
  }

  async setLoginUserAttributes(
    attributes: AttributesType
  ) {
    let e = await LoginUserAttributesEvent.create(attributes)
    EventSender.sendEvent(e)
  }

  async getDeviceId() {
    let deviceInfo = await DeviceInfo.sharedInstance()
    return deviceInfo.deviceId
  }

  async track(
    eventName: string,
    attributes: AttributesType = null
  ) {
    let generalProps = this.generalProps.getGeneralProps()
    let e = await CustomEvent.create(eventName, { ...generalProps, ...attributes })
    EventSender.sendEvent(e)
  }
}

class Location {
  latitude: number = 0
  longitude: number = 0
}