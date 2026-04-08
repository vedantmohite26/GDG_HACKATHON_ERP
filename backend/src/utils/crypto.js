const crypto = require('crypto');

/**
 * Generate SHA-256 hash of data
 */
function generateHash(data) {
  return crypto.createHash('sha256').update(JSON.stringify(data)).digest('hex');
}

/**
 * Sign data using RSA private key
 */
function signData(data, privateKey) {
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(JSON.stringify(data));
  sign.end();
  return sign.sign(privateKey, 'base64');
}

/**
 * Verify signature using RSA public key
 */
function verifySignature(data, signature, publicKey) {
  try {
    const verify = crypto.createVerify('RSA-SHA256');
    verify.update(JSON.stringify(data));
    verify.end();
    return verify.verify(publicKey, signature, 'base64');
  } catch (error) {
    console.error('Signature verification error:', error);
    return false;
  }
}

/**
 * Generate RSA key pair (for initial setup)
 */
function generateKeyPair() {
  const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: {
      type: 'spki',
      format: 'pem'
    },
    privateKeyEncoding: {
      type: 'pkcs8',
      format: 'pem'
    }
  });
  
  return { publicKey, privateKey };
}

/**
 * Create certificate data object for signing
 */
function createCertificateData(certificateInfo) {
  return {
    student_uid: certificateInfo.student_uid,
    student_name: certificateInfo.student_name,
    student_id: certificateInfo.student_id,
    course: certificateInfo.course,
    semester: certificateInfo.semester,
    cgpa: certificateInfo.cgpa,
    sgpa: certificateInfo.sgpa,
    issued_date: certificateInfo.issued_date
  };
}

module.exports = {
  generateHash,
  signData,
  verifySignature,
  generateKeyPair,
  createCertificateData
};
