/**
 *
 * @author 王洪贺
 * @date 2024/2/20 15:46
 */

export class Utils {
  static rect_left: number
  static rect_top: number
  static rect_right: number
  static rect_bottom: number
  static rect_value: Record<string, number>

  /**获取组件所占矩形区域坐标
   * @param key 组件的id
   * @returns 返回组件所占矩形区域坐标
   */
  static getComponentRect(key: string): Record<string, number> {
    let strJson = getInspectorByKey(key)
    let obj: Record<string, string> = JSON.parse(strJson)
    console.info("[getInspectorByKey] current component obj is: " + JSON.stringify(obj))
    let rectInfo: string[] = JSON.parse('[' + obj.$rect + ']')
    console.info("[getInspectorByKey] rectInfo is: " + rectInfo)
    Utils.rect_left = JSON.parse('[' + rectInfo[0] + ']')[0]
    Utils.rect_top = JSON.parse('[' + rectInfo[0] + ']')[1]
    Utils.rect_right = JSON.parse('[' + rectInfo[1] + ']')[0]
    Utils.rect_bottom = JSON.parse('[' + rectInfo[1] + ']')[1]
    return Utils.rect_value = {
      "left": Utils.rect_left,
      "top": Utils.rect_top,
      "right": Utils.rect_right,
      "bottom": Utils.rect_bottom
    }
  }
}