import { hapTasks } from '@ohos/hvigor-ohos-plugin';
import { PluginConfig, GrowingAnalyticsPlugin } from '@growingio/auto-track-plugin';

const config: PluginConfig = {
    scanFiles: ["src/main/ets/pages/Index"],
}

export default {
    system: hapTasks,  /* Built-in plugin of Hvigor. It cannot be modified. */
    plugins: [GrowingAnalyticsPlugin(config)] // 自定义插件
}