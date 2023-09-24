#!/bin/bash

cd ./work

jq -r .PublicKey import.txt > PublicKey.b64
jq -r .ImportToken import.txt > ImportToken.b64

openssl enc -d -base64 -A -in PublicKey.b64 -out WrappingPublicKey.bin
openssl enc -d -base64 -A -in ImportToken.b64 -out ImportToken.bin

openssl rand -out PlaintextKeyMaterial.bin 32

openssl pkeyutl \
    -encrypt \
    -in PlaintextKeyMaterial.bin \
    -out EncryptedKeyMaterial.bin \
    -inkey WrappingPublicKey.bin \
    -keyform DER \
    -pubin \
    -pkeyopt rsa_padding_mode:oaep \
    -pkeyopt rsa_oaep_md:sha256 \
    -pkeyopt rsa_mgf1_md:sha256