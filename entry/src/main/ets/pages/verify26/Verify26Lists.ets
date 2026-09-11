/**
 * 验证点 3：列表族的 index 采集（SDK 常量 LIST_COMPONENTS）
 *
 * SDK 在 xpath 回溯时遇到 ListItem / GridItem / GridCol / FlowItem 会把该层的
 * xcontent 记为 '-'，并把该层的兄弟序号作为事件的 index 上报。
 * 26.0.0 新增了 LazyColumnLayout / LazyVWaterFlowLayout / LazyDynamicLayout 等
 * 懒加载布局容器，节点树层级有变化的可能。
 *
 * 注意：每个点击目标都必须挂 onClick，否则 UIObserver 的 willClick 不会针对该组件触发。
 *
 * 需要对比的内容：点击每个 item 上的按钮，检查 VIEW_CLICK 事件的
 * 1) index 是否与按钮上显示的序号一致（NewSaaS 模式下列表内 index 会 +1）；
 * 2) xpath 中对应层级是否仍为 ListItem / GridItem / GridCol / FlowItem，xcontent 是否为 '-'。
 */
@Entry
@Component
struct Verify26Lists {
  private items: number[] = [0, 1, 2, 3, 4, 5]

  build() {
    Scroll() {
      Column({ space: 10 }) {
        Text('列表 index 验证')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 12 })
        Text('点击各 item 的按钮，对比事件 index 与按钮上的序号')
          .fontSize(12)
          .fontColor('#666666')

        Text('List / ListItem').fontSize(16).fontWeight(FontWeight.Bold)
        List({ space: 8 }) {
          ForEach(this.items, (item: number) => {
            ListItem() {
              Button('ListItem-' + item.toString())
                .width('80%')
                .onClick(() => {
                })
            }
          }, (item: number) => 'list-' + item.toString())
        }
        .width('100%')
        .height(200)

        Text('Grid / GridItem').fontSize(16).fontWeight(FontWeight.Bold)
        Grid() {
          ForEach(this.items, (item: number) => {
            GridItem() {
              Button('GridItem-' + item.toString())
                .width('90%')
                .onClick(() => {
                })
            }
          }, (item: number) => 'grid-' + item.toString())
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        .height(200)

        Text('WaterFlow / FlowItem').fontSize(16).fontWeight(FontWeight.Bold)
        WaterFlow() {
          ForEach(this.items, (item: number) => {
            FlowItem() {
              Button('FlowItem-' + item.toString())
                .width('90%')
                .onClick(() => {
                })
            }
            .height(50)
          }, (item: number) => 'flow-' + item.toString())
        }
        .columnsTemplate('1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        .height(200)

        Text('GridRow / GridCol').fontSize(16).fontWeight(FontWeight.Bold)
        GridRow({ gutter: 8 }) {
          ForEach(this.items, (item: number) => {
            GridCol({ span: 6 }) {
              Button('GridCol-' + item.toString())
                .width('90%')
                .onClick(() => {
                })
            }
            .height(50)
          }, (item: number) => 'gridcol-' + item.toString())
        }
        .width('100%')
        .margin({ bottom: 24 })
      }
      .width('100%')
      .padding({ left: 12, right: 12 })
    }
    .width('100%')
    .height('100%')
  }
}
