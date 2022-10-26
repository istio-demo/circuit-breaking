# istio 熔断 demo

## 概述

熔断是服务降级的一种方式，在 istio 中，断路器策略分为两类：
1. 连接池限流。限制并发，超过阈值就直接响应 503，不转发给后端。
2. 主动探测，剔除异常后端。后端连续响应5xx状态码，或连续失败或超时，自动摘除一段时间。

下面演示如何在 istio 中配置熔断。

## 下载代码仓库

克隆代码仓库:

```bash
git clone https://github.com/istio-demo/circuit-breaking.git && cd circuit-breaking
```

## 开启 Sidecar 自动注入

将需要部署 demo 的命名空间开启 sidecar 自动注入。

## 安装 demo 应用

确保本地 kubeconfig 配置正常，可以用 kubectl 操作集群，然后执行下面命令将 demo 应用安装到集群中:

```bash
make install
```

## 压测

会安装 httpbin 作为服务端，fortio 作为压测客户端。

执行 `make bench3` 进行压测 (3个并发)，会看到所有请求都成功:

```txt
Code 200 : 200 (100.0 %)
```

## 配置熔断规则

执行以下命令配置熔断规则:

```bash
make dr
```

实际会使用是下面的 `DestinationRule`:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: httpbin
spec:
  host: httpbin
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
```

大概意思是：
* 允许一个并发。
* 后端响应5xx状态码后自动摘除。

## 再次压测

先用 `make bench1` 压测（1个并发）:

可以发现全部请求成功:

```txt
Code 200 : 200 (100.0 %)
```

再用 `make bench2` 压测（2个并发):

```txt
Code 200 : 94 (47.0 %)
Code 503 : 106 (53.0 %)
```

可以接近1半都 503 了，继续加大并发，用 `make bench3` 压测（3个并发）：

```txt
Code 200 : 80 (40.0 %)
Code 503 : 120 (60.0 %)
```

可以看到 503 比例加大，通过查看 access log 可以看出 503 的响应，response_flags 为 "UO"，即触发了断路器导致的 503 响应。