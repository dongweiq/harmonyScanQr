import { scanCore, scanBarcode, customScan, detectBarcode } from '@kit.ScanKit';
// 导入功能涉及的权限申请、回调接口
import { router, promptAction, display } from '@kit.ArkUI';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common, abilityAccessCtrl } from '@kit.AbilityKit';
import { Utils } from './Utils';
import { fileIo, picker } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import PlayManager from './PlayManager';
import resourceManager from '@ohos.resourceManager'

@Entry
@Component
struct Index {
  private player: PlayManager = new PlayManager();
  @State userGrant: boolean = false
  @State surfaceId: string = ''
  @State isShowBack: boolean = false
  @State isFlashLightEnable: boolean = false
  // 设置预览流高度，默认单位：vp
  @State cameraHeight: number = 640
  // 设置预览流宽度，默认单位：vp
  @State cameraWidth: number = 360
  private mXComponentController: XComponentController = new XComponentController()
  private TAG: string = '[customScanPage]'
  private callback: AsyncCallback<Array<scanBarcode.ScanResult>> = async (error: BusinessError, result:
    Array<scanBarcode.ScanResult>) => {
    if (error) {
      hilog.error(0x0001, this.TAG, 'start failed , error: %{public}s', JSON.stringify(error));
      return;
    }
    this.showScanResult(result);
  }
  @State line_percent: number = 0
  private timerId: number = -1
  @State cWidth: number = 0;
  @State cHeight: number = 0;
  //四个角的点
  topLeftPoint: number[] = [0, 0]
  topRightPoint: number[] = [0, 0]
  bottomLeftPoint: number[] = [0, 0]
  bottomRightPoint: number[] = [0, 0]
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private contextGesture: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  aboutToAppear(): void {
    this.player.init()
  }

  aboutToDisappear(): void {
    this.player.release()
  }

  async showScanResult(result: Array<scanBarcode.ScanResult>) {
    // const rawPath = 'beep.ogg'
    // const fd = PlayManager.context.resourceManager.getRawFdSync(rawPath).fd
    // this.player.play(`fd://${fd}`)
    this.player.play(`https://image.honghe.cool/audio/beep.ogg`) //鸿蒙目前播放rawfile里的文件有异常，总提示文件格式错误，换成网络播放没有问题
    if (result.length > 0) {
      // 打印测试结果，可在获取到结果后做相应处理
      hilog.info(0x0001, this.TAG, 'scan result: %{public}s ', JSON.stringify(result));
      // 使用toast显示出扫码结果
      try {

        promptAction.showToast({
          message: JSON.stringify(result),
          duration: 5000
        });
      } catch (error) {
        hilog.error(0x0001, this.TAG, 'showToast error: %{public}s ', JSON.stringify(error));
      }
      this.isShowBack = true;
      this.isFlashLightEnable = false;
    }
  }

  async reqPermissionsFromUser(): Promise<number[]> {
    hilog.info(0x0001, this.TAG, 'reqPermissionsFromUser start ')
    let context = getContext() as common.UIAbilityContext;
    let atManager = abilityAccessCtrl.createAtManager();
    let grantStatus = await atManager.requestPermissionsFromUser(context, ['ohos.permission.CAMERA']);
    return grantStatus.authResults;
  }

  // 申请相机权限
  async requestCameraPermission() {
    let grantStatus = await this.reqPermissionsFromUser()
    for (let i = 0; i < grantStatus.length; i++) {
      if (grantStatus[i] === 0) {
        // 用户授权，可以继续访问目标操作
        hilog.info(0x0001, this.TAG, 'requestPermissionsFromUser success');
        this.userGrant = true;
      }
    }
  }

  setDisplay() {
    // 默认竖屏
    this.cameraHeight = 800
    this.cameraWidth = 450
  }

  async onPageShow() {
    console.error('whh:', 'onPageShow')
    await this.requestCameraPermission();
    this.cWidth = px2vp(display.getDefaultDisplaySync().width)
    this.cHeight = px2vp(display.getDefaultDisplaySync().height)
    let options: scanBarcode.ScanOptions = {
      scanTypes: [scanCore.ScanType.ALL],
      enableMultiMode: true,
      enableAlbum: true
    }
    this.setDisplay();
    try {
      customScan.init(options);
    } catch (error) {
      hilog.error(0x0001, this.TAG, 'init fail, error: %{public}s', JSON.stringify(error));
    }
    this.drawTransparentBackground()
    this.startLineMoving()
  }

  startLineMoving() {
    this.timerId = setInterval(() => {
      this.line_percent += 240 / 100 //扫描框的高度是240，分成一百份，每100毫秒移动百分之一
      if (this.line_percent >= 240) {
        this.line_percent = 0
      }
    }, 20)
  }

  stopLineMoving() {
    clearInterval(this.timerId)
  }

  async onPageHide() {
    this.stopLineMoving()
    // 页面消失或隐藏时，停止并释放相机流
    this.userGrant = false;
    try {
      await customScan.stop();
    } catch (error) {
      hilog.error(0x0001, this.TAG, 'Catch: stop error %{public}s', JSON.stringify(error));
    }
    try {
      customScan.release((error: BusinessError) => {
        if (error) {
          hilog.error(0x0001, this.TAG, 'release failed! %{public}s', JSON.stringify(error));
          return;
        }
        hilog.info(0x0001, this.TAG, 'release success!');
      })
    } catch (error) {
      hilog.error(0x0001, this.TAG, 'Catch: release error %{public}s', JSON.stringify(error));
    }
  }

  /** 绘制半透明背景 */
  drawTransparentBackground() {
    console.error('whh:', `drawTransparentBackground:cWidth${this.cWidth}  cHeight${this.cHeight}`)
    this.contextGesture.clearRect(0, 0, this.cWidth, this.cHeight)
    this.contextGesture.beginPath()
    //绘制内边框
    this.contextGesture.fillStyle = 'rgba(0,0,0,0.8)'
    this.contextGesture.moveTo(this.topLeftPoint[0], this.topLeftPoint[1])
    this.contextGesture.lineTo(this.topRightPoint[0], this.topRightPoint[1])
    this.contextGesture.lineTo(this.bottomRightPoint[0], this.bottomRightPoint[1])
    this.contextGesture.lineTo(this.bottomLeftPoint[0], this.bottomLeftPoint[1])
    this.contextGesture.closePath();
    //绘制外边框
    this.contextGesture.moveTo(0, 0)
    this.contextGesture.lineTo(0, this.cHeight)
    this.contextGesture.lineTo(this.cWidth, this.cHeight)
    this.contextGesture.lineTo(this.cWidth, 0)
    this.contextGesture.closePath();
    //填充中间区域
    this.contextGesture.fill("evenodd");
  }

  /** 从相册选择照片 */
  selectPicFromAlbum() {
    try {
      let photoOption = new picker.PhotoSelectOptions();
      photoOption.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoOption.maxSelectNumber = 1;
      let options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.QR_CODE],
        enableMultiMode: true,
        enableAlbum: true
      }
      let photoPicker = new picker.PhotoViewPicker();
      photoPicker.select(photoOption).then((photoResult) => {
        hilog.info(0x0001, this.TAG, 'photoResult: %{public}s', JSON.stringify(photoResult))
        let infoW: number = 0;
        let infoH: number = 0;
        try {
          let file = fileIo.openSync(photoResult.photoUris[0], fileIo.OpenMode.READ_ONLY);
          const imageSourceApi = image.createImageSource(file.fd);
          imageSourceApi.getImageInfo(0, (error: BusinessError, imageInfo) => {
            if (imageInfo == undefined) {
              hilog.error(0x0001, this.TAG, 'Failed to obtain the image pixel map information: %{public}s', JSON.stringify(error));
            }
            hilog.info(0x0001, this.TAG, 'imageInfo: %{public}s', JSON.stringify(typeof imageInfo))
            hilog.info(0x0001, this.TAG, 'imageInfo: %{public}s', JSON.stringify(imageInfo))
            infoW = imageInfo.size.width;
            infoH = imageInfo.size.height;
          })
        } catch (error) {
          hilog.error(0x0001, this.TAG, 'photoPicker error: %{public}s', error)
        }
        try {
          let inputImage: detectBarcode.InputImage = { uri: photoResult.photoUris[0] }
          detectBarcode.decode(inputImage, options).then((result: Array<scanBarcode.ScanResult>) => {
            // If the value is not identified, the value is returned without assigning a value.
            if (result && result.length > 0) {
              this.showScanResult(result)
            } else {
              hilog.error(0x0001, this.TAG, 'Promise scan result error');
            }
          }).catch((failResult: BusinessError) => {
            hilog.error(0x0001, this.TAG, 'Promise scan result: %{public}s', JSON.stringify(failResult));
          });
        } catch (error) {
          hilog.error(0x0001, this.TAG, 'Catch: failResult: %{public}s', JSON.stringify(error));
        }
      })
    } catch (error) {
      hilog.error(0x0001, this.TAG, 'error : %{public}s', error)
    }
  }

  build() {
    Stack() {
      if (this.userGrant) {
        Column() {
          XComponent({
            id: 'componentId',
            type: 'surface',
            controller: this.mXComponentController
          })
            .onLoad(async () => {
              hilog.info(0x0001, this.TAG, 'onLoad is called');
              // 获取XComponent组件的surfaceId
              this.surfaceId = this.mXComponentController.getXComponentSurfaceId();
              hilog.info(0x0001, this.TAG, 'surfaceId: %{public}s ', this.surfaceId)
              let viewControl: customScan.ViewControl = {
                width: this.cameraWidth,
                height: this.cameraHeight,
                surfaceId: this.surfaceId
              };
              // 扫码结果放置到回调中处理
              try {
                customScan.start(viewControl, this.callback);
                this.isFlashLightEnable = true;
              } catch (error) {
                hilog.error(0x0001, this.TAG, 'start fail, error: %{public}s ', JSON.stringify(error));
              }
            })// XComponent宽、高，默认单位vp，支持px、lpx、vp
            .height(this.cameraHeight)
            .width(this.cameraWidth)
            .position({ x: 0, y: 0 })
            .layoutWeight(1)
        }
        .height('100%')
        .width('100%')
      }


      Column() {
        Canvas(this.contextGesture)// .width(this.cWidth)
          // .height(this.cHeight)
          .width('100%')
          .height('100%')
          .onReady(() => {
            console.error('whh:', 'onReady')
            setTimeout(() => {
              const rectInfo = Utils.getComponentRect('zxing_code_bg')
              this.topLeftPoint = [px2vp(Utils.rect_left), px2vp(Utils.rect_top)]
              this.topRightPoint = [px2vp(Utils.rect_right), px2vp(Utils.rect_top)]
              this.bottomLeftPoint = [px2vp(Utils.rect_left), px2vp(Utils.rect_bottom)]
              this.bottomRightPoint = [px2vp(Utils.rect_right), px2vp(Utils.rect_bottom)]
              console.error('whh:', 'rectInfo', JSON.stringify(rectInfo))
              this.drawTransparentBackground()
            }, 500)

          })
      }.width('100%')
      .height('100%')
      .layoutWeight(1)

      Column() {
        Column()
          .layoutWeight(1)
        Stack() {
          Image($r('app.media.zxing_code_bg'))
            .width(240).height(240)
            .id('zxing_code_bg')
          Column() {
            Column().height(this.line_percent)
            Image($r('app.media.zxing_line'))
              .width('240')
          }.layoutWeight(1)
          .width('240')
          .height(240)

        }

        Column() {
          Text('请将二维码放于框内，自动扫描')
            .margin({ top: 23 })
            .fontSize(17)
            .fontColor('#CACACA')
          Row() {
            Column() {
              Image($r('app.media.xiangce'))
                .width(26)
                .height(25)
                .objectFit(ImageFit.Contain)
                .margin({ top: 3 })
              Text('相册')
                .fontSize(11)
                .fontColor(Color.White)
                .margin({ top: 12 })
            }.padding(10)
            .onClick(() => {
              this.selectPicFromAlbum()
            })

            Column() {
              Image($r('app.media.shoudiantong'))
                .width(20)
                .height(29)
                .objectFit(ImageFit.Contain)
                .margin({ top: 3 })
              Text('手电筒')
                .fontSize(11)
                .fontColor(Color.White)
                .margin({ top: 12 })
            }.margin({ left: 87 })
            .padding(10).onClick(() => {
              // 根据当前闪光灯状态，选择打开或关闭闪关灯
              try {
                if (customScan.getFlashLightStatus()) {
                  customScan.closeFlashLight();
                } else {
                  customScan.openFlashLight();
                }
              } catch (error) {
                hilog.error(0x0001, this.TAG, 'flashLight control failed, error: %{public}s ', JSON.stringify(error));
              }
            })
          }
          .margin({ top: 90 })

        }.width('100%').layoutWeight(2)

      }.width('100%')
      .height('100%')
      .layoutWeight(1)
    }
    // 建议相机流设置为全屏
    .width('100%')
    .height('100%')
    .layoutWeight(1)
  }
}