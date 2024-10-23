#pragma once

#include "LogConfig.h"

#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/sinks/rotating_file_sink.h>

#include <string>

namespace logrus::impl {

class LogDriverImpl {
public:
    explicit LogDriverImpl(LogConfig::DriverInfo::Type type
                          , const std::string& pattern
                          , const LogConfig& config
                          , const std::string& logFilePath = "");

    spdlog::sink_ptr sink();

private:
    void createFile(const std::string& logFilePath, const LogConfig& config);

    LogConfig::DriverInfo::Type type_;
    spdlog::sink_ptr sink_;
};

} // namespace logrus::impl

