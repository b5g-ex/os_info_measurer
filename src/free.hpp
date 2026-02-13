#include "measurer.hpp"

#include <algorithm>
#include <array>
#include <cctype>
#include <cstdio>
#include <fstream>
#include <sstream>
#include <stdexcept>

class Free : public Measurer<std::string> {
public:
  Free(std::filesystem::path data_directory_path, std::string file_name_prefix,
       uint32_t interval_ms)
      : Measurer(data_directory_path, file_name_prefix, interval_ms) {}

  ~Free() = default;

  void measure() override {
    auto line = get_memory_line();
    line = convert_memory_line(line);
    Measurer::measurements.emplace_back(line);
  }

  void dump_to_csv() override {
    auto csv_file_path = Measurer::csv_file_path("free.csv");
    std::ofstream csv_file_stream(csv_file_path.string());

    // header
    csv_file_stream << "time[ms]" << ","
                    << "total[KiB],used[KiB],free[KiB],shared[KiB],buff/cache[KiB],available[KiB]"
                    << "," << "\n";

    // body
    for (const auto &m : Measurer::measurements) {
      const auto m_time =
          std::chrono::duration_cast<std::chrono::milliseconds>(m.time().time_since_epoch())
              .count();
      csv_file_stream << std::to_string(m_time) << "," << m.data() << "\n";
    }

    csv_file_stream.flush();
    Measurer::measurements.clear();
  }

private:
  std::string get_memory_line() {
    std::stringstream result(exec("free"));

    std::string line;
    // Skip first line (header)
    // "              total        used        free      shared  buff/cache   available"
    std::getline(result, line);

    // Get memory line:
    // "Mem:       32789156     3483060    24676784       38796     4629312    28879052"
    std::getline(result, line);

    return line;
  }

  std::string convert_memory_line(std::string line) {
    // "Mem:       32789156     3483060    24676784       38796     4629312    28879052"
    line = remove_multiple_spaces(line);
    // "Mem: 32789156 3483060 24676784 38796 4629312 28879052"

    // Remove "Mem: " prefix
    constexpr std::string_view prefix = "Mem: ";
    if (line.starts_with(prefix)) {
      line = line.substr(prefix.length());
    }
    // "32789156 3483060 24676784 38796 4629312 28879052"

    // Replace spaces with commas
    std::replace(line.begin(), line.end(), ' ', ',');
    // "32789156,3483060,24676784,38796,4629312,28879052"

    return line;
  }

  std::string exec(const std::string &command) {
    std::array<char, 256> buffer;
    std::string result;

    // Note: popen() is only safe here because we pass a fixed command
    // "free". Never pass user-controlled input to popen()!
    auto pipe = std::unique_ptr<FILE, int (*)(FILE *)>(popen(command.c_str(), "r"), pclose);
    if (!pipe) {
      throw std::runtime_error("popen() failed!");
    }

    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr) {
      result += buffer.data();
    }

    return result;
  }

  std::string remove_multiple_spaces(std::string line) {
    auto is_multiple_space = [](char lhs, char rhs) {
      return lhs == rhs && std::isspace(static_cast<unsigned char>(lhs));
    };

    auto iterator = std::unique(line.begin(), line.end(), is_multiple_space);
    line.erase(iterator, line.end());

    return line;
  }
};
