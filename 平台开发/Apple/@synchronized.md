`@synchronized`，同步锁，又名对象锁，由于其使用简单，基本上是在`iOS`开发中使用最频繁的锁。

使用方式如下：

```
@synchronized() {
    // 需要加锁的代码块
}

```

## 原理

那么`@synchronized`到底是如何实现了锁的功能呢？我们看一个例子：

```objective-c
- (void)synchronizedTest {
    @synchronized (self) {
        NSLog(@"====synchronized====");
    }
}

```

对程序设置一个断点，进入汇编，我们可以看到，发生变化的前后包裹了两个方法：

```c
objc_sync_enter
objc_sync_exit
```

或者使用下面代码对程序进行编译：

```shell
clang -x objective-c -rewrite-objc -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk main.m

```



```c
struct _SYNC_EXIT { _SYNC_EXIT(id arg) : sync_exit(arg) {}
	~_SYNC_EXIT() {objc_sync_exit(sync_exit);}
	id sync_exit;
	} _sync_exit(_sync_obj);

        NSLog((NSString *)&__NSConstantStringImpl__var_folders_2v__kb2z6292bg2zwsy41_j6vg40000gn_T_AppDelegate_8c0610_mi_0);
    } catch (id e) {_rethrow = e;}
```

也可以得出，分析的重点应该是以下代码：

```
objc_sync_enter
objc_sync_exit

```

通过符号断点我们可以将上述代码定位到`objc`源码。

```c
// Allocates recursive mutex associated with 'obj' if needed.
int objc_sync_enter(id obj)
{
    int result = OBJC_SYNC_SUCCESS;

    if (obj) {
        SyncData* data = id2data(obj, ACQUIRE);
        assert(data);
        data->mutex.lock();
    } else {
        // @synchronized(nil) does nothing
        if (DebugNilSync) {
            _objc_inform("NIL SYNC DEBUG: @synchronized(nil); set a breakpoint on objc_sync_nil to debug");
        }
        objc_sync_nil();
    }

    return result;
}

BREAKPOINT_FUNCTION(
    void objc_sync_nil(void)
);

```

从代码可以得出以下结论：

- `@synchronized`使用的是递归锁`(recursive mutex)`
- `@synchronized(nil)`不会做任何事情，可以用来防止死递归。

我们再来看看当`obj`存在的时候，`@synchronized`做了什么。

```c
SyncData* data = id2data(obj, ACQUIRE);
```

通过这行代码，可以看出来`obj`是以`SyncData`这种结构来保存的。`SyncData`是一个结构体，具体信息如下：

```c
typedef struct alignas(CacheLineSize) SyncData {
    struct SyncData* nextData;
    DisguisedPtr<objc_object> object;
    int32_t threadCount; 
    recursive_mutex_t mutex;
} SyncData;
```

- `struct SyncData* nextData`：`SyncData`的指针节点，指向下一条数据
- `DisguisedPtr<objc_object> object`：锁住的对象
- `int32_t threadCount`：等待的线程数量
- `recursive_mutex_t mutex`：使用的递归锁

获取`SyncData`结构的数据的流程是怎样的？

1. 如果支持`tls`缓存，从`tls`缓存获取`obj`的相关信息。该方法是检查每个线程单项快速缓存中是否有匹配的对象。

```c
SyncData *data = (SyncData *)tls_get_direct(SYNC_DATA_DIRECT_KEY);
```

此处引入一个概念，`tls`，`Thread Local Storage`，线程局部存储，它是操作系统为线程单独提供的私有空间，通常只有有限的容量。

```c
result = data;
lockCount = (uintptr_t)tls_get_direct(SYNC_COUNT_DIRECT_KEY);
lockCount++;
tls_set_direct(SYNC_COUNT_DIRECT_KEY, (void*)lockCount);
```

此处如果多次进入，也就是递归操作，只会对`lockCount`进行加1操作。

如果获取到数据，说明对象又被加了一次锁，更新`tls`中存储的`obj`信息，锁的次数加1，并将数据返回。如果没有获取到，则进入第二步。

1. 在线程缓存`SyncCache`中查找是否存在`obj`的数据信息。该方法是检查已拥有锁的每个线程高速缓存中是否有匹配的对象。

```c
typedef struct {
    SyncData *data; 
    unsigned int lockCount;  // number of times THIS THREAD locked this block
} SyncCacheItem;

typedef struct SyncCache {
    unsigned int allocated;
    unsigned int used;
    SyncCacheItem list[0];
} SyncCache;

SyncCache *cache = fetch_cache(NO);
SyncCacheItem *item = &cache->list[i];
item->lockCount++;
```

如果存在当前`obj`的数据信息，将线程缓存`SyncCache`中的`obj`的锁的次数加1，并将数据返回。如果没找到就进入第3步。

1. 在使用列表`sDataLists`中查找对象

在列表`sDataLists`中查找，需要对查找过程加锁，防止在多线程查找导致的异常。使用列表`sDataLists`把`SyncData`又做了一层封装，元素是一个结构体`SyncList`。

```c
spinlock_t *lockp = &LOCK_FOR_OBJ(object);
SyncData **listp = &LIST_FOR_OBJ(object);

using spinlock_t = mutex_tt<LOCKDEBUG>;
#define LOCK_FOR_OBJ(obj) sDataLists[obj].lock
#define LIST_FOR_OBJ(obj) sDataLists[obj].data
struct SyncList {
    SyncData *data;
    spinlock_t lock;

    constexpr SyncList() : data(nil), lock(fork_unsafe_lock) { }
};
static StripedMap<SyncList> sDataLists;
```

遍历，进行匹配：

```c
SyncData* p;
SyncData* firstUnused = NULL;
for (p = *listp; p != NULL; p = p->nextData) {
    if ( p->object == object ) {
        result = p;
        OSAtomicIncrement32Barrier(&result->threadCount);
        goto done;
    }
    if ( (firstUnused == NULL) && (p->threadCount == 0) )
        firstUnused = p;
}
```

如果找到，就将数据写入`tls`缓存和线程缓存`SyncCache`，并返回数据。

```c
// 写入tls缓存
tls_set_direct(SYNC_DATA_DIRECT_KEY, result);
tls_set_direct(SYNC_COUNT_DIRECT_KEY, (void*)1);

// 写入线程缓存
if (!cache) cache = fetch_cache(YES);
cache->list[cache->used].data = result;
cache->list[cache->used].lockCount = 1;
cache->used++;

```

1. 创建一个新的`SyncData`放入`sDataLists`中，并存入`tls`缓存和线程缓存中，然后返回。

```c
posix_memalign((void **)&result, alignof(SyncData), sizeof(SyncData));
result->object = (objc_object *)object;
result->threadCount = 1;
// 从这里可以看出来@synchronized其实是一个递归锁
new (&result->mutex) recursive_mutex_t(fork_unsafe_lock);
result->nextData = *listp;
*listp = result;

```

看完了获取锁，我们再来看看释放锁。释放的过程和保存相似。如果传入的对象是空的，也不会做任何事情。

```c
// End synchronizing on 'obj'. 
// Returns OBJC_SYNC_SUCCESS or OBJC_SYNC_NOT_OWNING_THREAD_ERROR
int objc_sync_exit(id obj)
{
    int result = OBJC_SYNC_SUCCESS;
    
    if (obj) {
        SyncData* data = id2data(obj, RELEASE); 
        if (!data) {
            result = OBJC_SYNC_NOT_OWNING_THREAD_ERROR;
        } else {
            bool okay = data->mutex.tryUnlock();
            if (!okay) {
                result = OBJC_SYNC_NOT_OWNING_THREAD_ERROR;
            }
        }
    } else {
        // @synchronized(nil) does nothing
    }
	
    return result;
}
```

如果传入的对象有值：

1. 先从`tls`缓存中查找，如果找到，对锁的计数减1，更新缓存中的数据，如果当前对象对应的锁计数为0了，直接将其从`tls`缓存中删除。

```c
lockCount--;
tls_set_direct(SYNC_COUNT_DIRECT_KEY, (void*)lockCount);
if (lockCount == 0) {
    tls_set_direct(SYNC_DATA_DIRECT_KEY, NULL);                    OSAtomicDecrement32Barrier(&result->threadCount);
}
```

1. 从线程缓存`SyncCache`中查找，如果找到，对锁的计数减1，更新缓存中的数据，如果当前对象对应的锁计数为0了，直接将其从线程缓存`SyncCache`中删除。

```c
item->lockCount--;
if (item->lockCount == 0) {
    cache->list[i] = cache->list[--cache->used];                OSAtomicDecrement32Barrier(&result->threadCount);
}
```

1. 从`sDataLists`查找，找到的话，直接将其置为`nil`。

其实，`@synchronized`就是一个递归锁，其内部维护了一张表用来存储对象和锁的相关信息，加锁和释放锁的操作就是对锁的计数进行操作。

## 注意点

使用`@synchronzied`的需要注意的是

```
for (int i = 0; i < 200000; i++) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        self.mArray = [NSMutableArray array];
    });
}

```

这段代码运行就会崩溃，是因为，我们在不断地创建`array`，`mArray`在不断的赋新值，释放旧值，这个时候多线程操作就会可能存在值已经被释放了，而其他线程还在操作，此时就会发生崩溃。此时就需要我们对程序加锁。将上述程序改成如下：

```objective-c
@synchronized (self.mArray) {
    self.mArray = [NSMutableArray array];
}
```

程序依然会崩溃，原因是`@synchronized`的操作时如果是`nil`，则什么也不做，则可能会出现`锁不住`的情况，同样会导致在释放的时候发现值已经变成`nil`了。那我们应该怎么改呢？

第一种方式就是使用信号量加锁：

```objective-c
dispatch_semaphore_wait(_semp, DISPATCH_TIME_FOREVER);
dispatch_async(dispatch_get_global_queue(0, 0), ^{
    self.mArray = [NSMutableArray array];
    dispatch_semaphore_signal(self.semp);
});
```

第二种直接使用`NSLock`:

```objective-c
NSLock *lock = [[NSLock alloc] init];
for (int i = 0; i < 200000; i++) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [lock lock];
        self.mArray = [NSMutableArray array];
        [lock unlock];
    });
}
```

在平常的开发中我们要慎用`@synchronized(self)`，直接将`self`传入`@synchronized`确实是很简单粗暴的方法，但是这样容易导致死锁的出现。原因是因为`self`很可能会被外部对象访问，被用作`key`来生成锁。两个公共锁交替使用的场景就容易出现死锁。

## 总结

`@synchronized`是递归锁，其实是在底层对`recursive_mutex_t`做了封装和特殊处理。

让`@synchronized`具备处理递归能力的是`lockCount`，让其能够处理多线程的是`threadCount`。

进入代码块的入口是`objc_sync_enter(id obj)`，出口是`objc_sync_enter(id obj)`。

核心的处理如下：

- 如果支持`tls`缓存，就从`tls`缓存中查找对象锁`SyncData`，找到对`lockCount`进行相应的操作
- 如果不支持`tls`缓存，或者从`tls`缓存中未找到，就从线程缓存`SyncCache`中查找，同样，找到对`lockCount`进行相应的操作
- 如果没有缓存命中，就从`sDataLists`链表中查找，找到之后进行相关的操作，并写入`tls`缓存和线程缓存`SyncCache`
- 都没有找到，就创建一个节点，将对象锁`SyncData`插入`sDataLists`，并写入缓存

释放对象操作类似。

需要注意的是`@synchronized`的操作相对其他锁来说对性能消耗比较大，不建议大量使用。另外再某些多线程操作中，`@synchronized`可能存在锁不住的情况。