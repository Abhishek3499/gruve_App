# Edit Profile API Integration

## Files Created (Following Existing Complete Profile Pattern)

### Models
- `lib/screens/auth/api/models/edit_profile_response.dart` - API response model
- `lib/screens/auth/api/models/edit_profile_request.dart` - API request model

### Services  
- `lib/screens/auth/api/services/edit_profile_service.dart` - Dio API calls

### Controllers
- `lib/screens/auth/api/controllers/edit_profile_controller.dart` - Business logic

### Updated Files
- `lib/features/profile/screens/edit_profile_screen.dart` - Dynamic API integration
- `lib/features/profile/widgets/personal_info_card.dart` - Conditional field display

## API Endpoints

### Fetch Profile
- **Method**: `GET /user/edit_profile/`
- **Authentication**: Bearer token from TokenStorage
- **Response**: EditProfileResponse with user data

### Update Profile
- **Method**: `PATCH /user/edit_profile/`
- **Authentication**: Bearer token from TokenStorage
- **Request**: EditProfileRequest with editable fields
- **Response**: Updated EditProfileResponse

## Field Configuration

### Editable Fields (Sent to API)
- `full_name` - Full name
- `username` - Username
- `bio` - Bio (optional)

### Read-only Fields (Display only)
- `profile_picture` - Profile picture URL
- `email` - Email (shown only if not null)
- `phone` - Phone (shown only if not null)
- `gender` - Gender (always read-only)

## Features

- **Automatic data loading** when screen opens
- **Form validation** with user-friendly error messages
- **Loading states** with progress indicators
- **Error handling** for network, auth, and validation errors
- **Conditional field display** based on data availability
- **Profile picture integration** with existing ProfileImagePicker

## Usage

```dart
// Navigate to Edit Profile screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const EditProfileScreen(),
  ),
);
```

## Implementation Details

- Follows exact same pattern as CompleteProfileService
- Uses TokenStorage.getAccessToken() for authentication
- Uses dotenv.env['BASE_URL'] for base URL
- Reuses existing widgets and UI components
- No hardcoded values - all data from API
- Proper error handling and loading states
