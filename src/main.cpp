#include <chrono>
#include <iostream>
#include <thread>
#include <vector>

#include "proc_stat.hpp"

int main(int argc, char *argv[]) {
  std::filesystem::path dir_path = "tmp";
  int interval_ms = 100;

  for (int i = 1; i < argc; ++i) {
    std::string k = argv[i];
    if (k == "-d") {
      std::string v = argv[i + 1];
      dir_path = v;
    }

    if (k == "-i") {
      std::string v = argv[i + 1];
      interval_ms = std::stoi(v);
    }
  }

  std::string command;
  std::vector<std::unique_ptr<Measurer<std::string>>> measurers;
  measurers.emplace_back(std::make_unique<ProcStat>(dir_path, (uint)interval_ms));

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
