const { body } = require('express-validator');

const registerValidation = [
	body('firstName')
		.trim()
		.notEmpty()
		.withMessage('First name is required')
		.isLength({ max: 100 })
		.withMessage('First name must be at most 100 characters'),
	body('lastName')
		.trim()
		.notEmpty()
		.withMessage('Last name is required')
		.isLength({ max: 100 })
		.withMessage('Last name must be at most 100 characters'),
	body('username')
		.optional({ values: 'falsy' })
		.trim()
		.isLength({ max: 100 })
		.withMessage('Username must be at most 100 characters'),
	body('phone')
		.optional({ values: 'falsy' })
		.trim()
		.isLength({ max: 30 })
		.withMessage('Phone must be at most 30 characters'),
	body('email')
		.trim()
		.notEmpty()
		.withMessage('Email is required')
		.isEmail()
		.withMessage('A valid email address is required')
		.normalizeEmail(),
	body('password')
		.notEmpty()
		.withMessage('Password is required')
		.isLength({ min: 8 })
		.withMessage('Password must be at least 8 characters')
		.matches(/[A-Z]/)
		.withMessage('Password must contain at least one uppercase letter')
		.matches(/[a-z]/)
		.withMessage('Password must contain at least one lowercase letter')
		.matches(/[0-9]/)
		.withMessage('Password must contain at least one number'),
	body('confirmPassword')
		.notEmpty()
		.withMessage('Password confirmation is required')
		.custom((value, { req }) => {
			if (value !== req.body.password) {
				throw new Error('Passwords do not match');
			}
			return true;
		}),
	body('university')
		.trim()
		.notEmpty()
		.withMessage('University name is required')
		.isLength({ max: 200 })
		.withMessage('University name must be at most 200 characters'),
	body('department')
		.trim()
		.notEmpty()
		.withMessage('Department is required')
		.isLength({ max: 200 })
		.withMessage('Department must be at most 200 characters'),
	body('preferredLanguage')
		.optional()
		.isIn(['English', 'Amharic'])
		.withMessage('Preferred language must be English or Amharic'),
	body('currency')
		.optional()
		.isIn(['ETB', 'USD'])
		.withMessage('Currency must be ETB or USD'),
	body('termsAccepted')
		.equals('true')
		.withMessage('You must accept the terms and conditions'),
];

const loginValidation = [
	body('email')
		.trim()
		.notEmpty()
		.withMessage('Email is required')
		.isEmail()
		.withMessage('A valid email address is required')
		.normalizeEmail(),
	body('password').notEmpty().withMessage('Password is required'),
];


const refreshValidation = [
  body('refreshToken')
    .trim()
    .notEmpty()
    .withMessage('Refresh token is required')
    .isLength({ min: 32 })
    .withMessage('Refresh token is invalid'),
];

const logoutValidation = [
	body('refreshToken')
		.optional({ values: 'falsy' })
		.trim()
		.isLength({ min: 32 })
		.withMessage('Refresh token is invalid'),
];

module.exports = {
	registerValidation,
	loginValidation,
	refreshValidation,
	logoutValidation,
};
