/**
 *
 * @author 王洪贺
 * @date 2024/2/20 16:17
 */
import PlayManager from './PlayManager';

@Entry
@Component
export struct CanvasTest {
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private canvas: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)
  private player: PlayManager = new PlayManager();

  aboutToAppear(): void {
    this.player.init()
  }

  build() {
    Column() {

      Button('绘制')
        .onClick(() => {
          this.canvas.clearRect(0, 0, 500, 500)
          this.canvas.fillStyle = 'rgba(0,0,0,0.2)'
          this.canvas.beginPath()
          this.canvas.moveTo(100, 100)
          this.canvas.lineTo(200, 100)
          this.canvas.lineTo(200, 200)
          this.canvas.lineTo(100, 200)
          this.canvas.closePath()

          this.canvas.moveTo(50, 50)
          this.canvas.lineTo(250, 50)
          this.canvas.lineTo(250, 250)
          this.canvas.lineTo(50, 250)
          this.canvas.closePath()

          this.canvas.stroke()
          this.canvas.fill("evenodd")

        })
      Button('播放').onClick(() => {
        // const rawPath = 'beep.ogg'
        // const fd = PlayManager.context.resourceManager.getRawFdSync(rawPath).fd
        // this.player.play(`fd://${fd}`)
        this.player.play(`https://image.honghe.cool/audio/beep.ogg`)//鸿蒙目前播放rawfile里的文件有异常，总提示文件格式错误，换成网络播放没有问题
      })
      Canvas(this.canvas)
        .width('100%')
        .height('100%')
        .layoutWeight(1)

    }
  }
}