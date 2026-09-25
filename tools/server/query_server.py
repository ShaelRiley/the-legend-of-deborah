"""Read-only Source A2S_INFO check, with the current challenge response path."""
import json
import socket
import struct
import sys


def query(host, port=27015):
    request = b'\xff\xff\xff\xffTSource Engine Query\x00'
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.settimeout(2)
        sock.connect((host, port))
        sock.send(request)
        data = sock.recv(65535)
        if data[:5] == b'\xff\xff\xff\xffA':
            if len(data) != 9:
                raise ValueError('Malformed query challenge')
            sock.send(request + data[5:9])
            data = sock.recv(65535)
    if data[:5] != b'\xff\xff\xff\xffI':
        raise ValueError('Not a supported Source INFO response')
    pos = 6
    fields = {}
    for name in ('name', 'map', 'folder', 'game'):
        end = data.index(b'\0', pos)
        fields[name] = data[pos:end].decode('utf-8', 'replace')
        pos = end + 1
    fields['app_id'], fields['players'], fields['max_players'], fields['bots'] = struct.unpack_from('<HBBB', data, pos)
    pos += 5
    fields['server_type'], fields['environment'] = chr(data[pos]), chr(data[pos+1])
    fields['password'], fields['vac'] = bool(data[pos+2]), bool(data[pos+3])
    if fields['map'] != 'gm_flatgrass' or fields['folder'] != 'garrysmod' or 'Deborah' not in fields['name']:
        raise ValueError('Unexpected server identity: ' + json.dumps(fields))
    if fields['password'] or fields['max_players'] == 0:
        raise ValueError('Server is not publicly joinable: ' + json.dumps(fields))
    return fields


if __name__ == '__main__':
    print(json.dumps(query(sys.argv[1] if len(sys.argv) > 1 else '40.160.86.240'), sort_keys=True))
