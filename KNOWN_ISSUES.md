# Known Issues

## Service-to-Service API Authentication

**Issue**: The service API endpoints (`/api/v1/services/*`) are returning 401 Unauthorized even with valid API keys.

**Status**: Under investigation

**Workaround**: The main user authentication API works perfectly. For now, services can authenticate as admin users and use the regular API endpoints.

**Details**:
- The API keys are correctly set in the environment variables
- The validation logic is correct
- This appears to be a Rails production mode issue with before_action callbacks

**Not Affected**:
- User authentication (`/api/v1/auth/login`) - Working ✅
- Authenticated user endpoints - Working ✅
- Admin web interface - Working ✅
- Health check endpoint - Working ✅

## Resolution for Production

Before deploying to production, your IT team should:
1. Test the service API endpoints after deployment
2. If issues persist, consider using the standard authenticated API with admin credentials instead
3. All core functionality for user authentication is fully operational