import cf from 'cloudfront';

const kvsId = '${KEY_VALUE_STORE_ID}';

// This fails if the key value store is not associated with the function
const kvsHandle = cf.kvs(kvsId);

const ip4ToInt = ip =>
  ip.split('.').reduce((int, oct) => (int << 8) + parseInt(oct, 10), 0) >>> 0;

const isIp4InCidr = ip => cidr => {
  let range = cidr.split('/')[0];
  let bits = cidr.split('/')[1];
  const mask = ~(2 ** (32 - bits) - 1);
  return (ip4ToInt(ip) & mask) === (ip4ToInt(range) & mask);
};

const isIp4InCidrs = (ip, cidrs) => cidrs.some(isIp4InCidr(ip));


async function handler(event) {
    var auth_header = event.request.headers.authorization;
    var clientIP = event.viewer.ip;
    let credentialsList = null;
    try {
        credentialsList = await kvsHandle.get('credentialsList');
    } catch (err) {
        console.log("Kvs key lookup failed for credentialsList: ", err);
    }
    let whitelistedIPsList = null;
    try {
        whitelistedIPsList = await kvsHandle.get('whitelistedIPsList');
    } catch (err) {
        console.log("Kvs key lookup failed for whitelistedIPsList: ", err);
    }
    let clientIpWhitelisted = whitelistedIPsList ? isIp4InCidrs(clientIP, whitelistedIPsList.split(",")) : false;
    // Check if credentials are valid for requests where the ip is not whitelisted
    if (credentialsList && !clientIpWhitelisted) {
        const creds = credentialsList.split(",");
        for (var i in creds) {
            // Forward the request if auth matches
            if (auth_header && auth_header.value === creds[i]) {
                return event.request;
            }
        }
        // If auth failed or not passed in, send response to set creds
        return {
            "statusCode": 401,
            "statusDescription": "Unauthorized",
            "headers": {
                "www-authenticate": {
                    "value": 'Basic realm="Enter credentials to access"'
                }
            }
        };
    } else {
        return event.request;
    }
}
