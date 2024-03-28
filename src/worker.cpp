#include <atomic>
#include <iostream>
#include <thread>

std::atomic<bool> done(false);

void worker() {
  while (!done) {
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
    std::cout << "working" << std::endl;
  }
}
