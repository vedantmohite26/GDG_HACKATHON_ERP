const express = require('express');
const router = express.Router();
const { verifyToken, requireRole } = require('../middleware/auth');
const { validate } = require('../middleware/validator');
const {
  generateCertificate,
  verifyCertificate,
  getStudentCertificates,
  revokeCertificate,
  generateCertificateSchema,
  revokeCertificateSchema
} = require('../controllers/certificateController');

/**
 * POST /api/certificates/generate
 * Generate a new certificate (faculty/committee only)
 */
router.post(
  '/generate',
  verifyToken,
  requireRole('faculty', 'committee', 'admin'),
  validate(generateCertificateSchema),
  generateCertificate
);

/**
 * GET /api/certificates/verify/:certificate_id
 * Verify certificate validity (public endpoint)
 */
router.get(
  '/verify/:certificate_id',
  verifyCertificate
);

/**
 * GET /api/certificates/student/:student_uid
 * Get all certificates for a student
 */
router.get(
  '/student/:student_uid',
  verifyToken,
  getStudentCertificates
);

/**
 * POST /api/certificates/revoke/:certificate_id
 * Revoke a certificate (admin only)
 */
router.post(
  '/revoke/:certificate_id',
  verifyToken,
  requireRole('admin', 'committee'),
  validate(revokeCertificateSchema),
  revokeCertificate
);

module.exports = router;

module.exports = router;
