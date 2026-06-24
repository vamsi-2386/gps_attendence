# Deployment Checklist

## Pre-Deployment Configuration

### Environment Setup
- [ ] Create `.env` file with actual credentials
- [ ] Set SUPABASE_URL to your Supabase project URL
- [ ] Set SUPABASE_ANON_KEY with correct anon key
- [ ] Set SUPABASE_SERVICE_KEY for admin operations
- [ ] Set API_BASE_URL to FastAPI server URL (http://10.79.79.4:8000)
- [ ] Verify all environment variables are set correctly
- [ ] Test environment variable loading in app

### Database Setup

#### Supabase Project Creation
- [ ] Create Supabase account at https://supabase.com
- [ ] Create new Supabase project
- [ ] Copy project URL and anon key to `.env`
- [ ] Enable PostgreSQL extensions:
  - [ ] uuid-ossp
  - [ ] vector (for embeddings)
- [ ] Run DATABASE_SETUP.sql in Supabase SQL editor
- [ ] Verify all tables created successfully

#### Table Verification
- [ ] companies table exists with correct columns
- [ ] employees table exists with correct columns
- [ ] offices table exists with correct columns
- [ ] attendance_logs table exists with correct columns
- [ ] leave_requests table exists with correct columns
- [ ] face_embeddings table exists with correct columns
- [ ] voice_embeddings table exists with correct columns

#### Indexes and Constraints
- [ ] All foreign key constraints created
- [ ] All indexes created for performance
- [ ] Unique constraints on email and employee_id
- [ ] Check constraints on status fields

#### Row Level Security (RLS)
- [ ] RLS enabled on all tables
- [ ] Read policies configured
- [ ] Insert policies configured
- [ ] Update policies configured
- [ ] Test RLS policies with sample queries

#### Storage Buckets
- [ ] Create 'face-images' bucket
- [ ] Create 'voice-data' bucket
- [ ] Create 'profile-pictures' bucket
- [ ] Create 'documents' bucket
- [ ] Configure bucket access policies
- [ ] Enable public access for required buckets

### FastAPI Backend

#### Endpoint Setup
- [ ] Flask/FastAPI server deployed
- [ ] `/api/v1/health` endpoint implemented
- [ ] `/api/v1/face/login` endpoint implemented
- [ ] `/api/v1/attendance/check-in` endpoint implemented
- [ ] `/api/v1/attendance/check-out` endpoint implemented
- [ ] `/api/v1/attendance/history` endpoint implemented
- [ ] `/api/v1/leave/apply` endpoint implemented
- [ ] `/api/v1/leave/history` endpoint implemented

#### Face Recognition
- [ ] Face detection model loaded
- [ ] Face embedding model loaded
- [ ] Minimum confidence threshold set (default 0.7)
- [ ] Model tested with sample images
- [ ] GPU acceleration configured (optional)

#### Error Handling
- [ ] Proper error responses (400, 401, 500)
- [ ] Error logging configured
- [ ] Request validation implemented
- [ ] CORS configured for Flutter app

#### Testing
- [ ] Health check passes: `curl http://10.79.79.4:8000/api/v1/health`
- [ ] All endpoints tested with sample data
- [ ] Load testing completed
- [ ] Error scenarios tested

### Flutter App Setup

#### Dependencies
- [ ] `flutter pub get` completed successfully
- [ ] All pubspec.yaml dependencies resolved
- [ ] No version conflicts
- [ ] Platform-specific dependencies installed:
  - [ ] Android: Build configuration correct
  - [ ] iOS: Pods installed
  - [ ] Web: Web support configured

#### Configuration Files
- [ ] `.env` file created in project root
- [ ] `lib/config/supabase_config.dart` configured
- [ ] `lib/config/app_theme.dart` colors correct
- [ ] `lib/services/api_service.dart` base URL correct

#### Permissions
- [ ] Camera permission declared (AndroidManifest.xml, Info.plist)
- [ ] Location permission declared
- [ ] Storage permission declared
- [ ] Microphone permission declared (for voice recognition)

#### App Initialization
- [ ] `lib/main.dart` initializes SupabaseService
- [ ] Error handling for failed initialization
- [ ] Splash screen configured
- [ ] Navigation routes defined

### Testing Phase

#### Unit Tests
- [ ] Model serialization/deserialization tests
- [ ] SupabaseService method tests
- [ ] ApiService endpoint tests
- [ ] Error handling tests

#### Integration Tests
- [ ] End-to-end check-in flow
- [ ] End-to-end leave application flow
- [ ] Real-time subscription tests
- [ ] File upload/download tests

#### Manual Testing
- [ ] Test Supabase connection
- [ ] Test API health check
- [ ] Test face login flow
- [ ] Test check-in/check-out
- [ ] Test leave application
- [ ] Test real-time updates
- [ ] Test error scenarios
- [ ] Test offline handling

#### Performance Testing
- [ ] App startup time < 3 seconds
- [ ] Check-in API response < 2 seconds
- [ ] Data loading < 1 second for normal datasets
- [ ] Memory usage reasonable
- [ ] No memory leaks

#### Security Testing
- [ ] Sensitive data not logged
- [ ] Face embeddings encrypted
- [ ] Location data encrypted
- [ ] API tokens handled securely
- [ ] No hardcoded credentials

### Platform-Specific

#### Android
- [ ] Min SDK version set correctly
- [ ] Target SDK version updated
- [ ] Permissions in AndroidManifest.xml
- [ ] Build signing configured
- [ ] APK built and tested

#### iOS
- [ ] Deployment target set (12.0+)
- [ ] Permissions in Info.plist
- [ ] Bundle ID configured
- [ ] Provisioning profiles set up
- [ ] Code signing configured
- [ ] IPA built and tested

#### Web
- [ ] Web build configured
- [ ] CORS headers set up
- [ ] Web server running
- [ ] Web version tested

### Documentation

#### Code Documentation
- [ ] All classes documented with doc comments
- [ ] All public methods documented
- [ ] Complex logic explained
- [ ] Code examples provided

#### User Documentation
- [ ] README updated
- [ ] Setup instructions clear
- [ ] API documentation complete
- [ ] Troubleshooting guide included

#### Deployment Documentation
- [ ] Deployment steps documented
- [ ] Rollback procedure documented
- [ ] Emergency contacts listed
- [ ] Escalation path defined

### Monitoring and Logging

#### Supabase
- [ ] Query logging enabled
- [ ] Performance monitoring enabled
- [ ] Error tracking configured
- [ ] Real-time metrics available

#### FastAPI
- [ ] Request/response logging enabled
- [ ] Error logging configured
- [ ] Performance metrics tracked
- [ ] Slow query logging enabled

#### Flutter App
- [ ] Crash reporting configured (Firebase Crashlytics)
- [ ] Analytics configured
- [ ] Error logging configured
- [ ] Performance monitoring enabled

### Deployment Steps

#### Development Environment
- [ ] All code committed to version control
- [ ] Unit tests passing
- [ ] Code review completed
- [ ] Documentation updated

#### Staging Deployment
- [ ] Deploy to staging environment
- [ ] Run integration tests
- [ ] Test all features
- [ ] Load test
- [ ] Security audit
- [ ] Performance audit

#### Production Deployment
- [ ] Backup database
- [ ] Run DATABASE_SETUP.sql (if needed)
- [ ] Deploy FastAPI backend
- [ ] Deploy Flutter app to app stores
- [ ] Verify all endpoints working
- [ ] Monitor for errors
- [ ] Verify real-time subscriptions
- [ ] Test with real users

### Post-Deployment

#### Verification
- [ ] App available on app stores
- [ ] API endpoints responding
- [ ] Database queries working
- [ ] Real-time updates functioning
- [ ] File uploads/downloads working
- [ ] Face recognition working
- [ ] Geofence checks working

#### Monitoring
- [ ] Error rates normal
- [ ] Response times acceptable
- [ ] Database load reasonable
- [ ] Storage usage within limits
- [ ] API quota not exceeded

#### User Communication
- [ ] Release notes published
- [ ] Users notified of deployment
- [ ] Help documentation available
- [ ] Support team briefed

#### Maintenance
- [ ] Daily monitoring
- [ ] Weekly backups
- [ ] Monthly security updates
- [ ] Quarterly performance review
- [ ] Annual security audit

## Quick Start Checklist (Day 1)

- [ ] Clone repository
- [ ] Create `.env` file with local credentials
- [ ] Run `flutter pub get`
- [ ] Create Supabase project
- [ ] Run DATABASE_SETUP.sql
- [ ] Update Supabase credentials in `.env`
- [ ] Start FastAPI backend
- [ ] Run `flutter run` to test app
- [ ] Test basic check-in flow
- [ ] Review BACKEND_INTEGRATION.md

## Common Issues and Solutions

### Issue: "Supabase not initialized"
**Solution**: Ensure `SupabaseService.initialize()` is called in main() before accessing services

### Issue: "API connection refused"
**Solution**: Check FastAPI server is running and API_BASE_URL in .env is correct

### Issue: "Face recognition not working"
**Solution**: Verify image quality, minimum size (100x100), and confidence threshold settings

### Issue: "Location permission denied"
**Solution**: Request permission in app, verify app settings on device

### Issue: "Database connection timeout"
**Solution**: Check Supabase project is active, verify network connectivity

## Contacts and Escalation

### Development Team
- **Team Lead**: [Name and contact]
- **Backend Developer**: [Name and contact]
- **Mobile Developer**: [Name and contact]
- **DevOps**: [Name and contact]

### Support Team
- **First Level Support**: [Name and contact]
- **Escalation**: [Manager contact]
- **Emergency**: [Emergency contact]

### Service Providers
- **Supabase Support**: https://supabase.com/support
- **Google Play Support**: https://support.google.com/googleplay
- **Apple App Store Support**: https://developer.apple.com/contact/

## Version History

| Version | Date | Changes | Status |
|---------|------|---------|--------|
| 1.0 | 2024-06-23 | Initial deployment | In Progress |

---

**Last Updated**: 2026-06-23
**Status**: Ready for Deployment
**Estimated Deployment Time**: 2-3 hours

**Note**: Complete all items in this checklist before deploying to production.
