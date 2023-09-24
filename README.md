# AWS KMS Key with external key material

Create the key with `EXTERNAL` origin configuration:

```sh
aws kms create-key --origin EXTERNAL --description "External key"

aws kms create-alias \
    --alias-name alias/MyImportedKey \
    --target-key-id 1234abcd-12ab-34cd-56ef-1234567890ab
```

Create the `work` directory where artifacts will be created:

```sh
mkdir work
```

Download the wrapping public key:

```sh
aws kms get-parameters-for-import \
    --key-id 1234abcd-12ab-34cd-56ef-1234567890ab \
    --wrapping-algorithm RSAES_OAEP_SHA_256 \
    --wrapping-key-spec RSA_3072 \
    > ./work/import.txt
```

Execute the script to prepare the key material:

```sh
bash wrapKey.sh
```

Import the key material into KMS:

```sh
aws kms import-key-material --key-id 1234abcd-12ab-34cd-56ef-1234567890ab \
    --encrypted-key-material fileb://work/EncryptedKeyMaterial.bin \
    --import-token fileb://work/ImportToken.bin \
    --expiration-model KEY_MATERIAL_DOES_NOT_EXPIRE
```

To add expiration to the key, change the following:

```sh
--expiration-model KEY_MATERIAL_EXPIRES \
--valid-to 2023-06-17T12:00:00-08:00
```
