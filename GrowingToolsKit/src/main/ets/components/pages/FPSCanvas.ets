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

import { displaySync } from '@kit.ArkGraphics2D'
import { FPS_WINDOW_WIDTH, FPS_WINDOW_HEIGHT } from '../utils/Constants'

@Component
export default struct FPSCanvas {
  @State currentFPS: number = 0
  @State frameCount: number = 0
  @State @Watch('onFPSDataChanged') fpsHistory: number[] = []
  private fpsTimer: number | undefined = undefined
  private lastTime: number = 0
  private readonly maxHistoryLength: number = 60
  private readonly maxHistoryForChartLength: number = 20
  private readonly canvasWidth: number = FPS_WINDOW_WIDTH
  private readonly canvasHeight: number = FPS_WINDOW_HEIGHT
  private readonly maxFPS: number = 100
  private readonly fpsGood: number = 50
  private readonly fpsOk: number = 30
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D({ antialias: true })
  private displaySync: displaySync.DisplaySync | undefined

  aboutToAppear() {
    this.startFPSMonitoring()
  }

  aboutToDisappear() {
    this.stopFPSMonitoring()
  }

  onFPSDataChanged() {
    this.drawFPSChart(this.canvasContext)
  }

  private startFPSMonitoring() {
    this.lastTime = Date.now()
    this.currentFPS = 60
    this.frameCount = 0
    this.fpsHistory = []

    // 逐帧回调
    this.displaySync = displaySync.create()
    this.displaySync?.on("frame", (frameInfo: displaySync.IntervalInfo) => {
      this.frameCount++
    })
    this.displaySync?.start()

    // 计算并每秒更新 FPS
    this.fpsTimer = setInterval(() => {
      const currentTime = Date.now()
      const deltaTime = currentTime - this.lastTime

      if (deltaTime >= 1000) {
        this.currentFPS = Math.round((this.frameCount * 1000) / deltaTime)
        this.fpsHistory.push(this.currentFPS)

        if (this.fpsHistory.length > this.maxHistoryLength) {
          this.fpsHistory.shift()
        }

        this.frameCount = 0
        this.lastTime = currentTime
      }
    }, 1000)
  }

  private stopFPSMonitoring() {
    this.displaySync?.off("frame")
    this.displaySync?.stop()
    this.displaySync = undefined

    if (this.fpsTimer !== undefined) {
      clearInterval(this.fpsTimer)
      this.fpsTimer = undefined
    }
  }

  private drawFPSChart(context: CanvasRenderingContext2D) {
    try {
      context.fillStyle = '#1a1a1a'
      context.fillRect(0, 0, this.canvasWidth, this.canvasHeight)

      context.strokeStyle = '#444444'
      context.lineWidth = 1
      const gridLines = 8
      for (let i = 0; i <= gridLines; i++) {
        const y = (i / gridLines) * this.canvasHeight
        context.beginPath()
        context.moveTo(0, y)
        context.lineTo(this.canvasWidth, y)
        context.stroke()
      }

      context.fillStyle = '#888888'
      context.font = '8px sans-serif'
      for (let i = 0; i <= gridLines; i++) {
        const fpsValue = this.maxFPS - (i * 10)
        const y = (i / gridLines) * this.canvasHeight + 3
        context.fillText(`${fpsValue}`, 2, y)
      }

      if (this.fpsHistory.length >= 1) {
        const stepX = this.canvasWidth / Math.max(1, this.maxHistoryForChartLength - 1)

        const lineColor = this.getFPSColor(this.currentFPS)
        context.strokeStyle = lineColor
        context.lineWidth = 2
        context.beginPath()

        let firstPoint = true
        let fpsHistory = this.fpsHistory.slice(-20) // 取最近的 20个 fps 进行绘制
        for (let i = 0; i < fpsHistory.length; i++) {
          const x = i * stepX
          const normalizedFPS = Math.max(0, Math.min(1, fpsHistory[i] / this.maxFPS))
          const y = this.canvasHeight - (normalizedFPS * this.canvasHeight)

          if (firstPoint) {
            context.moveTo(x, y)
            firstPoint = false
          } else {
            context.lineTo(x, y)
          }
        }

        context.stroke()
      } else {
        context.fillStyle = '#888888'
        context.font = '10px sans-serif'
        context.fillText('等待 FPS 数据...', this.canvasWidth / 2 - 30, this.canvasHeight / 2)
      }
    } catch (error) {
      console.error('Error drawing FPS chart:', error)
    }
  }

  private getFPSColor(fps: number): string {
    if (fps >= this.fpsGood) return '#00FF00'
    if (fps >= this.fpsOk) return '#FFA500'
    return '#FF0000'
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Canvas(this.canvasContext)
        .width(this.canvasWidth)
        .height(this.canvasHeight)
        .backgroundColor('#1a1a1a')
        .onReady(() => {
          this.drawFPSChart(this.canvasContext)
        })

      Text(`FPS: ${this.currentFPS}`)
        .fontSize(10)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getFPSColor(this.currentFPS))
        .backgroundColor('#000000AA')
        .padding({ left: 3, right: 3, top: 1, bottom: 1 })
        .margin({ left: 4, top: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#1a1a1a')
  }
}