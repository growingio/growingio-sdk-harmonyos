import { GrowingConfig } from '../interfaces/GrowingConfig'
import SharedPreferences from '../utils/SharedPreferences'
import Session from './Session'

export default class AnalyticsCore {
  preferences: SharedPreferences = null
  config: GrowingConfig = null
  session: Session = null

  constructor(context: Context, config: GrowingConfig) {
    this.preferences = new SharedPreferences(context)
    this.config = config
    this.session = new Session()
  }
}