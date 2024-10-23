#pragma once

#include "LogConfig.h"
#include "LogDriverImpl.h"

#include <spdlog/async_logger.h>
#include <spdlog/fmt/ostr.h>
#include <spdlog/spdlog.h>
#include <spdlog/fmt/bin_to_hex.h>

#include <memory>
#include <vector>

namespace logrus::impl {

/**
 * Implements the log to use the spdlog library
 */
class LogImpl {
public:
    explicit LogImpl(const std::string& name
                    , const LogConfig& config
                    , const std::vector<LogDriverImpl>& drivers
                    , bool isDefault);

    template <typename... Args>
    inline void trace(Args&&...args) { logger_->trace(std::forward<Args>(args)...); }

    template <typename... Args>
    inline void info(Args&&...args) { logger_->info(std::forward<Args>(args)...); }

    template <typename... Args>
    inline void debug(Args&&...args) { logger_->debug(std::forward<Args>(args)...); }

    template <typename... Args>
    inline void warn(Args&&...args) { logger_->warn(std::forward<Args>(args)...); }

    template <typename... Args>
    inline void error(Args&&...args) { logger_->error(std::forward<Args>(args)...); }

    template <typename... Args>
    inline void fatal(Args&&...args) { logger_->critical(std::forward<Args>(args)...); }

    template <typename T>
    auto hex(const T& buf) { return spdlog::to_hex(buf); }

    inline void drop() { spdlog::drop(logger_->name()); }

private:
    std::shared_ptr<spdlog::async_logger> logger_;
};

} // namespace logrus::impl

