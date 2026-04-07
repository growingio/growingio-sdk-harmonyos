/**
 * JSON 解析辅助类（TypeScript，非 ArkTS）
 *
 * 目的：在 .ets 测试文件中，JSON.parse() 返回 unknown，即使 as ESObject 也仍会触发
 * arkts-no-any-unknown。通过将 JSON 解析封装在 .ts 文件中，让 TypeScript 处理 any
 * 类型，向 .ets 文件暴露严格类型化的访问接口，从根本上规避该限制。
 */
export class JsonParser {
  private readonly data: Record<string, unknown>

  constructor(jsonStr: string) {
    this.data = JSON.parse(jsonStr) as Record<string, unknown>
  }

  /** 读取字符串字段，字段不存在或非字符串时返回 undefined */
  getString(key: string): string | undefined {
    const val = this.data[key]
    return typeof val === 'string' ? val : undefined
  }

  /** 读取数字字段，字段不存在或非数字时返回 undefined */
  getNumber(key: string): number | undefined {
    const val = this.data[key]
    return typeof val === 'number' ? val : undefined
  }

  /** 判断字段是否存在（不论值为何） */
  hasKey(key: string): boolean {
    return Object.prototype.hasOwnProperty.call(this.data, key)
  }
}
