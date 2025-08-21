/**
 * @license
 * Copyright (C) 2024 Beijing Yishu Technology Co., Ltd.
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

@Component
export default struct ModuleButton {
  entrySideLength: number = 50
  imageSideLength : number = this.entrySideLength - 15
  buttonSideLength: number = this.entrySideLength + 15

  @Require @Prop name: string
  @Require @Prop image: string
  @Prop isActive: boolean = false

  build() {
    Button() {
      Column() {
        Stack() {
          Image($r(this.image))
            .backgroundColor(this.isActive ? '#E5732C' : '#FF9167')
            .width(this.imageSideLength)
            .height(this.imageSideLength)
        }
        .backgroundColor(this.isActive ? '#E5732C' : '#FF9167')
        .borderRadius(this.entrySideLength / 2)
        .width(this.entrySideLength)
        .height(this.entrySideLength)
        Blank(10)
        Text(this.name)
      }
    }
    .backgroundColor(Color.White)
    .stateEffect(false)
    .width(this.buttonSideLength)
    .height(this.buttonSideLength)
  }
}