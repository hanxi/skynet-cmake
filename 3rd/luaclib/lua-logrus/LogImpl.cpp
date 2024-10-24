#include "LogImpl.h"

#include <spdlog/async.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/sinks/basic_file_sink.h>

namespace {

using namespace logrus::def;

constexpr spdlog::level::level_enum get_spdlog_level(LogLevel level) {
    switch (level) {
        case LogLevel::kTrace: return spdlog::level::trace;
        case LogLevel::kDebug: return spdlog::level::debug;
        case LogLevel::kInfo: return spdlog::level::info;
        case LogLevel::kWarn: return spdlog::level::warn;
        case LogLevel::kError: return spdlog::level::err;
        case LogLevel::kCritical: return spdlog::level::critical;
        case LogLevel::kTurnedOff: return spdlog::level::off;
    }
}

} // anonymous namespace

namespace logrus::impl {

LogImpl::LogImpl(const std::string& name
                , const LogConfig& config
                , const std::vector<LogDriverImpl>& drivers
                , bool isDefault) {
    std::vector<spdlog::sink_ptr> sinks;

    for (auto driver : drivers) {
        sinks.push_back(driver.sink());
    }
    if (config.backtrace.isEnabled) {
        spdlog::enable_backtrace(config.backtrace.max);
    }
    if (isDefault) {
        spdlog::init_thread_pool(config.thread.maxItemsInQueue, config.thread.maxNumThreads);
    }
    logger_ = std::make_shared<spdlog::async_logger>(name
                                                    , sinks.begin()
                                                    , sinks.end()
                                                    , spdlog::thread_pool()
                                                    , spdlog::async_overflow_policy::block);
    spdlog::register_logger(logger_);

    if (isDefault) {
        spdlog::set_default_logger(logger_);
    }
    const auto level = get_spdlog_level(config.logger.level);
    logger_->set_level(level);
    logger_->flush_on(level);
}

} // namespace logrus::impl
