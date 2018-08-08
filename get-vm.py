#!/usr/bin/env python

from __future__ import print_function
import atexit
from time import clock

from pyVim import connect
from pyVmomi import vim
import cli
import pchelper

START = clock()
vm_details = []


def endit():
    """
    times how long it took for this script to run.
    :return:
    """
    end = clock()
    total = end - START
    print("Completion time: {0} seconds.".format(total))


# List of properties.
# See: http://goo.gl/fjTEpW
# for all properties.
vm_properties = ["name", "config.uuid", "config.hardware.numCPU",
                 "config.hardware.memoryMB", "guest.guestState",
                 "config.guestFullName", "config.guestId",
                 "config.version", "config.firmware", "config.hardware.numCoresPerSocket", "summary.guest.ipAddress"]

args = cli.get_args()
service_instance = None
try:
    service_instance = connect.SmartConnectNoSSL(host=args.host,
                                                 user=args.user,
                                                 pwd=args.password,
                                                 port=int(args.port))
    atexit.register(connect.Disconnect, service_instance)
    atexit.register(endit)
except IOError as e:
    pass

if not service_instance:
    raise SystemExit("Unable to connect to host with supplied info.")

root_folder = service_instance.content.rootFolder
view = pchelper.get_container_view(service_instance,
                                   obj_type=[vim.VirtualMachine])
vm_data = pchelper.collect_properties(service_instance, view_ref=view,
                                      obj_type=vim.VirtualMachine,
                                      path_set=vm_properties,
                                      include_mors=True)

for vm in vm_data:
    try:
        vm_details.append(format(vm["name"]).lower() + "," + format(vm["config.uuid"]) + "," + format(vm["config.hardware.numCPU"])
                          + "," + format(vm["config.hardware.memoryMB"]) + "," + format(vm["guest.guestState"]) + "," +
                          format(vm["config.guestFullName"]) + "," + format(vm["config.guestId"]) + ","
                          + format(vm["config.version"]) + "," + format(vm["config.firmware"]) + "," +
                          format(vm["config.hardware.numCoresPerSocket"]) + "," + format(vm["summary.guest.ipAddress"]))
    except:
        pass

with open('/tmp/vm_details.csv', 'a') as f:
    for i in vm_details:
        if i:
            f.write('DEFAULT,' + i + "\n")
