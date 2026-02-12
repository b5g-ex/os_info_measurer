#include "measurer.hpp"

#include <algorithm>
#include <array>
#include <fstream>

using namespace std::literals;

class Free : public Measurer<std::string> {
public:
  Free(std::filesystem::path data_directory_path, std::string file_name_prefix, uint interval_ms)
      : Measurer(data_directory_path, file_name_prefix, interval_ms) {}
  ~Free() { Measurer::stop(); }
  void measure() override {
    auto line = get_memory_line();
    line = convert_memory_line(line);
    Measurer::measurements.emplace_back(line);
  }

  void dump_to_csv() override {
    auto csv_file_path = Measurer::csv_file_path("free.csv");
    std::ofstream csv_file_stream(csv_file_path.string());

    // header
    csv_file_stream << "time[ms]"s
                    << ","s
                    << "total[KiB],used[KiB],free[KiB],shared[KiB],buff/cache[KiB],available[KiB]"s
                    << ","s
                    << "\n"s;
    // body
    for (auto m : Measurer::measurements) {
      const auto m_time =
          std::chrono::duration_cast<std::chrono::milliseconds>(m.time().time_since_epoch())
              .count();
      csv_file_stream << std::to_string(m_time) << ","s << m.data() << "\n"s;
    }

    csv_file_stream.flush();
    Measurer::measurements.clear();
  }

private:
  std::string get_memory_line() {
    std::stringstream result(exec("free"s));
    std::string line;
    // "              total        used        free      shared  buff/cache   available"
    std::getline(result, line); // abandon header
    // "Mem:       32789156     3483060    24676784       38796     4629312    28879052"
    std::getline(result, line);

    return line;
  }

  std::string convert_memory_line(std::string line) {
    // "Mem: 32789156 3483060 24676784 38796 4629312 28879052"
    line = remove_multiple_space(line);
    // "32789156 3483060 24676784 38796 4629312 28879052"
    line = line.substr("Mem: "s.length(), line.length());
    // "32789156,3483060,24676784,38796,4629312,28879052"
    std::replace(line.begin(), line.end(), ' ', ',');

    return line;
  }

  std::string exec(const std::string command) {
    std::array<char, 256> buffer;
    std::string result;
    // custom deleter
    auto pipe = std::unique_ptr<FILE, int (*)(FILE *)>(popen(command.c_str(), "r"), pclose);
    if (!pipe) {
      throw std::runtime_error("popen() failed!");
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
      result += buffer.data();
    }

    return result;
  }

  std::string remove_multiple_space(std::string line) {
    auto is_multiple_space = [](char const &lhs, char const &rhs) -> bool {
      return lhs == rhs && iswspace(lhs);
    };
    auto iterator = std::unique(line.begin(), line.end(), is_multiple_space);
    line.erase(iterator, line.end());

    return line;
  }
};
