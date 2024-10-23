#include "LogDriverImpl.h"

#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <spdlog/sinks/rotating_file_sink.h>

#include <cassert>

namespace logrus::impl {

LogDriverImpl::LogDriverImpl(LogConfig::DriverInfo::Type type
                            , const std::string& pattern
                            , const LogConfig& config
                            , const std::string& logFilePath) : type_{type} {
    switch (type_) {
    case LogConfig::DriverInfo::Type::kConsole:
        sink_ = std::make_shared<spdlog::sinks::stdout_color_sink_mt>();
        break;
    case LogConfig::DriverInfo::Type::kFile:
        createFile(logFilePath, config);
        break;
    case LogConfig::DriverInfo::Type::kPubSub:
        break;
    }
    assert(sink_ != nullptr);
    sink_->set_pattern(pattern);
}

void LogDriverImpl::createFile(const std::string& logFilePath, const LogConfig& config) {
    assert(logFilePath.empty() == false);

    if (config.file.isRotating) {
        sink_ = std::make_shared<spdlog::sinks::rotating_file_sink_mt>(
            logFilePath, config.file.maxFileSize, config.file.maxNumFiles);
    } else {
        sink_ = std::make_shared<spdlog::sinks::basic_file_sink_mt>(logFilePath);
    }
}

spdlog::sink_ptr LogDriverImpl::sink() {
    return sink_;
}

} // namespace logrus::impl
