#pragma once

#include <chrono>
#include <filesystem>
#include <thread>
#include <vector>

template <typename T> class Measurer {
  class measurement {
  public:
    measurement(T data) : time_(std::chrono::system_clock::now()), data_(data) {}

    std::chrono::system_clock::time_point time() const { return time_; }
    T data() const { return data_; }

  private:
    std::chrono::system_clock::time_point time_;
    T data_;
  };

public:
  Measurer(std::filesystem::path data_directory_path, uint interval_ms)
      : data_directory_path_(data_directory_path), interval_ms_(interval_ms) {
    if (!std::filesystem::exists(data_directory_path_)) {
      std::cerr << data_directory_path_ << " does not exists." << std::endl;
      exit(1);
    }
    if (!std::filesystem::is_directory(data_directory_path_)) {
      std::cout << data_directory_path_ << " is not directory." << std::endl;
      exit(1);
    }
  }
  virtual ~Measurer() {}

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
      thread_.join();
      dump_to_csv();
    }
  }

  std::filesystem::path csv_file_path(std::string csv_file_name) {
    return data_directory_path_ / csv_file_name;
  }

  virtual void measure() = 0;
  virtual void dump_to_csv() = 0;

  std::vector<measurement> measurements;

private:
  std::filesystem::path data_directory_path_;
  bool done_ = false;
  std::thread thread_;
  uint interval_ms_;
};
