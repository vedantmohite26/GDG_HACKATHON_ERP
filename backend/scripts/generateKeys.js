const { generateKeyPair } = require('../src/utils/crypto');
const fs = require('fs');
const path = require('path');

console.log('🔑 Generating RSA Key Pair...\n');

const { publicKey, privateKey } = generateKeyPair();

console.log('✅ Keys generated successfully!\n');
console.log('📋 Copy these values to your .env file:\n');
console.log('CERTIFICATE_PRIVATE_KEY:');
console.log(privateKey);
console.log('\nCERTIFICATE_PUBLIC_KEY:');
console.log(publicKey);
console.log('\n⚠️  IMPORTANT: Keep the private key secret!');
console.log('💡 TIP: You can also save these to files and reference them in .env');

// Optionally save to files
const keysDir = path.join(__dirname, '../keys');
if (!fs.existsSync(keysDir)) {
  fs.mkdirSync(keysDir, { recursive: true });
}

fs.writeFileSync(path.join(keysDir, 'private.pem'), privateKey);
fs.writeFileSync(path.join(keysDir, 'public.pem'), publicKey);

console.log('\n💾 Keys also saved to backend/keys/ directory');
