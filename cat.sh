#1. 打开web debug模式 webview.WebviewController.setWebDebuggingAccess(true)
#2. chrome 访问 chrome://inspect/#devices，在 Discover network targets 中添加 localhost:9222
#3. 运行 cat.sh
#原文链接：https://blog.csdn.net/coooliang/article/details/138001902
name=$(hdc shell ps -ef | grep com.growingio.analytics | awk '{print $2}')
echo "prefix_${name}"
pid=${name##*_}
hdc fport tcp:9222 localabstract:webview_devtools_remote_$pid
