#include <iostream>

int main(int argc, char *argv[]) {
  FILE *pipe = popen("./_build/dev/lib/os_info_measurer/priv/measurer -d data -f cpp_ -i 100", "w");

  std::string start_measure = "start\n";
  fwrite(start_measure.c_str(), sizeof(char), start_measure.size(), pipe);
  fflush(pipe);

  pclose(pipe);
  return 0;
}
