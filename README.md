# IPv6的ddns脚本（dnspod)
## 适用范围
+ 用于openwrt上的一个ddns脚本，理论上linux系统都可以用。
+ 服务商是dnspod，我没有其它服务商，所以只适用dnspod。
## 使用方法
+ 登录dnspod获取`token`和`ID`,设置好一个二级域名`domain`用于ddns。
+ 将`ID`、`token`和`domain`按格式填入config文件中。
+ 给dnspod.sh和record.sh赋权。
```
chmod +x dnspod.sh record.sh
```
+ 运行dnspod.sh
