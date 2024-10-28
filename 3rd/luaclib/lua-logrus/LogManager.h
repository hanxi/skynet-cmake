#pragma once

#include "LogConfig.h"
#include "LogImpl.h"
#include "LogDriverImpl.h"

#include <string_view>
#include <memory>
#include <mutex>
#include <unordered_map>

namespace logrus {

constexpr bool kIsDefaultLogger = true;

/**
 *
 */
class LogManager {
public:
    /**
     * Use in case you need to modify any configuration before initialization
     * @return The configuration instance
     */
    static LogConfig& getConfig();

    /**
     *
     * @param loggerName
     */
    static void init(std::string_view loggerName, bool isDefault = !kIsDefaultLogger);

    /**
     *
     * @return
     */
    static impl::LogImpl& getLogger(const std::string& loggerName = "");

protected:
    LogManager() = default;
    ~LogManager();
    static void createLogger(const std::string& loggerName, bool isDefault = false);
    static void createDrivers();

    inline static LogManager* inst_ = nullptr;
    inline static LogConfig config_{};
    inline static std::once_flag once_;
    inline static std::unordered_map<std::string, std::shared_ptr<impl::LogImpl>> loggers_;
    inline static std::vector<impl::LogDriverImpl> drivers_;
    inline static std::string defaultLoggerName_{};
};

} // namespace logrus
