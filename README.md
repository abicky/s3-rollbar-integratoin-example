# Example of Rollbar integration with S3

## 1. Create a S3 bucket and a lambda function

```
% cat <<EOF > .envrc
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export TF_VAR_rollbar_access_token=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
export TF_VAR_bucket=YOUR_BACKET_NAME
EOF
% direnv allow
% make
```

## 2. Upload a JSON file to your backet

```
% aws s3 cp /path/to/json s3://YOUR_BACKET_NAME/
```

You will receive an item in Rollbar!
