#include <iostream>
#include <thread>
#include <chrono>

int main(int argc, char *argv[])
{
    std::string command;

    while (true)
    {
        std::cin >> command;

        if (std::cin.eof())
        {
            // NOTE: Erlang VM のシャットダウンで標準入力が閉じられると EOF となる
            //       それをトリガーに終了させる
            std::cerr << "eof" << std::endl;
            break;
        }

        if (std::cin.fail())
        {
            std::cerr << "fail" << std::endl;
            break;
        }

        std::cout << command << std::endl;
    }
    return 0;
}
