#include <chrono>
#include <iostream>
#include <thread>
#include <vector>

#include "proc_stat.hpp"

int main(int argc, char *argv[]) {
  std::string command;
  std::vector<std::unique_ptr<Measurer<std::string>>> measurers;
  measurers.emplace_back(std::make_unique<ProcStat>("tmp"));

  while (true) {
    std::cin >> command;

    if (std::cin.eof()) {
      // NOTE: Erlang VM のシャットダウンで標準入力が閉じられると EOF となる
      //       それをトリガーに終了させる
      std::cerr << "eof" << std::endl;
      break;
    }

    if (std::cin.fail()) {
      std::cerr << "fail" << std::endl;
      break;
    }

    if (command == std::string("start")) {
      std::cerr << "start" << std::endl;
      for (const auto &measurer : measurers) {
        measurer->start();
      }
    }

    if (command == std::string("stop")) {
      std::cerr << "stop" << std::endl;
      for (const auto &measurer : measurers) {
        measurer->stop();
      }
    }
  }

  return 0;
}
