# 通用（屏幕）侧栏


> 从配置文件，构建快速动作。单列，瀑布型，类似侧栏。简单粗暴。

![](./list-exec.png)

> 配置文件格式，直接看`conf.ini`里面的说明。

> settings的某些函数又废弃了。暂时取消Switch功能。

## 配置文件格式

### 开关
```
[Switch]
SCHEMA_KEY = org.gnome.system.proxy mode
Name = 切换系统代理模式
Follow_execute = 
```
gsettings里面获取。
	
```
⭕ gsettings range org.gnome.system.proxy use-same-proxy
type b
⭕ gsettings describe org.gnome.system.proxy.ftp host
执行 FTP 代理的计算机名。
```
布尔类型。纯开关。描叙文本，只能作为tip使用。
```
⭕ gsettings range org.gnome.system.proxy mode
enum
'none'
'manual'
'auto'
```
枚举类型。多选。

### 选择并执行
```
[Choose]
List = ls -1 ~/bin/vvvv/json/*.json
Exec = sudo pkill -9 v2ray; sudo v2ray $$
Search = true
```
