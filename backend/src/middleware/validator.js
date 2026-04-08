const Joi = require("joi");

/**
 * Higher-order function that returns a Joi validation middleware
 * @param {Joi.ObjectSchema} schema Joi validation schema
 * @param {string} property Request property to validate (body, query, params)
 * @returns {AsyncFunction} Validation middleware
 */
const validate = (schema, property = "body") => {
  return (req, res, next) => {
    const { error } = schema.validate(req[property]);
    if (!error) {
      next();
    } else {
      const { details } = error;
      const message = details.map((i) => i.message).join(",");
      const validationError = new Error(message);
      validationError.status = 422;
      next(validationError);
    }
  };
};

module.exports = {
  validate,
};
