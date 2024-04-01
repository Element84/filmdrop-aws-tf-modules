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
    let auth_header = event.request.headers.authorization;
    let clientIP = event.viewer.ip;
    let credentialsList = null;
    let whitelistedIPsList = null;
    let whitelistedRefererList = null;
    let unsupportedBasicAuth = null;
    try {
        credentialsList = await kvsHandle.get('credentialsList');
    } catch (err) {
        console.log("Kvs key lookup failed for credentialsList: ", err);
    }
    try {
        whitelistedIPsList = await kvsHandle.get('whitelistedIPsList');
    } catch (err) {
        console.log("Kvs key lookup failed for whitelistedIPsList: ", err);
    }
    try {
        whitelistedRefererList = await kvsHandle.get('whitelistedRefererList');
    } catch (err) {
        console.log("Kvs key lookup failed for whitelistedReferer: ", err);
    }
    try {
        unsupportedBasicAuth = await kvsHandle.get('unsupportedBasicAuth');
    } catch (err) {
        console.log("Kvs key lookup failed for unsupportedBasicAuth: ", err);
    }
    let filmdropAuthorized = event.request.headers['filmdrop-authorized'] ? event.request.headers['filmdrop-authorized'].value == "true" : false;
    let clientIpWhitelisted = whitelistedIPsList ? isIp4InCidrs(clientIP, whitelistedIPsList.split(",")) : false;
    let refererAuthorized = whitelistedRefererList && event.request.headers['referer'] ? whitelistedRefererList.split(",").findIndex(element => event.request.headers['referer'].value.includes(element)) : false;
    let unsupportedAuth = unsupportedBasicAuth ? unsupportedBasicAuth == "true" : false;
    // Check if credentials are valid for requests where the ip is not whitelisted
    if (credentialsList && !clientIpWhitelisted && !filmdropAuthorized && !refererAuthorized) {
        const creds = credentialsList.split(",");
        for (var i in creds) {
            // Forward the request if auth matches
            if (auth_header && auth_header.value === creds[i]) {
                if (unsupportedAuth) {
                    auth_header.value = "";
                }
                event.request.headers['filmdrop-authorized'] = {value: "true"};
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
        if (unsupportedAuth) {
            auth_header.value = "";
        }
        return event.request;
    }
}
