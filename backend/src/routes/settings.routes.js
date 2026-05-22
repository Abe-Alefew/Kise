router.get('/allowance', asyncHandler(SettingsController.getAllowance));

router.put(
  '/allowance',
  [
    body('monthlyAmount')
      .notEmpty()
      .withMessage('monthlyAmount is required')
      .isFloat({ min: 0 })
      .withMessage('monthlyAmount cannot be negative'),
    body('cycleStartDay')
      .notEmpty()
      .withMessage('cycleStartDay is required')
      .isInt({ min: 1, max: 28 })
      .withMessage('cycleStartDay must be between 1 and 28'),
  ],
  asyncHandler(SettingsController.updateAllowance)
);

router.get('/preferences', asyncHandler(SettingsController.getPreferences));

router.patch(
  '/preferences',
  [
    body('preferredLanguage')
      .optional()
      .isIn(UserPreferenceModel.allowedLanguages)
      .withMessage('preferredLanguage must be English or Amharic'),
    body('themeMode')
      .optional()
      .isIn(UserPreferenceModel.allowedThemeModes)
      .withMessage('themeMode must be light, dark, or system'),
  ],
  asyncHandler(SettingsController.updatePreferences)
);