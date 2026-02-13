#include <chrono>
#include <iostream>
#include <thread>
#include <vector>

#include "free.hpp"
#include "proc_stat.hpp"

int main(int argc, char *argv[]) {
  std::filesystem::path dir_path = "tmp";
  std::string file_name_prefix = "";
  int interval_ms = 100;
  bool debug = false;

  for (int i = 1; i < argc; ++i) {
    std::string k = argv[i];
    if (k == "-d" && i + 1 < argc) {
      dir_path = argv[++i];
    } else if (k == "-f" && i + 1 < argc) {
      file_name_prefix = argv[++i];
    } else if (k == "-i" && i + 1 < argc) {
      try {
        interval_ms = std::stoi(argv[++i]);
      } catch (const std::invalid_argument &e) {
        std::cerr << "Error: invalid interval value" << std::endl;
        return -1;
      }
    } else if (k == "-v") {
      debug = true;
    }
  }

  std::string command;
  std::vector<std::unique_ptr<Measurer<std::string>>> measurers;
  measurers.emplace_back(std::make_unique<ProcStat>(dir_path, file_name_prefix, (uint)interval_ms));
  measurers.emplace_back(std::make_unique<Free>(dir_path, file_name_prefix, (uint)interval_ms));

  while (true) {
    std::cin >> command;

    if (std::cin.eof()) {
      // NOTE: Erlang VM のシャットダウンで標準入力が閉じられると EOF となる
      //       それをトリガーに終了させる
      if (debug) {
        std::cerr << "eof" << std::endl;
      }
      break;
    }

    if (std::cin.fail()) {
      if (debug) {
        std::cerr << "fail" << std::endl;
      }
      break;
    }

    if (command == "start") {
      if (debug) {
        std::cerr << "start" << std::endl;
      }
      for (const auto &measurer : measurers) {
        measurer->start();
      }
    } else if (command == "stop") {
      if (debug) {
        std::cerr << "stop" << std::endl;
      }
      for (const auto &measurer : measurers) {
        measurer->stop();
      }
    }
  }

  return 0;
}
