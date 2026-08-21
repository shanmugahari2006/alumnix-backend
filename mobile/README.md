# Alumnix Mobile (Flutter) 🎓📱

The cross-platform collegiate alumni and networking mobile application for **Alumnix**.

## 🎨 Design System: Convocation
- **Primary Color**: Deep Ink Navy (`#1B2A4A`)
- **Accent / Secondary**: Warm Gold (`#C9A15C`)
- **Background**: Off-white Paper (`#F7F5F0`)
- **Surface**: Crisp White (`#FFFFFF`)
- **Success**: Forest Green (`#2F5D4E`)
- **Error**: Muted Crimson (`#B3403A`)
- **Typography**: Fraunces (Headings, Medallions, Editorial) & IBM Plex Sans (Body, Inputs, Badges)

## 🚀 Key Modules
1. **Authentication & Onboarding**: 4-step student/alumni USN registration wizard, 6-box OTP verification, password strength meter, faculty verification, and admin approval moderation.
2. **Alumni Directory**: Debounced 400ms search, branch/grad-year/location/skill filters, profile medallion, and LinkedIn url launcher integration.
3. **Job Portal & ATS**: Categorized job feed, PDF resume submission, push-replacement job poster, and applicant tracking segmented status updates.
4. **Success Stories Feed**: Editorial magazine layout, scale-bounce optimistic like animations, author medallions, and full story reader.
5. **Startup Fundraising & Native Payments**: 2-column campaign cards, real-time funding progress bars, and native Razorpay SDK (`razorpay_flutter`) payment verification & status retry.
6. **Events & Collegiate Bulletin**: Soonest-first chronological event feed, live registration deadline countdown banner, and optimistic seat reservation.

## 🛠️ Stack
- **Framework**: Flutter (Material 3)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Navigation**: `go_router` (5-tab stateful shell routing)
- **Networking**: `dio` with JWT bearer interceptors & auto-refresh
- **Secure Storage**: `flutter_secure_storage`
- **Native Payments**: `razorpay_flutter`
