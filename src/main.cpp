#include <iostream>
#include <atomic>
#include <thread>
#include <chrono>

std::atomic<bool> done(false);

void worker()
{
    while (!done)
    {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
        std::cout << "working" << std::endl;
    }
}

int main(int argc, char *argv[])
{
    std::string command;
    std::thread t;

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

        if (command == std::string("start"))
        {
            std::cerr << "start" << std::endl;
            done = false;
            t = std::thread(worker);
        }

        if (command == std::string("stop"))
        {
            std::cerr << "stop" << std::endl;
            done = true;
            t.join();
        }
    }
    return 0;
}
