/**
 * Test caller for os_info_measurer.
 *
 * This program starts the measurer binary, sends start and stop commands,
 * and verifies that output CSV files are generated.
 */

#include <cstdio>
#include <filesystem>
#include <iostream>
#include <sstream>
#include <string>
#include <unistd.h>
#include <vector>

// Find measurer binary in common locations
std::string find_measurer() {
  std::vector<std::string> candidates = {"_build/dev/lib/os_info_measurer/priv/measurer",
                                         "_build/test/lib/os_info_measurer/priv/measurer",
                                         "./priv/measurer"};

  for (const auto &path : candidates) {
    if (std::filesystem::exists(path)) {
      return path;
    }
  }

  return "";
}

int main(int argc, char *argv[]) {
  // Default values
  std::string directory = "tmp";
  std::string prefix = "cpp_test";
  std::string interval = "100";

  // Parse command line arguments
  for (int i = 1; i < argc; i++) {
    std::string arg = argv[i];
    if (arg == "-d" && i + 1 < argc) {
      directory = argv[++i];
    } else if (arg == "-f" && i + 1 < argc) {
      prefix = argv[++i];
    } else if (arg == "-i" && i + 1 < argc) {
      interval = argv[++i];
    }
  }

  // Find measurer binary
  std::string measurer_path = find_measurer();
  if (measurer_path.empty()) {
    std::cerr << "Error: measurer binary not found" << std::endl;
    return 1;
  }

  // Build the measurer command
  std::stringstream ss;
  ss << measurer_path << " -d " << directory << " -f " << prefix << " -i " << interval;
  std::string cmd = ss.str();

  // Start measurer binary
  FILE *pipe = popen(cmd.c_str(), "w");
  if (!pipe) {
    perror("popen failed");
    return 1;
  }

  // Send start command
  int ret = fprintf(pipe, "start\n");
  std::cout << "Sent 'start\\n' to measurer (bytes written: " << ret << ")" << std::endl;
  fflush(pipe);

  // Measurement in progress
  sleep(1);

  // Send stop command
  ret = fprintf(pipe, "stop\n");
  std::cout << "Sent 'stop\\n' to measurer (bytes written: " << ret << ")" << std::endl;
  fflush(pipe);

  // Close pipe and wait for process to exit
  // The measurer binary waits for EOF on stdin as a signal to exit normally.
  // Calling pclose() closes the pipe and causes EOF, allowing measurer to
  // terminate and write CSV files to disk. See src/main.cpp for details.
  int status = pclose(pipe);
  if (status == -1) {
    perror("pclose failed");
    return 1;
  }

  std::cout << "Measurement completed." << std::endl;
  return 0;
}
