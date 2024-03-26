from subprocess import Popen, PIPE

process = Popen(["./a.out"], stdin=PIPE, stdout=PIPE, text=True)

process.stdin.write("start\n")
process.stdin.flush()

output = process.stdout.readline()

print(output)

process.stdin.close()
