#include <iostream>

int main(int argc, char *argv[]) {
  FILE *pipe = popen("./a.out", "w");

  std::string start_measure = "start\n";
  fwrite(start_measure.c_str(), sizeof(char), start_measure.size(), pipe);
  fflush(pipe);

  pclose(pipe);
  return 0;
}
