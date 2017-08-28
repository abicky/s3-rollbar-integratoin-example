const https = require('https');
const AWS = require('aws-sdk');
const s3 = new AWS.S3();

const postToRollbar = (message) => {
  const payload = JSON.stringify({
    access_token: process.env['ROLLBAR_ACCESS_TOKEN'],
    data: {
      environment: 'test',
      body: {
        message: {
          body: message,
        },
      },
    },
  });

  const options = {
    host: 'api.rollbar.com',
    path: '/api/1/item/',
    port: 443,
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'Content-Length': Buffer.byteLength(payload),
    },
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let responseBody = '';
      res.on('data', chunk => responseBody += chunk);

      res.on('end', () => {
        const data = JSON.parse(responseBody);
        if (data.err === 0) {
          resolve();
        } else {
          reject(new Error(data.message));
        }
      });
    });

    req.on('error', err => reject(err));

    req.write(payload);
    req.end();
  });
};

exports.handler = (event, context, callback) => {
  const bucket = event.Records[0].s3.bucket.name;
  const key = event.Records[0].s3.object.key;

  console.log(`Process ${bucket}/${key}`);
  s3.getObject({ Bucket: bucket, Key: key }).promise().then((data) => {
    postToRollbar(data.Body.toString());
  }).then(() => {
    callback(null, 'done');
  }).catch((err) => {
    callback(err);
  });
};
