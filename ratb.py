#!/usr/bin/python3
import os, argparse, sys
from enum import Enum

TRAVEL_PRICE = 130  # 1.30 ron


class Banner(object):
    SHOW = """
 _______________________________________
|                                       |
|               RATB PWN                |
|---------------------------------------|
| xx..............    _  _____ _  __    |
| xx/\............   | |/ / __| |/ /    |
| xxx/\...........   | ' <| _|| ' <     |
| xxxxxxxxxxxxxxxx   |_|\_\___|_|\_\    |
|                                       |
|_______________________________________|

         RATB travel cards PWNage
"""


class ConsoleColors(object):
    OKBLUE = '\033[94m'
    OKGREEN = '\033[92m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'


class PrintType(Enum):
    Error = 1
    Ok = 2
    Info = 3


class CRC(object):
    def __init__(self, poly, preset=0x1D0F):
        self.poly = poly
        self.preset = preset

        self._tab = [self._initial(i) for i in range(256)]

    def _initial(self, c):
        crc = 0
        c = c << 8
        for j in range(8):
            if (crc ^ c) & 0x8000:
                crc = (crc << 1) ^ self.poly
            else:
                crc = crc << 1
            c = c << 1
        return crc

    def _update_crc(self, crc, c):
        cc = 0xff & c

        tmp = (crc >> 8) ^ cc
        crc = (crc << 8) ^ self._tab[tmp & 0xff]
        crc = crc & 0xffff
        # print (crc)

        return crc

    def crc(self, str):
        crc = self.preset
        for c in str:
            crc = self._update_crc(crc, ord(c))
        return crc

    def crcb(self, *i):
        crc = self.preset
        for c in i:
            crc = self._update_crc(crc, c)
        return crc


def printEx(message, type):
    print_type_str = ""
    if type == PrintType.Error:
        print_type_str = ConsoleColors.FAIL + "[!]" + ConsoleColors.ENDC
    elif type == PrintType.Ok:
        print_type_str = ConsoleColors.OKGREEN + "[*]" + ConsoleColors.ENDC
    elif type == PrintType.Info:
        print_type_str = ConsoleColors.OKBLUE + "[*]" + ConsoleColors.ENDC

    print(print_type_str + " " + message)


def hex_travels(travels):
    return '%04x' % (int(int(hex((TRAVEL_PRICE * travels) * 8), 16) + 0x8000))


def calc_crc(crc_string):
    return '%04x' % crc.crcb(*[int(crc_string[i:i + 2], 16) for i in range(0, len(crc_string), 2)])


class ParseThePotatoes(object):
    def __init__(self, file):
        self.file = open(file, "rb+")

        self.address_list = (
            ([0xc0, 0xe5, 0xe7, 0xee], [0x380, 0x3a5, 0x3a7, 0x3ae]),
            ([0x100, 0x125, 0x127, 0x12e], [0x340, 0x365, 0x367, 0x36e])
        )

        self.valid_bytes = ["b040", "af40", "6440"]

    def check_card_type(self):
        for address in self.address_list:
            if self.file.seek(address[0][0]) and self.file.read(2).hex() in self.valid_bytes and self.file.seek(
                    address[1][0]) and self.file.read(2).hex() in self.valid_bytes:
                return address

        printEx("Unknown card type.", PrintType.Error)
        self.close_file()
        sys.exit(1)

    def write_dump(self, address_list, travels):
        for address in address_list:
            # block 3, crdit value
            self.file.seek(address[1])
            self.file.write(bytearray.fromhex(hex_travels(travels)))

            # number of times the card has been manipulated
            self.file.seek(address[2])
            # read data from dump, get hex val as str
            data = self.file.read(2).hex()
            # hex string to int
            counter = int(data, base=16)
            # increment by 16 and convert to str hex with leading 0 if that's the case
            counter = '%04x' % (counter + 16)
            self.file.seek(address[2])
            # convert str to bytearray and write to file
            self.file.write(bytearray.fromhex(counter))

            # start of sector 3
            self.file.seek(address[0])
            # we need the whole sector without the last 2 bytes to calculate CRC
            sector = self.file.read(46).hex()
            # calc crc
            crc_val = calc_crc(sector)
            # it needs to be flipped: lsb msb
            crc_val = crc_val[2:] + crc_val[0:2]
            # crc address
            self.file.seek(address[3])
            self.file.write(bytearray.fromhex(crc_val))

    def get_info(self, address_list):
        self.file.seek(address_list[0][1])
        credit = str((int(self.file.read(2).hex(), base=16) - 0x8000) / 8)
        travels = str(int(float(float(credit)) / TRAVEL_PRICE))
        credit = str(float(int(float(credit)) / 100))

        self.file.seek(address_list[0][2])
        counter = str(int(self.file.read(2).hex(), base=16) / 16)

        self.file.seek(address_list[0][3])
        crc_val = self.file.read(2).hex()

        self.file.seek(0x0)
        uid = self.file.read(4).hex()

        return ("[ UID: %s | Credit: %s RON | Travels: %s | Counter: %s | CRC: %s]" %
                (uid, credit, travels, counter, crc_val))

    def close_file(self):
        self.file.close()


crc = CRC(0x1021)


def main():
    parser = argparse.ArgumentParser(usage='./ratb_pwn.py [info, mod] [-h]',
                                     formatter_class=argparse.RawDescriptionHelpFormatter, description=(Banner.SHOW))
    subparsers = parser.add_subparsers(dest='action', help='Action to perform on ratb mfd dumps')

    info_parser = subparsers.add_parser('info', help='Parse dump and print relevant information',
                                        usage='./ratb_pwn.py info FILE')
    info_parser.add_argument('file', help='RATB mfd file')

    mod_parser = subparsers.add_parser('mod', help='Modify dump with n travels (max 31)',
                                       usage='./ratb_pwn.py mod FILE TRAVELS')
    mod_parser.add_argument('file', help='RATB mfd file')
    mod_parser.add_argument('travels', help='Number of travels required (max 31)')
    mod_parser.add_argument('-w', '--write', help='Write dump to card', action='store_true')

    args = parser.parse_args()

    # Info
    if args.action == "info":
        printEx("Exctracting card info", PrintType.Info)

        if os.path.isfile(args.file):
            kek = ParseThePotatoes(args.file)
            print(kek.get_info(kek.check_card_type()))
            kek.close_file()

        else:
            printEx("No such file '%s'" % args.file, PrintType.Error)

    # Mod
    elif args.action == "mod":

        if os.path.isfile(args.file):
            if int(args.travels) in range(0, 32):
                printEx("Writing file..", PrintType.Info)

                kek = ParseThePotatoes(args.file)
                kek.write_dump(kek.check_card_type(), int(args.travels))
                print(kek.get_info(kek.check_card_type()))
                kek.close_file()

                printEx("File written succesfully", PrintType.Ok)

                if args.write:
                    printEx("Writing dump to card..", PrintType.Info)
                    os.system("sudo nfc-mfclassic w b %s %s" % (args.file, args.file))

            else:
                printEx("Travels must be in range(0, 31)", PrintType.Error)
        else:
            printEx("No such file '%s'" % args.file, PrintType.Error)

    # No actions matched
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
