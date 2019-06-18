from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding
import base64

private_key = rsa.generate_private_key(
    public_exponent=374413471625854958269706803072259202131399386829497836277471117216044734280924224462969371,
    key_size=2048,
    backend=default_backend()
)
public_key = private_key.public_key()

pem = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.NoEncryption()
)

with open('/tmp/private_key.pem', 'wb') as f:
    f.write(pem)

pem = public_key.public_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PublicFormat.SubjectPublicKeyInfo
)

with open('/tmp/public_key.pem', 'wb') as f:
    f.write(pem)

with open("/tmp/privatekey", "rb") as key_file:
    private_key = serialization.load_pem_private_key(
        key_file.read(),
        password=None,
        backend=default_backend()
    )
with open("/tmp/public_key.pem", "rb") as key_file:
    public_key = serialization.load_pem_public_key(
        key_file.read(),
        backend=default_backend()
    )

message = b'encrypt me!'

encrypted = public_key.encrypt(
    message,
    padding.OAEP(
        mgf=padding.MGF1(algorithm=hashes.SHA256()),
        algorithm=hashes.SHA256(),
        label=None
    )
)

with open("/tmp/encrypted.letter", "wb") as letter:
    letter.write(base64.b64encode(encrypted))


with open("/tmp/ico", "rt") as x:
    message2 = x.read()
message2 = base64.b64decode(message2)

orig = private_key.decrypt(
    message2,
    padding.OAEP(
        mgf=padding.MGF1(algorithm=hashes.SHA1()),
        algorithm=hashes.SHA1(),
        label=None
    )
)

print(orig)
