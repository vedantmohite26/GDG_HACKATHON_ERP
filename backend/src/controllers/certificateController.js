const Joi = require('joi');
const { Certificate } = require('../models');
const { 
  generateHash, 
  signData, 
  verifySignature, 
  createCertificateData 
} = require('../utils/crypto');
const { validate } = require('../middleware/validator');

// Validation Schemas
const generateCertificateSchema = Joi.object({
  student_uid: Joi.string().required(),
  student_name: Joi.string().required(),
  student_id: Joi.string().required(),
  course: Joi.string().required(),
  semester: Joi.string().required(),
  cgpa: Joi.number().min(0).max(10).required(),
  sgpa: Joi.number().min(0).max(10).required(),
  metadata: Joi.object().optional()
});

const revokeCertificateSchema = Joi.object({
  reason: Joi.string().min(5).required()
});

/**
 * Generate a new certificate
 */
const generateCertificate = async (req, res) => {
  const { 
    student_uid, 
    student_name, 
    student_id, 
    course, 
    semester, 
    cgpa, 
    sgpa,
    metadata 
  } = req.body;

  // Only faculty and committee can generate certificates
  if (!['faculty', 'committee', 'admin'].includes(req.user.role)) {
    const error = new Error('Unauthorized to generate certificates');
    error.status = 403;
    throw error;
  }

  // Create certificate data for signing
  const certificateData = createCertificateData({
    student_uid,
    student_name,
    student_id,
    course,
    semester,
    cgpa,
    sgpa,
    issued_date: new Date().toISOString()
  });

  // Generate hash
  const certificateHash = generateHash(certificateData);

  // Sign the certificate
  const privateKey = process.env.CERTIFICATE_PRIVATE_KEY;
  if (!privateKey) {
    throw new Error('Server Configuration Error: Certificate signing key missing');
  }
  
  const digitalSignature = signData(certificateData, privateKey);

  // Save to database
  const certificate = await Certificate.create({
    student_uid,
    student_name,
    student_id,
    course,
    semester,
    cgpa,
    sgpa,
    issued_date: new Date(),
    digital_signature: digitalSignature,
    certificate_hash: certificateHash,
    metadata: metadata || {}
  });

  res.status(201).json({
    success: true,
    certificate: {
      certificate_id: certificate.certificate_id,
      student_name: certificate.student_name,
      course: certificate.course,
      semester: certificate.semester,
      cgpa: certificate.cgpa,
      sgpa: certificate.sgpa,
      issued_date: certificate.issued_date,
      certificate_hash: certificate.certificate_hash
    }
  });
};

/**
 * Verify a certificate
 */
const verifyCertificate = async (req, res) => {
  const { certificate_id } = req.params;

  // Find certificate in database
  const certificate = await Certificate.findByPk(certificate_id);

  if (!certificate) {
    return res.status(404).json({ 
      valid: false, 
      error: 'Certificate not found' 
    });
  }

  // Check if revoked
  if (certificate.is_revoked) {
    return res.json({
      valid: false,
      error: 'Certificate has been revoked',
      revoke_reason: certificate.revoke_reason,
      revoked_at: certificate.revoked_at
    });
  }

  // Recreate certificate data
  const certificateData = createCertificateData({
    student_uid: certificate.student_uid,
    student_name: certificate.student_name,
    student_id: certificate.student_id,
    course: certificate.course,
    semester: certificate.semester,
    cgpa: certificate.cgpa,
    sgpa: certificate.sgpa,
    issued_date: certificate.issued_date.toISOString()
  });

  // Verify hash
  const computedHash = generateHash(certificateData);
  const hashValid = computedHash === certificate.certificate_hash;

  // Verify signature
  const publicKey = process.env.CERTIFICATE_PUBLIC_KEY;
  if (!publicKey) {
    throw new Error('Server Configuration Error: Certificate public key missing');
  }
  
  const signatureValid = verifySignature(
    certificateData, 
    certificate.digital_signature, 
    publicKey
  );

  const isValid = hashValid && signatureValid;

  res.json({
    valid: isValid,
    certificate: isValid ? {
      certificate_id: certificate.certificate_id,
      student_name: certificate.student_name,
      student_id: certificate.student_id,
      course: certificate.course,
      semester: certificate.semester,
      cgpa: certificate.cgpa,
      sgpa: certificate.sgpa,
      issued_date: certificate.issued_date,
      metadata: certificate.metadata
    } : null,
    verification: {
      hash_valid: hashValid,
      signature_valid: signatureValid
    }
  });
};

/**
 * Get all certificates for a student
 */
const getStudentCertificates = async (req, res) => {
  const { student_uid } = req.params;

  // Students can only view their own certificates
  if (req.user.role === 'student' && req.user.student_uid !== student_uid) {
    const error = new Error('Unauthorized access to student certificates');
    error.status = 403;
    throw error;
  }

  const certificates = await Certificate.findAll({
    where: { 
      student_uid,
      is_revoked: false 
    },
    order: [['issued_date', 'DESC']]
  });

  res.json({
    success: true,
    count: certificates.length,
    certificates: certificates.map(cert => ({
      certificate_id: cert.certificate_id,
      course: cert.course,
      semester: cert.semester,
      cgpa: cert.cgpa,
      sgpa: cert.sgpa,
      issued_date: cert.issued_date
    }))
  });
};

/**
 * Revoke a certificate
 */
const revokeCertificate = async (req, res) => {
  const { certificate_id } = req.params;
  const { reason } = req.body;

  // Only admin can revoke
  if (!['admin', 'committee'].includes(req.user.role)) {
    const error = new Error('Unauthorized to revoke certificates');
    error.status = 403;
    throw error;
  }

  const certificate = await Certificate.findByPk(certificate_id);
  if (!certificate) {
    return res.status(404).json({ error: 'Certificate not found' });
  }

  await certificate.update({
    is_revoked: true,
    revoked_at: new Date(),
    revoke_reason: reason || 'No reason provided'
  });

  res.json({
    success: true,
    message: 'Certificate revoked successfully'
  });
};

module.exports = {
  generateCertificate,
  verifyCertificate,
  getStudentCertificates,
  revokeCertificate,
  generateCertificateSchema,
  revokeCertificateSchema
};

module.exports = {
  generateCertificate,
  verifyCertificate,
  getStudentCertificates,
  revokeCertificate
};
