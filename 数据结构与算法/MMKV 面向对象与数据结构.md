# MMKV

## 内存准备

通过 mmap 内存映射文件，提供一段可供随时写入的内存块，App 只管往里面写数据，由操作系统负责将内存回写到文件，不必担心 crash 导致数据丢失。

## 写入优化

标准 protobuf 不提供增量更新的能力，每次写入都必须全量写入。考虑到主要使用场景是频繁地进行写入更新，我们需要有增量更新的能力：将增量 kv 对象序列化后，直接 append 到内存末尾；这样同一个 key 会有新旧若干份数据，最新的数据在最后；那么只需在程序启动第一次打开 mmkv 时，不断用后读入的 value 替换之前的值，就可以保证数据是最新有效的。

## 空间增长

使用 append 实现增量更新带来了一个新的问题，就是不断 append 的话，文件大小会增长得不可控。例如同一个 key 不断更新的话，是可能耗尽几百 M 甚至上 G 空间，而事实上整个 kv 文件就这一个 key，不到 1k 空间就存得下。这明显是不可取的。我们需要在性能和空间上做个折中：以内存 pagesize 为单位申请空间，在空间用尽之前都是 append 模式；当 append 到文件末尾时，进行文件重整、key 排重，尝试序列化保存排重结果；排重后空间还是不够用的话，将文件扩大一倍，直到空间足够。

## iOS OC 接口调用样例

```objective-c
	[MMKV initializeMMKV:nil];
	MMKV *mmkv = [MMKV defaultMMKV];
        
	[mmkv setBool:YES forKey:@"bool"];
	BOOL bValue = [mmkv getBoolForKey:@"bool"];
    
	[mmkv setInt32:-1024 forKey:@"int32"];
	int32_t iValue = [mmkv getInt32ForKey:@"int32"];
        
	[mmkv setString:@"hello, mmkvxxxxxxxxxxx" forKey:@"string"];
	__unused NSString *str = [mmkv getStringForKey:@"string"];
```

## 支持的数据类型

| 数据类型                                    | 内部逻辑                                                     | 条件                               |
| ------------------------------------------- | ------------------------------------------------------------ | ---------------------------------- |
| Bool,Int32,UInt32,Int64,UInt64,Float,Double |                                                              |                                    |
| NSString                                    | 将NSString转换为NSData，tmpData = [str dataUsingEncoding:NSUTF8StringEncoding]; |                                    |
| NSDate                                      | 将NSDate转换为double；double time = oDate.timeIntervalSince1970; |                                    |
| NSData                                      |                                                              |                                    |
| NSArray、NSDictionary                       | 将集合数据类型转换为NSData；auto tmp = [NSKeyedArchiver archivedDataWithRootObject:obj]; | 集合内对的对象需要满足NSCoding协议 |

## 接口设计

setter/getter 的接口设计是参照 NSUserDefault的接口设计

## 数据结构设计

```c++
#ifdef MMKV_APPLE
struct KeyHasher {
    size_t operator()(NSString *key) const { return key.hash; }
};

struct KeyEqualer {
    bool operator()(NSString *left, NSString *right) const {
        if (left == right) {
            return true;
        }
        return ([left isEqualToString:right] == YES);
    }
};

using MMKVVector = std::vector<std::pair<NSString *, mmkv::MMBuffer>>;
using MMKVMap = std::unordered_map<NSString *, mmkv::KeyValueHolder, KeyHasher, KeyEqualer>;
using MMKVMapCrypt = std::unordered_map<NSString *, mmkv::KeyValueHolderCrypt, KeyHasher, KeyEqualer>;
#else
using MMKVVector = std::vector<std::pair<std::string, mmkv::MMBuffer>>;
using MMKVMap = std::unordered_map<std::string, mmkv::KeyValueHolder>;
using MMKVMapCrypt = std::unordered_map<std::string, mmkv::KeyValueHolderCrypt>;
#endif // MMKV_APPLE
```

### MMKV

c++实现，提供给外层OC接口调用

整个文件的数据是创建MMKV实例的时候，从文件中一次性全部加载到m_dic中的

```c++
class MMKV {
#ifndef MMKV_ANDROID
    std::string m_mmapKey;
    MMKV(const std::string &mmapID, MMKVMode mode, std::string *cryptKey, MMKVPath_t *rootPath);
#else // defined(MMKV_ANDROID)
    mmkv::FileLock *m_fileModeLock;
    mmkv::InterProcessLock *m_sharedProcessModeLock;
    mmkv::InterProcessLock *m_exclusiveProcessModeLock;

    MMKV(const std::string &mmapID, int size, MMKVMode mode, std::string *cryptKey, MMKVPath_t *rootPath);

    MMKV(const std::string &mmapID, int ashmemFD, int ashmemMetaFd, std::string *cryptKey = nullptr);
#endif

    ~MMKV();

    std::string m_mmapID;
    MMKVPath_t m_path;
    MMKVPath_t m_crcPath;
    mmkv::MMKVMap *m_dic; // 文件内的全部k、v，（v是数据的结构抽象，而不是实际的data，实际的data需要通过KeyValueHolder的toMMBuffer还原）
    mmkv::MMKVMapCrypt *m_dicCrypt;

    mmkv::MemoryFile *m_file; // 文件操作，其中有mmap等函数的调用，负责提供映射文件到内存的指针等
    size_t m_actualSize;
    mmkv::CodedOutputData *m_output;//在loadFromFile中每次更新，并将其成员指针m_ptr指向mmap映射之后的指针

    bool m_needLoadFromFile;
    bool m_hasFullWriteback;

    uint32_t m_crcDigest;
    mmkv::MemoryFile *m_metaFile;
    mmkv::MMKVMetaInfo *m_metaInfo;

    mmkv::AESCrypt *m_crypter;

    mmkv::ThreadLock *m_lock;
    mmkv::FileLock *m_fileLock;
    mmkv::InterProcessLock *m_sharedProcessLock;
    mmkv::InterProcessLock *m_exclusiveProcessLock;

#ifdef MMKV_APPLE
    using MMKVKey_t = NSString *__unsafe_unretained;
    static bool isKeyEmpty(MMKVKey_t key) { return key.length <= 0; }
#else
    using MMKVKey_t = const std::string &;
    static bool isKeyEmpty(MMKVKey_t key) { return key.empty(); }
#endif

    void loadFromFile();

    void partialLoadFromFile();

    void checkDataValid(bool &loadFromFile, bool &needFullWriteback);

    void checkLoadData();

    bool isFileValid();

    bool checkFileCRCValid(size_t actualSize, uint32_t crcDigest);

    void recaculateCRCDigestWithIV(const void *iv);

    void updateCRCDigest(const uint8_t *ptr, size_t length);

    size_t readActualSize();

    void oldStyleWriteActualSize(size_t actualSize);

    bool writeActualSize(size_t size, uint32_t crcDigest, const void *iv, bool increaseSequence);

    bool ensureMemorySize(size_t newSize);

    bool fullWriteback(mmkv::AESCrypt *newCrypter = nullptr);

    bool doFullWriteBack(std::pair<mmkv::MMBuffer, size_t> preparedData, mmkv::AESCrypt *newCrypter);

    mmkv::MMBuffer getDataForKey(MMKVKey_t key);

    // isDataHolder: avoid memory copying
    bool setDataForKey(mmkv::MMBuffer &&data, MMKVKey_t key, bool isDataHolder = false);

    bool removeDataForKey(MMKVKey_t key);

    using KVHolderRet_t = std::pair<bool, mmkv::KeyValueHolder>;
    // isDataHolder: avoid memory copying
    KVHolderRet_t doAppendDataWithKey(const mmkv::MMBuffer &data, const mmkv::MMBuffer &key, bool isDataHolder, uint32_t keyLength);
    KVHolderRet_t appendDataWithKey(const mmkv::MMBuffer &data, MMKVKey_t key, bool isDataHolder = false);
    KVHolderRet_t appendDataWithKey(const mmkv::MMBuffer &data, const mmkv::KeyValueHolder &kvHolder, bool isDataHolder = false);
#ifdef MMKV_APPLE
    KVHolderRet_t appendDataWithKey(const mmkv::MMBuffer &data,
                                    MMKVKey_t key,
                                    const mmkv::KeyValueHolderCrypt &kvHolder,
                                    bool isDataHolder = false);
#endif

    void notifyContentChanged();

#if defined(MMKV_ANDROID) && !defined(MMKV_DISABLE_CRYPT)
    void checkReSetCryptKey(int fd, int metaFD, std::string *cryptKey);
#endif

public:
    // call this before getting any MMKV instance
    static void initializeMMKV(const MMKVPath_t &rootDir, MMKVLogLevel logLevel = MMKVLogInfo);

#ifdef MMKV_APPLE
    // protect from some old code that don't call initializeMMKV()
    static void minimalInit(MMKVPath_t defaultRootDir);
#endif

    // a generic purpose instance
    static MMKV *defaultMMKV(MMKVMode mode = MMKV_SINGLE_PROCESS, std::string *cryptKey = nullptr);

#ifndef MMKV_ANDROID

    // mmapID: any unique ID (com.tencent.xin.pay, etc)
    // if you want a per-user mmkv, you could merge user-id within mmapID
    // cryptKey: 16 bytes at most
    static MMKV *mmkvWithID(const std::string &mmapID,
                            MMKVMode mode = MMKV_SINGLE_PROCESS,
                            std::string *cryptKey = nullptr,
                            MMKVPath_t *rootPath = nullptr);

#else // defined(MMKV_ANDROID)

    // mmapID: any unique ID (com.tencent.xin.pay, etc)
    // if you want a per-user mmkv, you could merge user-id within mmapID
    // cryptKey: 16 bytes at most
    static MMKV *mmkvWithID(const std::string &mmapID,
                            int size = mmkv::DEFAULT_MMAP_SIZE,
                            MMKVMode mode = MMKV_SINGLE_PROCESS,
                            std::string *cryptKey = nullptr,
                            MMKVPath_t *rootPath = nullptr);

    static MMKV *mmkvWithAshmemFD(const std::string &mmapID, int fd, int metaFD, std::string *cryptKey = nullptr);

    int ashmemFD();

    int ashmemMetaFD();

    bool checkProcessMode();
#endif // MMKV_ANDROID

    // you can call this on application termination, it's totally fine if you don't call
    static void onExit();

    const std::string &mmapID() const;

    const bool m_isInterProcess;

#ifndef MMKV_DISABLE_CRYPT
    std::string cryptKey() const;

    // transform plain text into encrypted text, or vice versa with empty cryptKey
    // you can change existing crypt key with different cryptKey
    bool reKey(const std::string &cryptKey);

    // just reset cryptKey (will not encrypt or decrypt anything)
    // usually you should call this method after other process reKey() the multi-process mmkv
    void checkReSetCryptKey(const std::string *cryptKey);
#endif

    bool set(bool value, MMKVKey_t key);

    bool set(int32_t value, MMKVKey_t key);

    bool set(uint32_t value, MMKVKey_t key);

    bool set(int64_t value, MMKVKey_t key);

    bool set(uint64_t value, MMKVKey_t key);

    bool set(float value, MMKVKey_t key);

    bool set(double value, MMKVKey_t key);

    // avoid unexpected type conversion (pointer to bool, etc)
    template <typename T>
    bool set(T value, MMKVKey_t key) = delete;

#ifdef MMKV_APPLE
    bool set(NSObject<NSCoding> *__unsafe_unretained obj, MMKVKey_t key);

    NSObject *getObject(MMKVKey_t key, Class cls);
#else  // !defined(MMKV_APPLE)
    bool set(const char *value, MMKVKey_t key);

    bool set(const std::string &value, MMKVKey_t key);

    bool set(const mmkv::MMBuffer &value, MMKVKey_t key);

    bool set(const std::vector<std::string> &vector, MMKVKey_t key);

    bool getString(MMKVKey_t key, std::string &result);

    mmkv::MMBuffer getBytes(MMKVKey_t key);

    bool getVector(MMKVKey_t key, std::vector<std::string> &result);
#endif // MMKV_APPLE

    bool getBool(MMKVKey_t key, bool defaultValue = false);

    int32_t getInt32(MMKVKey_t key, int32_t defaultValue = 0);

    uint32_t getUInt32(MMKVKey_t key, uint32_t defaultValue = 0);

    int64_t getInt64(MMKVKey_t key, int64_t defaultValue = 0);

    uint64_t getUInt64(MMKVKey_t key, uint64_t defaultValue = 0);

    float getFloat(MMKVKey_t key, float defaultValue = 0);

    double getDouble(MMKVKey_t key, double defaultValue = 0);

    // return the actual size consumption of the key's value
    // pass actualSize = true to get value's length
    size_t getValueSize(MMKVKey_t key, bool actualSize);

    // return size written into buffer
    // return -1 on any error
    int32_t writeValueToBuffer(MMKVKey_t key, void *ptr, int32_t size);

    bool containsKey(MMKVKey_t key);

    size_t count();

    size_t totalSize();

    size_t actualSize();

#ifdef MMKV_APPLE
    NSArray *allKeys();

    void removeValuesForKeys(NSArray *arrKeys);

    typedef void (^EnumerateBlock)(NSString *key, BOOL *stop);
    void enumerateKeys(EnumerateBlock block);

#    ifdef MMKV_IOS
    static void setIsInBackground(bool isInBackground);
    static bool isInBackground();
#    endif
#else  // !defined(MMKV_APPLE)
    std::vector<std::string> allKeys();

    void removeValuesForKeys(const std::vector<std::string> &arrKeys);
#endif // MMKV_APPLE

    void removeValueForKey(MMKVKey_t key);

    void clearAll();

    // MMKV's size won't reduce after deleting key-values
    // call this method after lots of deleting if you care about disk usage
    // note that `clearAll` has the similar effect of `trim`
    void trim();

    // call this method if the instance is no longer needed in the near future
    // any subsequent call to the instance is undefined behavior
    void close();

    // call this method if you are facing memory-warning
    // any subsequent call to the instance will load all key-values from file again
    void clearMemoryCache();

    // you don't need to call this, really, I mean it
    // unless you worry about running out of battery
    void sync(SyncFlag flag = MMKV_SYNC);

    // get exclusive access
    void lock();
    void unlock();
    bool try_lock();

    // check if content been changed by other process
    void checkContentChanged();

    // called when content is changed by other process
    // doesn't guarantee real-time notification
    static void registerContentChangeHandler(mmkv::ContentChangeHandler handler);
    static void unRegisterContentChangeHandler();

    // by default MMKV will discard all datas on failure
    // return `OnErrorRecover` to recover any data from file
    static void registerErrorHandler(mmkv::ErrorHandler handler);
    static void unRegisterErrorHandler();

    // MMKVLogInfo by default
    // pass MMKVLogNone to disable all logging
    static void setLogLevel(MMKVLogLevel level);

    // by default MMKV will print log to the console
    // implement this method to redirect MMKV's log
    static void registerLogHandler(mmkv::LogHandler handler);
    static void unRegisterLogHandler();

    static bool isFileValid(const std::string &mmapID, MMKVPath_t *relatePath = nullptr);

    // just forbid it for possibly misuse
    explicit MMKV(const MMKV &other) = delete;
    MMKV &operator=(const MMKV &other) = delete;
}
```





### MMBuffer

数据在内存中的数据结构模型，根据数据类型大小开辟内存空间

```c++
class MMBuffer {
    enum MMBufferType : uint8_t {
        MMBufferType_Small,  // store small buffer in stack memory
        MMBufferType_Normal, // store in heap memory
    };
    MMBufferType type;

    union {
        struct {
            MMBufferCopyFlag isNoCopy;
            size_t size;  //数据内存大小
            void *ptr;    //数据内存指针
#ifdef MMKV_APPLE
            NSData *m_data; // Apple平台为nil
#endif
        };
        struct {
            uint8_t paddedSize;
            // make at least 10 bytes to hold all primitive types (negative int32, int64, double etc) on 32 bit device
            // on 64 bit device it's guaranteed larger than 10 bytes
            uint8_t paddedBuffer[10];
        };
    };

    static constexpr size_t SmallBufferSize() {
        return sizeof(MMBuffer) - offsetof(MMBuffer, paddedBuffer);
    }

public:
    explicit MMBuffer(size_t length = 0);
    MMBuffer(void *source, size_t length, MMBufferCopyFlag flag = MMBufferCopy);
#ifdef MMKV_APPLE
	  // 对于Apple平台来说，NSString和集合集合类型都转化为NSData类进行内存数据结构抽象
    explicit MMBuffer(NSData *data, MMBufferCopyFlag flag = MMBufferCopy); 
#endif

    MMBuffer(MMBuffer &&other) noexcept;
    MMBuffer &operator=(MMBuffer &&other) noexcept;

    ~MMBuffer();

    void *getPtr() const { return (type == MMBufferType_Small) ? (void *) paddedBuffer : ptr; }

    size_t length() const { return (type == MMBufferType_Small) ? paddedSize : size; }

    // transfer ownership to others
    void detach();

    // those are expensive, just forbid it for possibly misuse
    explicit MMBuffer(const MMBuffer &other) = delete;
    MMBuffer &operator=(const MMBuffer &other) = delete;

#ifndef MMKV_DISABLE_CRYPT
    friend KeyValueHolderCrypt;
#endif
};
```

### CodedOutputData

1. 对于对象类型，首先将对应类型转换为NSData实例，然后将NSData类型再转换为MMBuffer类型

2. 对于简单数据类型，通过将v占用内存的大小转换为MMBuffer类型，然后将MMBuffer实例和v占用的内存大小作为初始化 CodedOutputData 实例的参数，最后通过 CodedOutputData 实例的 write 方法，将v写入到 CodedOutputData 实例指针中

3. 通过调用MMKV的setDataForKey方法，其中再调用MMKV的appendDataWithKey方法（返回KVHolderRet_t类型，是MMKV中m_dic的数据类型），在其中将string类型的key（如果k、v不存在）或者是KeyValueHolder类型（如果k、v存在，先通过getMemory获取到mmap指针+加上偏移量等）的key转换为MMBuffer实例，然后调用MMKV的doAppendDataWithKey方法，在这个方法中调用ensureMemorySize，ensureMemorySize中为一个新的kv开辟内存(放入m_dic中)并调用MMKV的doFullWriteBack方法，doFullWriteBack里每次都要创建一个CodedOutputData实例并调用MMKV的memmoveDictionary方法，memmoveDictionary将负责把CodedOutputData实例关联的数据内存空间放入m_dic中，doFullWriteBack中最后调用MMKV的sync方法，sync调用了MemoryFile的msync方法将内存映射到文件中。然后doAppendDataWithKey中因有了可用的内存，再调用MMKV的CodedOutputData实例的write方法，将数据写入内存；在setDataForKey中最后判断如果不存在k、v，则调用emplace方法，将k、v放入MMKV的m_dic中

4. CodedOutputData 实例的write方法中写入数据的方式是指针赋值：m_ptr[m_position++] = value， m_ptr与mmap映射文件的指针是同一个地址

    

```c++
class CodedOutputData {
    uint8_t *const m_ptr;
    size_t m_size;
    size_t m_position;

public:
    CodedOutputData(void *ptr, size_t len);

    size_t spaceLeft();

    uint8_t *curWritePointer();

    void seek(size_t addedSize);

    void writeRawByte(uint8_t value);

    void writeRawLittleEndian32(int32_t value);

    void writeRawLittleEndian64(int64_t value);

    void writeRawVarint32(int32_t value);

    void writeRawVarint64(int64_t value);

    void writeRawData(const MMBuffer &data);

    void writeDouble(double value);

    void writeFloat(float value);

    void writeInt64(int64_t value);

    void writeUInt64(uint64_t value);

    void writeInt32(int32_t value);

    void writeUInt32(uint32_t value);

    void writeBool(bool value);

    void writeData(const MMBuffer &value);

#ifndef MMKV_APPLE
    void writeString(const std::string &value);
#endif
};
```

### CodedInputData

在初始化MMKV实例的时候，调用loadFromFile，通过 MiniPBCoder 的 decodeMap 方法将数据放入到 MMKVMap 类型的m_dic中。

1. 如果存在k、v，则根据key从 m_dic 中取出游标itr，在通过 itr->second 取出v的 KeyValueHolder 的实例，并通过 KeyValueHolder 的成员方法toMMBuffer转换成MMBuffer实例返回
2. 如果是基本数据类型，则将1中返回的 MMBuffer 实例作为创建 CodedInputData 实例的参数，通过此 CodedInputData 实例的 read 方法获取到值；如果是NSObject类型，则将1中返回的 MMBuffer 实例和需要解析为具体类型的 Class 作为参数，传递给 MiniPBCoder 的 decodeObject 方法，然后在decodeObject方法中将这两个参数作为创建 CodedInputData 实例的参数，通过read方法获取到值（支持的反解类型是NSString、NSMutableString、NSData、NSMutableData、NSDate）；对于其他满足NSCoding协议的类型，通过 [NSKeyedUnarchiver unarchiveObjectWithData:tmp]获取到值

```c++
class CodedInputData {
    uint8_t *const m_ptr;
    size_t m_size;
    size_t m_position;

    int8_t readRawByte();

    int32_t readRawVarint32();

    int32_t readRawLittleEndian32();

    int64_t readRawLittleEndian64();

public:
    CodedInputData(const void *oData, size_t length);

    bool isAtEnd() const { return m_position == m_size; };

    void seek(size_t addedSize);

    bool readBool();

    double readDouble();

    float readFloat();

    int64_t readInt64();

    uint64_t readUInt64();

    int32_t readInt32();

    uint32_t readUInt32();

    MMBuffer readData();
    void readData(KeyValueHolder &kvHolder);

#ifndef MMKV_APPLE
    std::string readString();
    std::string readString(KeyValueHolder &kvHolder);
#else
    NSString *readString();
    NSString *readString(KeyValueHolder &kvHolder);
    NSData *readNSData();
#endif
};
```

### MiniPBCoder

1. 在初始化MMKV实例时，通过 decodeOneMap 方法文件中存储的k、v写入到内存中
2. 通过对 CodedInputData 实例方法的调用，反解出对象类型的数据的值

```c++
class MiniPBCoder {
    const MMBuffer *m_inputBuffer = nullptr;
    CodedInputData *m_inputData = nullptr;
    CodedInputDataCrypt *m_inputDataDecrpt = nullptr;

    MMBuffer *m_outputBuffer = nullptr;
    CodedOutputData *m_outputData = nullptr;
    std::vector<PBEncodeItem> *m_encodeItems = nullptr;

    MiniPBCoder();
    explicit MiniPBCoder(const MMBuffer *inputBuffer, AESCrypt *crypter = nullptr);
    ~MiniPBCoder();

    void writeRootObject();

    size_t prepareObjectForEncode(const MMKVVector &vec);
    size_t prepareObjectForEncode(const MMBuffer &buffer);

    template <typename T>
    MMBuffer getEncodeData(const T &obj) {
        size_t index = prepareObjectForEncode(obj);
        return writePreparedItems(index);
    }

    MMBuffer writePreparedItems(size_t index);

    void decodeOneMap(MMKVMap &dic, size_t position, bool greedy);
#ifndef MMKV_DISABLE_CRYPT
    void decodeOneMap(MMKVMapCrypt &dic, size_t position, bool greedy);
#endif

#ifndef MMKV_APPLE
    size_t prepareObjectForEncode(const std::string &str);
    size_t prepareObjectForEncode(const std::vector<std::string> &vector);

    std::vector<std::string> decodeOneVector();
#else
    // NSString, NSData, NSDate
    size_t prepareObjectForEncode(__unsafe_unretained NSObject *obj);
#endif

public:
    template <typename T>
    static MMBuffer encodeDataWithObject(const T &obj) {
        try {
            MiniPBCoder pbcoder;
            return pbcoder.getEncodeData(obj);
        } catch (const std::exception &exception) {
            MMKVError("%s", exception.what());
            return MMBuffer();
        }
    }

    // opt encoding a single MMBuffer
    static MMBuffer encodeDataWithObject(const MMBuffer &obj);

    // return empty result if there's any error
    static void decodeMap(MMKVMap &dic, const MMBuffer &oData, size_t position = 0);

    // decode as much data as possible before any error happens
    static void greedyDecodeMap(MMKVMap &dic, const MMBuffer &oData, size_t position = 0);

#ifndef MMKV_DISABLE_CRYPT
    // return empty result if there's any error
    static void decodeMap(MMKVMapCrypt &dic, const MMBuffer &oData, AESCrypt *crypter, size_t position = 0);

    // decode as much data as possible before any error happens
    static void greedyDecodeMap(MMKVMapCrypt &dic, const MMBuffer &oData, AESCrypt *crypter, size_t position = 0);
#endif // MMKV_DISABLE_CRYPT

#ifndef MMKV_APPLE
    static std::vector<std::string> decodeVector(const MMBuffer &oData);
#else
    // NSString, NSData, NSDate
    static NSObject *decodeObject(const MMBuffer &oData, Class cls);

    static bool isCompatibleClass(Class cls);
#endif

    // just forbid it for possibly misuse
    explicit MiniPBCoder(const MiniPBCoder &other) = delete;
    MiniPBCoder &operator=(const MiniPBCoder &other) = delete;
};
```



### KeyValueHolder

k、v数据结构的抽象，MMKV中的m_dic中的一个值类型，这个类型描述了k、v的大小和在文件中的偏移位置。这样的设计是巧妙的，因为在实际的业务场景下，k的长度是远远低于v的长度的，将k、v再次抽象出一层，从而可以在MMKV实例初始化的时候，将文件内的k、v属性结构读入到m_dic中，当getter的时候，获取到值的属性结构，然后再去mmap映射的指针中获取值。

在m_dic中根据key获取到KeyValueHolder实例，然后通过实例的toMMBuffer方法(内存指针+数据块偏移量(KeyValueHolder属性)+数据块大小(KeyValueHolder属性))读取到需要的值，这里是一种灵活滑动指针获取值的方式。

```c++
struct KeyValueHolder {
    uint16_t computedKVSize; // internal use only
    uint16_t keySize;
    uint32_t valueSize;
    uint32_t offset;

    KeyValueHolder() = default;
    KeyValueHolder(uint32_t keyLength, uint32_t valueLength, uint32_t offset);

    MMBuffer toMMBuffer(const void *basePtr) const;
}
```



## 核心接口

### 将文件中的数据加载到内存

```c++
void MemoryFile::reloadFromFile() {
#    ifdef MMKV_ANDROID
    if (m_fileType == MMFILE_TYPE_ASHMEM) {
        return;
    }
#    endif
    if (isFileValid()) {
        MMKVWarning("calling reloadFromFile while the cache [%s] is still valid", m_name.c_str());
        MMKV_ASSERT(0);
        clearMemoryCache();
    }

    m_fd = open(m_name.c_str(), O_RDWR | O_CREAT | O_CLOEXEC, S_IRWXU);
    if (m_fd < 0) {
        MMKVError("fail to open:%s, %s", m_name.c_str(), strerror(errno));
    } else {
        FileLock fileLock(m_fd);
        InterProcessLock lock(&fileLock, ExclusiveLockType);
        SCOPED_LOCK(&lock);

        mmkv::getFileSize(m_fd, m_size);
        // round up to (n * pagesize)
        if (m_size < DEFAULT_MMAP_SIZE || (m_size % DEFAULT_MMAP_SIZE != 0)) {
            size_t roundSize = ((m_size / DEFAULT_MMAP_SIZE) + 1) * DEFAULT_MMAP_SIZE;
            truncate(roundSize);
        } else {
            auto ret = mmap();
            if (!ret) {
                doCleanMemoryCache(true);
            }
        }
#    ifdef MMKV_IOS
        tryResetFileProtection(m_name);
#    endif
    }
}

```

### 缓存文件处理

```c++
bool MemoryFile::truncate(size_t size) {
    if (m_fd < 0) {
        return false;
    }
    if (size == m_size) {
        return true;
    }
#    ifdef MMKV_ANDROID
    if (m_fileType == MMFILE_TYPE_ASHMEM) {
        if (size > m_size) {
            MMKVError("ashmem %s reach size limit:%zu, consider configure with larger size", m_name.c_str(), m_size);
        } else {
            MMKVInfo("no way to trim ashmem %s from %zu to smaller size %zu", m_name.c_str(), m_size, size);
        }
        return false;
    }
#    endif // MMKV_ANDROID

    auto oldSize = m_size;
    m_size = size;
    // round up to (n * pagesize)
    if (m_size < DEFAULT_MMAP_SIZE || (m_size % DEFAULT_MMAP_SIZE != 0)) {
        m_size = ((m_size / DEFAULT_MMAP_SIZE) + 1) * DEFAULT_MMAP_SIZE;
    }

    if (::ftruncate(m_fd, static_cast<off_t>(m_size)) != 0) {
        MMKVError("fail to truncate [%s] to size %zu, %s", m_name.c_str(), m_size, strerror(errno));
        m_size = oldSize;
        return false;
    }
    if (m_size > oldSize) {
        if (!zeroFillFile(m_fd, oldSize, m_size - oldSize)) {
            MMKVError("fail to zeroFile [%s] to size %zu, %s", m_name.c_str(), m_size, strerror(errno));
            m_size = oldSize;
            return false;
        }
    }

    if (m_ptr) {
        if (munmap(m_ptr, oldSize) != 0) {
            MMKVError("fail to munmap [%s], %s", m_name.c_str(), strerror(errno));
        }
    }
    auto ret = mmap();
    if (!ret) {
        doCleanMemoryCache(true);
    }
    return ret;
}
```

### 内存映射处理

```C++
bool MemoryFile::mmap() {
    m_ptr = (char *) ::mmap(m_ptr, m_size, PROT_READ | PROT_WRITE, MAP_SHARED, m_fd, 0);
    if (m_ptr == MAP_FAILED) {
        MMKVError("fail to mmap [%s], %s", m_name.c_str(), strerror(errno));
        m_ptr = nullptr;
        return false;
    }

    return true;
}
```

### 内存缓存清理逻辑

```c++
void MemoryFile::doCleanMemoryCache(bool forceClean) {
#    ifdef MMKV_ANDROID
    if (m_fileType == MMFILE_TYPE_ASHMEM && !forceClean) {
        return;
    }
#    endif
    if (m_ptr && m_ptr != MAP_FAILED) {
        if (munmap(m_ptr, m_size) != 0) {
            MMKVError("fail to munmap [%s], %s", m_name.c_str(), strerror(errno));
        }
    }
    m_ptr = nullptr;

    if (m_fd >= 0) {
        if (::close(m_fd) != 0) {
            MMKVError("fail to close [%s], %s", m_name.c_str(), strerror(errno));
        }
    }
    m_fd = -1;
    m_size = 0;
}
```

### 同步内存缓存到文件

```c++
bool MemoryFile::msync(SyncFlag syncFlag) {
    if (m_ptr) {
        auto ret = ::msync(m_ptr, m_size, syncFlag ? MMKV_SYNC : MMKV_ASYNC);
        if (ret == 0) {
            return true;
        }
        MMKVError("fail to msync [%s], %s", m_name.c_str(), strerror(errno));
    }
    return false;
}
```



## C++编程小技巧

- C++11 使用 using 定义别名（替代typedef）
- typedef 用来定义block
- 使用std::unordered_map来操作数据

## 内核接口

###关于mmap

[认真分析mmap](https://www.cnblogs.com/huxiao-tee/p/4660352.htmll)

###关于ftruncate

- 定义函数

   int ftruncate(int fd,off_t length);

- 函数说明
  ftruncate()会将参数fd指定的文件大小改为参数length指定的大小。
  参数fd为已打开的文件描述词，而且必须是以写入模式打开的文件。
  如果原来的文件大小比参数length大，则超过的部分会被删去。

- 返回值
  执行成功则返回0，失败返回-1，错误原因存于errno。
- 错误代码
  EBADF 参数fd文件描述词为无效的或该文件已关闭。
  EINVAL 参数fd 为一socket 并非文件，或是该文件并非以写入模式打开。

###关于msync

进程在映射空间的对共享内容的改变并不直接写回到磁盘文件中，往往在调用munmap()后才执行该操作。
可以通过调用msync()函数来实现磁盘文件内容与共享内存区中的内容一致,即同步操作.

- 函数原型
  int msync ( void * addr, size_t len, int flags)
- 参数说明
  addr：文件映射到进程空间的地址；
  len：映射空间的大小；
  flags：刷新的参数设置，可以取值MS_ASYNC/ MS_SYNC/ MS_INVALIDATE
  其中：
  取值为MS_ASYNC（异步）时，调用会立即返回，不等到更新的完成；
  取值为MS_SYNC（同步）时，调用会等到更新完成之后返回；
  取MS_INVALIDATE（通知使用该共享区域的进程，数据已经改变）时，在共享内容更改之后，使得文件的其他映射失效，从而使得共享该文件的其他进程去重新获取最新值；
- 返回值
  成功则返回0；失败则返回-1；
- 可能的错误
  EBUSY/ EINVAL/ ENOMEM

###关于munmap

- 定义函数

   int munmap(void *start,size_t length);

- 函数说明

   munmap()用来取消参数start所指的映射内存起始地址，参数length则是欲取消的内存大小。当进程结束或利用exec相关函数来执行其他程序时，映射内存会自动解除，但关闭对应的文件描述符时不会解除映射。

- 返回值 

  解除映射成功则返回0，否则返回－1，

- 错误原因存于errno中错误代码EINVAL

