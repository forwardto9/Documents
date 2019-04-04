
早在 Docker 正式发布几个月的时候，LeanCloud 就开始在生产环境大规模使用 Docker，在过去几年里 Docker 的技术栈支撑了我们主要的后端架构。
这是一篇写给程序员的 Docker 和 Kubernetes 教程，目的是让熟悉技术的读者在尽可能短的时间内对 Docker 和 Kubernetes 有基本的了解，并通过实际部署、升级、回滚一个服务体验容器化生产环境的原理和好处。本文假设读者都是开发者，并熟悉 Mac/Linux 环境，所以就不介绍基础的技术概念了。命令行环境以 Mac 示例，在 Linux 下只要根据自己使用的发行版和包管理工具做调整即可。

Docker 速成
首先快速地介绍一下 Docker：作为示例，我们在本地启动 Docker 的守护进程，并在一个容器里运行简单的 HTTP 服务。先完成安装：

$ brew cask install docker
复制代码
上面的命令会从 Homebrew 安装 Docker for Mac，它包含 Docker 的后台进程和命令行工具。Docker 的后台进程以一个 Mac App 的形式安装在 /Applications 里，需要手动启动。启动 Docker 应用后，可以在 Terminal 里确认一下命令行工具的版本：

$ docker --version
Docker version 18.03.1-ce, build 9ee9f40
复制代码
上面显示的 Docker 版本可能和我的不一样，但只要不是太老就好。我们建一个单独的目录来存放示例所需的文件。为了尽量简化例子，我们要部署的服务是用 Nginx 来 serve 一个简单的 HTML 文件 html/index.html。

$ mkdir docker-demo
$ cd docker-demo
$ mkdir html
$ echo '<h1>Hello Docker!</h1>' > html/index.html
复制代码
接下来在当前目录创建一个叫 Dockerfile 的新文件，包含下面的内容：

FROM nginx
COPY html/* /usr/share/nginx/html
复制代码
每个 Dockerfile 都以 FROM ... 开头。FROM nginx 的意思是以 Nginx 官方提供的镜像为基础来构建我们的镜像。在构建时，Docker 会从 Docker Hub 查找和下载需要的镜像。Docker Hub 对于 Docker 镜像的作用就像 GitHub 对于代码的作用一样，它是一个托管和共享镜像的服务。使用过和构建的镜像都会被缓存在本地。第二行把我们的静态文件复制到镜像的 /usr/share/nginx/html 目录下。也就是 Nginx 寻找静态文件的目录。Dockerfile 包含构建镜像的指令，更详细的信息可以参考这里。

然后就可以构建镜像了：

$ docker build -t docker-demo:0.1 .
复制代码
请确保你按照上面的步骤为这个实验新建了目录，并且在这个目录中运行 docker build。如果你在其它有很多文件的目录（比如你的用户目录或者 /tmp ）运行，docker 会把当前目录的所有文件作为上下文发送给负责构建的后台进程。

这行命令中的名称 docker-demo 可以理解为这个镜像对应的应用名或服务名，0.1 是标签。Docker 通过名称和标签的组合来标识镜像。可以用下面的命令来看到刚刚创建的镜像：

$ docker image ls
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
docker-demo         0.1                 efb8ca048d5a        5 minutes ago       109MB
复制代码
下面我们把这个镜像运行起来。Nginx 默认监听在 80 端口，所以我们把宿主机的 8080 端口映射到容器的 80 端口：

$ docker run --name docker-demo -d -p 8080:80 docker-demo:0.1
复制代码
用下面的命令可以看到正在运行中的容器：

$ docker container ps
CONTAINER ID  IMAGE            ...  PORTS                 NAMES
c495a7ccf1c7  docker-demo:0.1  ...  0.0.0.0:8080->80/tcp  docker-demo
复制代码
这时如果你用浏览器访问 http://localhost:8080，就能看到我们刚才创建的「Hello Docker!」页面。

在现实的生产环境中 Docker 本身是一个相对底层的容器引擎，在有很多服务器的集群中，不太可能以上面的方式来管理任务和资源。所以我们需要 Kubernetes 这样的系统来进行任务的编排和调度。在进入下一步前，别忘了把实验用的容器清理掉：

$ docker container stop docker-demo
$ docker container rm docker-demo
复制代码
安装 Kubernetes
介绍完 Docker，终于可以开始试试 Kubernetes 了。我们需要安装三样东西：Kubernetes 的命令行客户端 kubctl、一个可以在本地跑起来的 Kubernetes 环境 Minikube、以及给 Minikube 使用的虚拟化引擎 xhyve。

$ brew install kubectl
$ brew cask install minikube
$ brew install docker-machine-driver-xhyve
复制代码
Minikube 默认的虚拟化引擎是 VirtualBox，而 xhyve 是一个更轻量、性能更好的替代。它需要以 root 权限运行，所以安装完要把所有者改为 root:wheel，并把 setuid 权限打开：

$ sudo chown root:wheel /usr/local/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
$ sudo chmod u+s /usr/local/opt/docker-machine-driver-xhyve/bin/docker-machine-driver-xhyve
复制代码
然后就可以启动 Minikube 了：

$ minikube start --vm-driver xhyve
复制代码
你多半会看到一个警告说 xhyve 会在未来的版本被 hyperkit 替代，推荐使用 hyperkit。不过在我写这个教程的时候 docker-machine-driver-hyperkit 还没有进入 Homebrew, 需要手动编译和安装，我就偷个懒，仍然用 xhyve。以后只要在安装和运行的命令中把 xhyve 改为 hyperkit 就可以。

如果你在第一次启动 Minikube 时遇到错误或被中断，后面重试仍然失败时，可以尝试运行 minikube delete 把集群删除，重新来过。

Minikube 启动时会自动配置 kubectl，把它指向 Minikube 提供的 Kubernetes API 服务。可以用下面的命令确认：

$ kubectl config current-context
minikube
复制代码
Kubernetes 架构简介
典型的 Kubernetes 集群包含一个 master 和很多 node。Master 是控制集群的中心，node 是提供 CPU、内存和存储资源的节点。Master 上运行着多个进程，包括面向用户的 API 服务、负责维护集群状态的 Controller Manager、负责调度任务的 Scheduler 等。每个 node 上运行着维护 node 状态并和 master 通信的 kubelet，以及实现集群网络服务的 kube-proxy。

作为一个开发和测试的环境，Minikube 会建立一个有一个 node 的集群，用下面的命令可以看到：

$ kubectl get nodes
NAME       STATUS    AGE       VERSION
minikube   Ready     1h        v1.10.0
复制代码
部署一个单实例服务
我们先尝试像文章开始介绍 Docker 时一样，部署一个简单的服务。Kubernetes 中部署的最小单位是 pod，而不是 Docker 容器。实时上 Kubernetes 是不依赖于 Docker 的，完全可以使用其他的容器引擎在 Kubernetes 管理的集群中替代 Docker。在与 Docker 结合使用时，一个 pod 中可以包含一个或多个 Docker 容器。但除了有紧密耦合的情况下，通常一个 pod 中只有一个容器，这样方便不同的服务各自独立地扩展。

Minikube 自带了 Docker 引擎，所以我们需要重新配置客户端，让 docker 命令行与 Minikube 中的 Docker 进程通讯：

$ eval $(minikube docker-env)
复制代码
在运行上面的命令后，再运行 docker image ls 时只能看到一些 Minikube 自带的镜像，就看不到我们刚才构建的 docker-demo:0.1 镜像了。所以在继续之前，要重新构建一遍我们的镜像，这里顺便改一下名字，叫它 k8s-demo:0.1。

$ docker build -t k8s-demo:0.1 .
复制代码
然后创建一个叫 pod.yml 的定义文件：

apiVersion: v1
kind: Pod
metadata:
  name: k8s-demo
spec:
  containers:
    - name: k8s-demo
      image: k8s-demo:0.1
      ports:
        - containerPort: 80
复制代码
这里定义了一个叫 k8s-demo 的 Pod，使用我们刚才构建的 k8s-demo:0.1 镜像。这个文件也告诉 Kubernetes 容器内的进程会监听 80 端口。然后把它跑起来：

$ kubectl create -f pod.yml
pod "k8s-demo" created
复制代码
kubectl 把这个文件提交给 Kubernetes API 服务，然后 Kubernetes Master 会按照要求把 Pod 分配到 node 上。用下面的命令可以看到这个新建的 Pod：

$ kubectl get pods
NAME       READY     STATUS    RESTARTS   AGE
k8s-demo   1/1       Running   0          5s
复制代码
因为我们的镜像在本地，并且这个服务也很简单，所以运行 kubectl get pods 的时候 STATUS 已经是 running。要是使用远程镜像（比如 Docker Hub 上的镜像），你看到的状态可能不是 Running，就需要再等待一下。

虽然这个 pod 在运行，但是我们是无法像之前测试 Docker 时一样用浏览器访问它运行的服务的。可以理解为 pod 都运行在一个内网，我们无法从外部直接访问。要把服务暴露出来，我们需要创建一个 Service。Service 的作用有点像建立了一个反向代理和负载均衡器，负责把请求分发给后面的 pod。

创建一个 Service 的定义文件 svc.yml：

apiVersion: v1
kind: Service
metadata:
  name: k8s-demo-svc
  labels:
    app: k8s-demo
spec:
  type: NodePort
  ports:
    - port: 80
      nodePort: 30050
  selector:
    app: k8s-demo
复制代码
这个 service 会把容器的 80 端口从 node 的 30050 端口暴露出来。注意文件最后两行的 selector 部分，这里决定了请求会被发送给集群里的哪些 pod。这里的定义是所有包含「app: k8s-demo」这个标签的 pod。然而我们之前部署的 pod 并没有设置标签：

$ kubectl describe pods | grep Labels
Labels:		<none>
复制代码
所以要先更新一下 pod.yml，把标签加上（注意在 metadata: 下增加了 labels 部分）：

apiVersion: v1
kind: Pod
metadata:
  name: k8s-demo
  labels:
    app: k8s-demo
spec:
  containers:
    - name: k8s-demo
      image: k8s-demo:0.1
      ports:
        - containerPort: 80
复制代码
然后更新 pod 并确认成功新增了标签：

$ kubectl apply -f pod.yml
pod "k8s-demo" configured
$ kubectl describe pods | grep Labels
Labels:		app=k8s-demo
复制代码
然后就可以创建这个 service 了：

$ kubectl create -f svc.yml
service "k8s-demo-svc" created
复制代码
用下面的命令可以得到暴露出来的 URL，在浏览器里访问，就能看到我们之前创建的网页了。

$ minikube service k8s-demo-svc --url
http://192.168.64.4:30050
复制代码
横向扩展、滚动更新、版本回滚
在这一节，我们来实验一下在一个高可用服务的生产环境会常用到的一些操作。在继续之前，先把刚才部署的 pod 删除（但是保留 service，下面还会用到）：

$ kubectl delete pod k8s-demo
pod "k8s-demo" deleted
复制代码
在正式环境中我们需要让一个服务不受单个节点故障的影响，并且还要根据负载变化动态调整节点数量，所以不可能像上面一样逐个管理 pod。Kubernetes 的用户通常是用 Deployment 来管理服务的。一个 deployment 可以创建指定数量的 pod 部署到各个 node 上，并可完成更新、回滚等操作。

首先我们创建一个定义文件 deployment.yml：

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: k8s-demo-deployment
spec:
  replicas: 10
  template:
    metadata:
      labels:
        app: k8s-demo
    spec:
      containers:
        - name: k8s-demo-pod
          image: k8s-demo:0.1
          ports:
            - containerPort: 80
复制代码
注意开始的 apiVersion 和之前不一样，因为 Deployment API 没有包含在 v1 里，replicas: 10 指定了这个 deployment 要有 10 个 pod，后面的部分和之前的 pod 定义类似。提交这个文件，创建一个 deployment：

$ kubectl create -f deployment.yml
deployment "k8s-demo-deployment" created
复制代码
用下面的命令可以看到这个 deployment 的副本集（replica set），有 10 个 pod 在运行。

$ kubectl get rs
NAME                             DESIRED   CURRENT   READY     AGE
k8s-demo-deployment-774878f86f   10        10        10        19s
复制代码
假设我们对项目做了一些改动，要发布一个新版本。这里作为示例，我们只把 HTML 文件的内容改一下, 然后构建一个新版镜像 k8s-demo:0.2：

$ echo '<h1>Hello Kubernetes!</h1>' > html/index.html
$ docker build -t k8s-demo:0.2 .
复制代码
然后更新 deployment.yml：

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: k8s-demo-deployment
spec:
  replicas: 10
  minReadySeconds: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    metadata:
      labels:
        app: k8s-demo
    spec:
      containers:
        - name: k8s-demo-pod
          image: k8s-demo:0.2
          ports:
            - containerPort: 80
复制代码
这里有两个改动，第一个是更新了镜像版本号 image: k8s-demo:0.2，第二是增加了 minReadySeconds: 10 和 strategy 部分。新增的部分定义了更新策略：minReadySeconds: 10 指在更新了一个 pod 后，需要在它进入正常状态后 10 秒再更新下一个 pod；maxUnavailable: 1 指同时处于不可用状态的 pod 不能超过一个；maxSurge: 1 指多余的 pod 不能超过一个。这样 Kubernetes 就会逐个替换 service 后面的 pod。运行下面的命令开始更新：

$ kubectl apply -f deployment.yml --record=true
deployment "k8s-demo-deployment" configured
复制代码
这里的 --record=true 让 Kubernetes 把这行命令记到发布历史中备查。这时可以马上运行下面的命令查看各个 pod 的状态：

$ kubectl get pods
NAME                                   READY  STATUS        ...   AGE
k8s-demo-deployment-774878f86f-5wnf4   1/1    Running       ...   7m
k8s-demo-deployment-774878f86f-6kgjp   0/1    Terminating   ...   7m
k8s-demo-deployment-774878f86f-8wpd8   1/1    Running       ...   7m
k8s-demo-deployment-774878f86f-hpmc5   1/1    Running       ...   7m
k8s-demo-deployment-774878f86f-rd5xw   1/1    Running       ...   7m
k8s-demo-deployment-774878f86f-wsztw   1/1    Running       ...   7m
k8s-demo-deployment-86dbd79ff6-7xcxg   1/1    Running       ...   14s
k8s-demo-deployment-86dbd79ff6-bmvd7   1/1    Running       ...   1s
k8s-demo-deployment-86dbd79ff6-hsjx5   1/1    Running       ...   26s
k8s-demo-deployment-86dbd79ff6-mkn27   1/1    Running       ...   14s
k8s-demo-deployment-86dbd79ff6-pkmlt   1/1    Running       ...   1s
k8s-demo-deployment-86dbd79ff6-thh66   1/1    Running       ...   26s
复制代码
从 AGE 列就能看到有一部分 pod 是刚刚新建的，有的 pod 则还是老的。下面的命令可以显示发布的实时状态：

$ kubectl rollout status deployment k8s-demo-deployment
Waiting for rollout to finish: 1 old replicas are pending termination...
Waiting for rollout to finish: 1 old replicas are pending termination...
deployment "k8s-demo-deployment" successfully rolled out
复制代码
由于我输入得比较晚，发布已经快要结束，所以只有三行输出。下面的命令可以查看发布历史，因为第二次发布使用了 --record=true 所以可以看到用于发布的命令。

$ kubectl rollout history deployment k8s-demo-deployment
deployments "k8s-demo-deployment"
REVISION	CHANGE-CAUSE
1		<none>
2		kubectl apply --filename=deploy.yml --record=true
复制代码
这时如果刷新浏览器，就可以看到更新的内容「Hello Kubernetes!」。假设新版发布后，我们发现有严重的 bug，需要马上回滚到上个版本，可以用这个很简单的操作：

$ kubectl rollout undo deployment k8s-demo-deployment --to-revision=1
deployment "k8s-demo-deployment" rolled back
复制代码
Kubernetes 会按照既定的策略替换各个 pod，与发布新版本类似，只是这次是用老版本替换新版本：

$ kubectl rollout status deployment k8s-demo-deployment
Waiting for rollout to finish: 4 out of 10 new replicas have been updated...
Waiting for rollout to finish: 6 out of 10 new replicas have been updated...
Waiting for rollout to finish: 8 out of 10 new replicas have been updated...
Waiting for rollout to finish: 1 old replicas are pending termination...
deployment "k8s-demo-deployment" successfully rolled out
复制代码
在回滚结束之后，刷新浏览器就可以确认网页内容又改回了「Hello Docker!」。

结语
我们从不同层面实践了一遍镜像的构建和容器的部署，并且部署了一个有 10 个容器的 deployment, 实验了滚动更新和回滚的流程。Kubernetes 提供了非常多的功能，本文只是以走马观花的方式做了一个快节奏的 walkthrough，略过了很多细节。虽然你还不能在简历上加上「精通 Kubernetes」，但是应该可以在本地的 Kubernetes 环境测试自己的前后端项目，遇到具体的问题时求助于 Google 和官方文档即可。在此基础上进一步熟悉应该就可以在别人提供的 Kubernetes 生产环境发布自己的服务。

参考：
https://juejin.im/post/5b62d0356fb9a04fb87767f5
https://www.ibm.com/developerworks/cn/cloud/library/cl-getting-started-docker-and-kubernetes/index.html
