from subprocess import Popen, PIPE

line = "./_build/dev/lib/os_info_measurer/priv/measurer -d data -f python_ -i 100"

process = Popen(
    line.split(),
    stdin=PIPE,
    stdout=PIPE,
    text=True,
)

process.stdin.write("start\n")
process.stdin.flush()

process.stdin.close()
