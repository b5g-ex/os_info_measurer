#pragma once

#include <atomic>
#include <chrono>
#include <cstdint>
#include <filesystem>
#include <thread>
#include <vector>

template <typename T> class Measurer {
  class Measurement {
  public:
    Measurement(T data) : time_(std::chrono::system_clock::now()), data_(data) {}

    std::chrono::system_clock::time_point time() const { return time_; }
    T data() const { return data_; }

  private:
    std::chrono::system_clock::time_point time_;
    T data_;
  };

public:
  Measurer(std::filesystem::path data_directory_path, std::string file_name_prefix,
           uint32_t interval_ms)
      : data_directory_path_(data_directory_path), file_name_prefix_(file_name_prefix),
        interval_ms_(interval_ms) {
    if (!std::filesystem::exists(data_directory_path_)) {
      std::filesystem::create_directories(data_directory_path_);
    }
  }

  virtual ~Measurer() { stop(); }

  void start() {
    done_ = false;
    thread_ = std::thread([this]() {
      while (!done_) {
        measure();
        std::this_thread::sleep_for(std::chrono::milliseconds(interval_ms_));
      }
    });
  }

  void stop() {
    if (!done_) {
      done_ = true;
      if (thread_.joinable()) {
        thread_.join();
      }
      dump_to_csv();
    }
  }

  std::filesystem::path csv_file_path(std::string csv_file_name) {
    if (file_name_prefix_.empty()) {
      return data_directory_path_ / csv_file_name;
    }
    return data_directory_path_ / (file_name_prefix_ + "_" + csv_file_name);
  }

  virtual void measure() = 0;
  virtual void dump_to_csv() = 0;

  std::vector<Measurement> measurements;

private:
  std::filesystem::path data_directory_path_;
  std::atomic<bool> done_ = true;
  std::thread thread_;
  std::string file_name_prefix_;
  uint32_t interval_ms_;
};
