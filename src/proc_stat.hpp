#include "measurer.hpp"

#include <algorithm>
#include <fstream>
#include <string_view>

class ProcStat : public Measurer<std::string> {
public:
  ProcStat(std::filesystem::path data_directory_path, std::string file_name_prefix,
           uint32_t interval_ms)
      : Measurer(data_directory_path, file_name_prefix, interval_ms) {}

  ~ProcStat() = default;

  void measure() override {
    auto line = get_cpu_line();
    line = convert_cpu_line(line);
    Measurer::measurements.emplace_back(line);
  }

  void dump_to_csv() override {
    auto csv_file_path = Measurer::csv_file_path("proc_stat.csv");
    std::ofstream csv_file_stream(csv_file_path.string());

    // header, see man 5 proc, /proc/stat
    csv_file_stream << "time[ms]" << ","
                    << "user,nice,system,idle,iowait,irq,softirq,steal,guest,guest_nice" << ","
                    << "\n";
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
  std::string get_cpu_line() {
    std::ifstream proc_stat("/proc/stat");
    std::string line;
    // "cpu  228602 66 124305 99146269 4121 0 1163 0 0 0";
    std::getline(proc_stat, line);

    return line;
  }

  std::string convert_cpu_line(std::string line) {
    // "cpu  228602 66 124305 99146269 4121 0 1163 0 0 0";
    constexpr std::string_view prefix = "cpu  ";
    if (line.starts_with(prefix)) {
      line = line.substr(prefix.length());
    }
    // "228602 66 124305 99146269 4121 0 1163 0 0 0";
    std::replace(line.begin(), line.end(), ' ', ',');
    // "228602,66,124305,99146269,4121,0,1163,0,0,0";

    return line;
  }
};
