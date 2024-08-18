# AWS KMS Key with external key material

## Key Creation & import

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
sudo chmod 700 wrapKey.sh 

bash wrapKey.sh
```

Import the key material into KMS:

```sh
aws kms import-key-material --key-id 1234abcd-12ab-34cd-56ef-1234567890ab \
    --encrypted-key-material fileb://work/EncryptedKeyMaterial.bin \
    --import-token fileb://work/ImportToken.bin \
    --expiration-model KEY_MATERIAL_DOES_NOT_EXPIRE
```

💡 To add expiration to the key, change the following:

```sh
--expiration-model KEY_MATERIAL_EXPIRES \
--valid-to 2023-06-17T12:00:00-08:00
```

Test the key:

```sh
aws kms encrypt \
    --key-id alias/MyImportedKey \
    --plaintext c2Vuc2l0aXZlIGRhdGEK \
    --output text \
    --query CiphertextBlob | base64 \
    --decode > ./work/ExampleEncryptedFile
```

## Key Management

### Rotating keys

It is not possible to automatically rotate keys with imported keys.

You'll need to generate a new KMS Key, import a new key, and then change the alias pointer:

```sh
aws kms update-alias \
    --alias-name alias/MyImportedKey \
    --target-key-id "<< NEW KEY ID >>"
```

### Deleting keys

You cannot immediately delete a KMS Key.

Options are:
- Disable the key.
- Delete the key material (imported keys only).
- Schedule for deletion with the standard range of 7-30 days.

When the key material is deleted, it is only possible to upload the same previous key material (view next section).

### Re-upload key material

**🚨 You cannot change the key material. Only [re-upload][1] the same material.**

You simulate this by testing:

```sh
mv work work-backup

aws kms get-parameters-for-import \
    --key-id 1234abcd-12ab-34cd-56ef-1234567890ab \
    --wrapping-algorithm RSAES_OAEP_SHA_256 \
    --wrapping-key-spec RSA_3072 \
    > ./work/import.txt
```

You'll get an error. Even if you delete the key material, you can only import the same that was previously used.


[1]: https://docs.aws.amazon.com/kms/latest/developerguide/importing-keys-import-key-material.html
