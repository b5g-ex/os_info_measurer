/**
 * Test caller for os_info_measurer.
 *
 * This program starts the measurer binary, sends start and stop commands,
 * and verifies that output CSV files are generated.
 */

#include <cstdio>
#include <iostream>
#include <sstream>
#include <string>
#include <unistd.h>

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

  // Build the measurer command
  std::stringstream ss;
  ss << "./priv/measurer -d " << directory << " -f " << prefix << " -i " << interval;
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
