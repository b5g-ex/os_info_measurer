#pragma once

#include <atomic>
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
  virtual ~Measurer() {}

  void start() {
    thread_ = std::thread([this]() {
      while (!done) {
        measure();
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
      }
    });
  }
  void stop(std::filesystem::path data_directory_path) {
    done = true;
    thread_.join();
    dump_to_csv(data_directory_path);
  }
  virtual void measure() = 0;
  virtual void dump_to_csv(std::filesystem::path data_directory_path) = 0;

  std::atomic<bool> done = false;
  std::vector<measurement> measurements;

private:
  std::thread thread_;
};
