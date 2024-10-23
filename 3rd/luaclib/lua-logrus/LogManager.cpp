#include "LogManager.h"
#include "LogImpl.h"

#include <cassert>
#include <vector>

namespace logrus {

LogConfig& LogManager::getConfig() {
    return config_;
}

void LogManager::init(std::string_view loggerName, bool isDefault) {
    const std::string name{loggerName.begin(), loggerName.end()};

    if (isDefault && defaultLoggerName_.empty()) {
        config_.logger.name   = name;
        config_.file.filename = config_.file.filename.empty()
                              ? name + ".log"
                              : config_.file.filename + ".log";
        defaultLoggerName_    = name;
    }
    if (!inst_) {
        std::call_once(once_, [&] () {
            inst_ = new LogManager;
            createDrivers();
        });
    }
    createLogger(name, isDefault);
}

void LogManager::createLogger(const std::string& loggerName, bool isDefault) {
    loggers_.insert(std::make_pair(loggerName, std::make_shared<impl::LogImpl>(loggerName
                                                                              , config_
                                                                              , drivers_
                                                                              , isDefault)));
}

LogManager::~LogManager() {
    delete inst_;
}

impl::LogImpl& LogManager::getLogger(const std::string& loggerName) {
    const auto lookupName = loggerName.empty() ? defaultLoggerName_ : loggerName;

    if (loggers_.count(lookupName) == 0) {
        createLogger(lookupName);
    }
    assert(loggers_.count(lookupName) > 0);
    return *loggers_[lookupName];
}

void LogManager::createDrivers() {
    const std::filesystem::path p = config_.file.filePath / config_.file.filename;
    const auto filePath = p.string();

    for (const auto& driverConfig : config_.drivers) {
        drivers_.push_back(impl::LogDriverImpl{driverConfig.type
                                              , driverConfig.headerPattern
                                              , config_
                                              , filePath});
    }
}

// void LogManager::flushEvery() {
//     // Flush all *registered* loggers using a worker thread every 3 seconds.
//     spdlog::flush_every(std::chrono::seconds(3));
// }

// void LogManager::dropAll() {
//     for (auto& logger : loggers_) {
//         logger.second->drop();
//     }
//     loggers_.clear();
// }

} // namespace logrus
