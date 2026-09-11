import bundleManager from '@ohos.bundle.bundleManager'
import common from '@ohos.app.ability.common'
import deviceInfo from '@ohos.deviceInfo'
import fs from '@ohos.file.fs'
import hilog from '@ohos.hilog'
import window from '@ohos.window'

/**
 * HarmonyOS 26.0.0 验证用的事件录制插件（仅 demo 使用，不进 SDK）。
 *
 * 通过 SDK 的 onEventWroteToDisk 插件回调拿到每一条落库事件，输出到两个地方：
 * 1) hilog（tag = GIOV26），单条日志有长度上限，因此按 CHUNK_SIZE 分片，由
 *    scripts/verify26/collect.py 按 seq/idx 重新拼装；
 * 2) 应用沙箱文件 files/verify26-events.jsonl，作为 hilog 丢日志时的兜底。
 *
 * 事件结构与 GrowingToolsKit 的插件保持一致（结构化赋值给 Array<PluginsInterface>）。
 */
export interface Verify26EventPersistence {
  uuid: string
  data: string
  eventType: string
  sdkVersion: string
  accountId: string
  dataSourceId: string
}

const VERIFY26_TAG: string = 'GIOV26'
const VERIFY26_DOMAIN: number = 0x0000
const CHUNK_SIZE: number = 700
const VERIFY26_FILE_NAME: string = '/verify26-events.jsonl'

export class Verify26Recorder {
  private static seq: number = 0
  private static filePath: string = ''

  afterWindowStageCreate(abilityContext: common.UIAbilityContext, windowStage: window.WindowStage): void {
    Verify26Recorder.filePath = abilityContext.filesDir + VERIFY26_FILE_NAME
    Verify26Recorder.truncateFile()
    Verify26Recorder.emit(Verify26Recorder.buildMeta())
  }

  onEventWroteToDisk(event: Verify26EventPersistence, eventScene: number): void {
    let record = '{"type":"event","eventType":"' + event.eventType + '","scene":' + eventScene.toString() +
      ',"uuid":"' + event.uuid + '","data":' + event.data + '}'
    Verify26Recorder.emit(record)
  }

  private static buildMeta(): string {
    let targetVersion = 0
    let releaseType = ''
    try {
      let bundleInfo = bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION)
      targetVersion = bundleInfo.targetVersion
      releaseType = bundleInfo.appInfo.releaseType ?? ''
    } catch (e) {
      targetVersion = 0
    }

    return '{"type":"meta","osFullName":"' + deviceInfo.osFullName +
      '","displayVersion":"' + deviceInfo.displayVersion +
      '","sdkApiVersion":' + deviceInfo.sdkApiVersion.toString() +
      ',"deviceBrand":"' + deviceInfo.brand +
      '","productModel":"' + deviceInfo.productModel +
      '","targetVersion":' + targetVersion.toString() +
      ',"releaseType":"' + releaseType +
      '","startedAt":' + Date.now().toString() + '}'
  }

  private static emit(record: string): void {
    Verify26Recorder.seq++
    let seq = Verify26Recorder.seq
    let total = Math.ceil(record.length / CHUNK_SIZE)
    if (total === 0) {
      total = 1
    }
    for (let i = 0; i < total; i++) {
      let chunk = record.substring(i * CHUNK_SIZE, (i + 1) * CHUNK_SIZE)
      hilog.info(VERIFY26_DOMAIN, VERIFY26_TAG, '%{public}s',
        'GIOV26 s=' + seq.toString() + ' i=' + i.toString() + ' n=' + total.toString() + ' ' + chunk)
    }
    Verify26Recorder.appendFile(record)
  }

  private static truncateFile(): void {
    try {
      let file = fs.openSync(Verify26Recorder.filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC)
      fs.closeSync(file)
    } catch (e) {
      hilog.warn(VERIFY26_DOMAIN, VERIFY26_TAG, '%{public}s', 'truncate verify26 file failed')
    }
  }

  private static appendFile(record: string): void {
    if (Verify26Recorder.filePath.length === 0) {
      return
    }
    try {
      let file = fs.openSync(Verify26Recorder.filePath,
        fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.APPEND)
      fs.writeSync(file.fd, record + '\n')
      fs.closeSync(file)
    } catch (e) {
      hilog.warn(VERIFY26_DOMAIN, VERIFY26_TAG, '%{public}s', 'append verify26 file failed')
    }
  }
}
