/**
 * Validate certificate generation request
 */
const validateCertificateGeneration = (req, res, next) => {
  const { student_uid, student_name, student_id, course, semester, cgpa, sgpa } = req.body;

  const errors = [];

  if (!student_uid || typeof student_uid !== 'string') {
    errors.push('student_uid is required and must be a string');
  }
  if (!student_name || typeof student_name !== 'string') {
    errors.push('student_name is required and must be a string');
  }
  if (!student_id || typeof student_id !== 'string') {
    errors.push('student_id is required and must be a string');
  }
  if (!course || typeof course !== 'string') {
    errors.push('course is required and must be a string');
  }
  if (!semester || typeof semester !== 'string') {
    errors.push('semester is required and must be a string');
  }
  if (cgpa === undefined || typeof cgpa !== 'number' || cgpa < 0 || cgpa > 10) {
    errors.push('cgpa is required and must be a number between 0 and 10');
  }
  if (sgpa === undefined || typeof sgpa !== 'number' || sgpa < 0 || sgpa > 10) {
    errors.push('sgpa is required and must be a number between 0 and 10');
  }

  if (errors.length > 0) {
    return res.status(400).json({ errors });
  }

  next();
};

/**
 * Validate certificate verification request
 */
const validateCertificateVerification = (req, res, next) => {
  const { certificate_id } = req.params;

  if (!certificate_id) {
    return res.status(400).json({ error: 'certificate_id is required' });
  }

  // UUID validation
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(certificate_id)) {
    return res.status(400).json({ error: 'Invalid certificate_id format' });
  }

  next();
};

module.exports = {
  validateCertificateGeneration,
  validateCertificateVerification
};
