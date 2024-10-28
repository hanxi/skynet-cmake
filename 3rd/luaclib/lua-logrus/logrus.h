#pragma once

#include "LogConfig.h"
#include "LogManager.h"

using namespace logrus;

class Logrus {
public:
    explicit Logrus(const std::string& loggerName = "", bool isDefault = !kIsDefaultLogger)
        : logname_{loggerName}
        , is_default_{isDefault} {
    }
    
    ~Logrus() {
        warn("~Logrus:" + logname_);
        LogManager::getLogger(logname_).drop();
    }

    LogConfig& getConfig() {
        return LogManager::getConfig();
    }
    /**
     * Changes the output file name. This function must be called before
     * @param filename
     */
    Logrus& configFilename(const std::string& filename) {
        auto& config = LogManager::getConfig();
        config.file.filename = filename;
        return *this;
    }

    Logrus& configBacktrace(size_t max = 0U) {
        auto& config = LogManager::getConfig();
        config.backtrace.isEnabled = true;
        if (max > 0) {
            config.backtrace.max = max;
        }
        return *this;
    }

    Logrus& configThreadPool(size_t maxQueue = 0U, size_t maxThreads = 0U) {
        auto& config = LogManager::getConfig();
        config.thread.maxItemsInQueue = maxQueue > 0U ? maxQueue :  config.thread.maxItemsInQueue;
        config.thread.maxNumThreads = maxThreads > 0U ? maxThreads : config.thread.maxNumThreads;
        return *this;
    }

    void init() { LogManager::init(logname_, is_default_); }

    template <typename... Args>
    void trace(Args... args) { LogManager::getLogger(logname_).trace(std::forward<Args>(args)...); }

    template <typename... Args>
    void info(Args... args) { LogManager::getLogger(logname_).info(std::forward<Args>(args)...); }

    template <typename... Args>
    void debug(Args... args) { LogManager::getLogger(logname_).debug(std::forward<Args>(args)...); }

    template <typename... Args>
    void warn(Args... args) { LogManager::getLogger(logname_).warn(std::forward<Args>(args)...); }

    template <typename... Args>
    void error(Args... args) { LogManager::getLogger(logname_).error(std::forward<Args>(args)...); }

    template <typename... Args>
    void fatal(Args... args) { LogManager::getLogger(logname_).fatal(std::forward<Args>(args)...); }

    template <typename T>
    auto hex(const T& buf) {
        return LogManager::getLogger(logname_).hex(buf);
    }

private:
    const std::string logname_;
    const bool is_default_;
};
