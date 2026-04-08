const express = require('express');
const router = express.Router();
const Joi = require('joi');
const { User } = require('../models');
const { generateToken } = require('../middleware/auth');
const { validate } = require('../middleware/validator');

const loginSchema = Joi.object({
  firebase_uid: Joi.string().required(),
  email: Joi.string().email().required(),
  role: Joi.string().valid('student', 'faculty', 'committee', 'admin').required(),
  student_uid: Joi.string().allow('', null),
});

/**
 * POST /api/auth/login
 * Generate JWT token for authenticated Firebase user
 */
router.post('/login', validate(loginSchema), async (req, res) => {
  const { firebase_uid, email, role, student_uid } = req.body;

  // Find or create user in backend database
  let [user, created] = await User.findOrCreate({
    where: { firebase_uid },
    defaults: {
      email,
      role,
      student_uid,
      last_login: new Date()
    }
  });

  if (!created) {
    // Update last login if user already exists
    await user.update({ last_login: new Date() });
  }

  // Generate JWT token
  const token = generateToken(user);

  res.json({
    success: true,
    token,
    user: {
      id: user.id,
      email: user.email,
      role: user.role,
      student_uid: user.student_uid
    }
  });
});

/**
 * POST /api/auth/verify
 * Verify JWT token validity
 */
router.post('/verify', async (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ valid: false, error: 'No token provided' });
  }

  const jwt = require('jsonwebtoken');
  const decoded = jwt.verify(token, process.env.JWT_SECRET);
  
  res.json({ valid: true, user: decoded });
});

module.exports = router;
