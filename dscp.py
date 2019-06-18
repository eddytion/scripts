from paramiko import SSHClient
from scp import SCPClient
import multiprocessing
import sys
import paramiko

ssh = SSHClient()
ssh.load_system_host_keys()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())


def progress(filename, size, sent, peername):
    sys.stdout.write(
        "(%s:%s) %s\'s progress: %.2f%%   \r" % (peername[0], peername[1], filename, float(sent) / float(size) * 100))


def dscp(host, file):
    try:
        ssh.connect(hostname=host, username='padmin', port=22, timeout=60)
        scp = SCPClient(ssh.get_transport(), progress=progress)
        print("Getting file " + file + " from host: " + host)
        scp.get(file, '/home/eduard/PMR/' + str(host) + "." + (str(file).split('/')[-1]))
        scp.close()
    except Exception as e:
        print("Some error occurred" + str(e))
        pass


pool = multiprocessing.Pool(processes=multiprocessing.cpu_count() - 1)
for i in sys.argv[1:]:
    pool.apply_async(dscp, args=(i, '/tmp/ibmsupt/snap.pax.Z'))
pool.close()
pool.join()
