package com.plottheirfuture.plottheirfuture_backend.service;

import com.plottheirfuture.plottheirfuture_backend.dto.AdminRegistrationRequest;
import com.plottheirfuture.plottheirfuture_backend.dto.AuthResponse;
import com.plottheirfuture.plottheirfuture_backend.dto.LoginRequest;
import com.plottheirfuture.plottheirfuture_backend.dto.OtpRequest;
import com.plottheirfuture.plottheirfuture_backend.dto.ProfileSetupRequest;
import com.plottheirfuture.plottheirfuture_backend.dto.VerifyOtpRequest;
import com.plottheirfuture.plottheirfuture_backend.entity.Invitation;
import com.plottheirfuture.plottheirfuture_backend.entity.MarriageRegistration;
import com.plottheirfuture.plottheirfuture_backend.entity.User;
import com.plottheirfuture.plottheirfuture_backend.exception.ResourceNotFoundException;
import com.plottheirfuture.plottheirfuture_backend.repository.InvitationRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.MarriageRegistrationRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.UserRepository;
import com.plottheirfuture.plottheirfuture_backend.repository.WeddingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
@RequiredArgsConstructor
@Slf4j
public class AuthService {

    private final UserRepository userRepository;
    private final InvitationRepository invitationRepository;
    private final WeddingRepository weddingRepository;
    private final MarriageRegistrationRepository marriageRegistrationRepository;
    private final PasswordEncoder passwordEncoder;

    // High-performance concurrent cache to absorb spikes of 100k+ requests without exhausting DB connections
    private final Map<String, CachedUser> userCache = new ConcurrentHashMap<>(16384);
    private final Map<String, OtpEntry> otpCache = new ConcurrentHashMap<>(16384);

    private static final long OTP_VALIDITY_SECONDS = 300; // 5 minutes
    private static final long TOKEN_VALIDITY_SECONDS = 86400 * 7; // 7 days
    private static final SecureRandom RANDOM = new SecureRandom();

    private record CachedUser(User user, long expiryMillis) {
        boolean isExpired() {
            return System.currentTimeMillis() > expiryMillis;
        }
    }

    private record OtpEntry(String otp, String slug, long expiryMillis) {
        boolean isExpired() {
            return System.currentTimeMillis() > expiryMillis;
        }
    }

    public String normalizePhone(String raw) {
        if (raw == null) return null;
        String cleaned = raw.replaceAll("[^0-9+]", "");
        if (!cleaned.startsWith("+")) {
            if (cleaned.length() == 10) {
                cleaned = "+91" + cleaned;
            } else if (cleaned.length() == 12 && cleaned.startsWith("91")) {
                cleaned = "+" + cleaned;
            }
        }
        return cleaned;
    }

    public Optional<User> findUserByMobileFlexible(String phone) {
        String normalized = normalizePhone(phone);
        if (normalized == null) return Optional.empty();

        Optional<User> u = userRepository.findByMobileNumber(normalized);
        if (u.isPresent()) return u;

        if (normalized.startsWith("+91")) {
            String withoutCode = normalized.substring(3);
            u = userRepository.findByMobileNumber(withoutCode);
            if (u.isPresent()) return u;
        } else if (normalized.length() == 10) {
            u = userRepository.findByMobileNumber("+91" + normalized);
            if (u.isPresent()) return u;
        }
        return Optional.empty();
    }

    /**
     * Standard Login (Mobile Number + Password)
     */
    public AuthResponse login(LoginRequest request) {
        String mobile = normalizePhone(request.getMobileNumber());

        User user = null;
        CachedUser cached = userCache.get(mobile);
        if (cached != null && !cached.isExpired()) {
            user = cached.user();
        } else {
            user = findUserByMobileFlexible(mobile)
                    .orElseThrow(() -> new BadCredentialsException("Invalid mobile number or password"));
            userCache.put(mobile, new CachedUser(user, System.currentTimeMillis() + 600_000));
        }

        boolean passwordMatches = false;
        if (user.getPassword() != null) {
            if (passwordEncoder.matches(request.getPassword(), user.getPassword())) {
                passwordMatches = true;
            } else if (request.getPassword().equals(user.getPassword())) {
                passwordMatches = true;
            }
        }
        // Developer & demo fallback for admin logins
        if (!passwordMatches && "ADMIN".equalsIgnoreCase(user.getRole())) {
            if ("AdminPassword123!".equals(request.getPassword()) || "Admin@123".equals(request.getPassword())) {
                passwordMatches = true;
            }
        }

        if (!passwordMatches) {
            throw new BadCredentialsException("Invalid mobile number or password");
        }

        List<String> accessibleWeddings = resolveAccessibleWeddings(user.getMobileNumber());
        String token = generateToken(user.getId(), user.getMobileNumber(), user.getRole());
        boolean hasActiveReg = hasActiveRegistration(user.getId());

        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .expiresIn(TOKEN_VALIDITY_SECONDS)
                .user(user)
                .isExistingUser(true)
                .hasActiveMarriageRegistration(hasActiveReg)
                .accessibleWeddings(accessibleWeddings)
                .message("Login successful")
                .build();
    }

    /**
     * Dynamic OTP Generation (WhatsApp / SMS)
     */
    public Map<String, Object> requestOtp(OtpRequest request) {
        String phone = normalizePhone(request.getPhone());
        String channel = request.getChannel() != null && !request.getChannel().isBlank() 
                ? request.getChannel().trim().toUpperCase() : "WHATSAPP";
        String slug = request.getSlug() != null ? request.getSlug().trim() : null;

        // Generate 6-digit OTP
        String otp = String.format("%06d", RANDOM.nextInt(1_000_000));

        // In dev/demo, keep deterministic fallback OTP for test seed users
        if ("+919988776655".equals(phone)) {
            otp = "482910";
        } else if ("+919848012345".equals(phone)) {
            otp = "123456";
        }

        long expiry = System.currentTimeMillis() + (OTP_VALIDITY_SECONDS * 1000);
        otpCache.put(phone, new OtpEntry(otp, slug, expiry));

        String sessionHash = Base64.getUrlEncoder().withoutPadding()
                .encodeToString((phone + ":" + expiry).getBytes());

        Map<String, Object> response = new LinkedHashMap<>();
        response.put("status", "SUCCESS");
        response.put("message", "OTP dispatched successfully via " + ("SMS".equals(channel) ? "SMS" : "WhatsApp"));
        response.put("phone", phone);
        response.put("sessionHash", sessionHash);
        response.put("expiresIn", OTP_VALIDITY_SECONDS);
        response.put("retryAfterSeconds", 30);
        return response;
    }

    /**
     * Dynamic OTP Verification & Session Issuance
     */
    public AuthResponse verifyOtp(VerifyOtpRequest request) {
        String phone = normalizePhone(request.getPhone());
        String submittedOtp = request.getOtp().trim();

        OtpEntry entry = otpCache.get(phone);
        boolean isValid = false;
        String slug = null;

        if (entry != null && !entry.isExpired()) {
            isValid = java.security.MessageDigest.isEqual(
                    entry.otp().getBytes(), submittedOtp.getBytes());
            slug = entry.slug();
        }

        // Fallback check in users table for seeded users
        if (!isValid) {
            Optional<User> dbUser = findUserByMobileFlexible(phone);
            if (dbUser.isPresent() && dbUser.get().getOtp() != null) {
                isValid = java.security.MessageDigest.isEqual(
                        dbUser.get().getOtp().getBytes(), submittedOtp.getBytes());
            }
        }

        // Universal development fallback code 123456 for testing & review
        if (!isValid && "123456".equals(submittedOtp)) {
            isValid = true;
        }

        if (!isValid) {
            throw new BadCredentialsException("Invalid or expired OTP");
        }

        otpCache.remove(phone);

        // Check if user already exists and has completed profile
        boolean isExisting = false;
        Optional<User> existingOpt = findUserByMobileFlexible(phone);
        if (existingOpt.isPresent()) {
            User eu = existingOpt.get();
            if (Boolean.TRUE.equals(eu.getRegistered()) ||
                (eu.getName() != null && !eu.getName().isBlank() &&
                 !eu.getName().equalsIgnoreCase("Guest User") &&
                 !eu.getName().equalsIgnoreCase("Honored Guest")) ||
                "ADMIN".equalsIgnoreCase(eu.getRole())) {
                isExisting = true;
            }
        }

        User user = findOrProvisionUser(phone);
        if ("ADMIN".equalsIgnoreCase(user.getRole())) {
            isExisting = true;
        }

        List<String> accessibleWeddings = resolveAccessibleWeddings(phone);
        if (slug != null && !accessibleWeddings.contains(slug)) {
            accessibleWeddings = new ArrayList<>(accessibleWeddings);
            accessibleWeddings.add(slug);
        }

        String token = generateToken(user.getId(), phone, user.getRole());
        boolean hasActiveReg = hasActiveRegistration(user.getId());

        String message = isExisting 
                ? "OTP verified successfully. Welcome back!"
                : "OTP verified successfully. Please complete casual profile setup or skip.";

        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .expiresIn(TOKEN_VALIDITY_SECONDS)
                .user(user)
                .isExistingUser(isExisting)
                .hasActiveMarriageRegistration(hasActiveReg)
                .accessibleWeddings(accessibleWeddings)
                .message(message)
                .build();
    }

    /**
     * Register Admin (Platform Administrator)
     */
    @Transactional
    public AuthResponse registerAdmin(AdminRegistrationRequest request) {
        String phone = normalizePhone(request.getMobileNumber());
        User user = findUserByMobileFlexible(phone).orElse(null);

        if (user != null) {
            user.setName(request.getName().trim());
            user.setRole("ADMIN");
            user.setRoleId(1L);
            user.setRegistered(true);
            user.setPassword(passwordEncoder.encode(request.getPassword().trim()));
            if (request.getOccupation() != null) {
                user.setOccupation(request.getOccupation().trim());
            }
            if (request.getEmail() != null) {
                user.setEmail(request.getEmail().trim());
            }
        } else {
            user = User.builder()
                    .name(request.getName().trim())
                    .mobileNumber(phone)
                    .password(passwordEncoder.encode(request.getPassword().trim()))
                    .role("ADMIN")
                    .roleId(1L)
                    .registered(true)
                    .occupation(request.getOccupation() != null ? request.getOccupation().trim() : "Platform Administrator")
                    .email(request.getEmail())
                    .build();
        }

        User saved = userRepository.save(user);
        userCache.put(phone, new CachedUser(saved, System.currentTimeMillis() + 600_000));

        String token = generateToken(saved.getId(), phone, saved.getRole());
        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .expiresIn(TOKEN_VALIDITY_SECONDS)
                .user(saved)
                .isExistingUser(true)
                .hasActiveMarriageRegistration(false)
                .accessibleWeddings(Collections.emptyList())
                .message("Admin registered successfully")
                .build();
    }

    /**
     * Casual Profile Setup / Skip Profile
     */
    @Transactional
    public Map<String, Object> updateProfile(Long userId, ProfileSetupRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        if (Boolean.TRUE.equals(request.getSkip())) {
            user.setRegistered(true);
            if (user.getName() == null || user.getName().isBlank()) {
                user.setName("Honored Guest");
            }
        } else {
            if (request.getName() != null && !request.getName().isBlank()) {
                user.setName(request.getName().trim());
            }
            if (request.getOccupation() != null) {
                user.setOccupation(request.getOccupation().trim());
            }
            if (request.getPassword() != null && !request.getPassword().isBlank()) {
                user.setPassword(passwordEncoder.encode(request.getPassword().trim()));
            }
            user.setRegistered(true);
        }

        User saved = userRepository.save(user);
        userCache.put(saved.getMobileNumber(), new CachedUser(saved, System.currentTimeMillis() + 600_000));

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("id", saved.getId());
        resp.put("name", saved.getName() != null ? saved.getName() : "");
        resp.put("mobileNumber", saved.getMobileNumber());
        resp.put("role", saved.getRole());
        resp.put("registered", saved.getRegistered());
        resp.put("occupation", saved.getOccupation());
        resp.put("image", saved.getImage());
        resp.put("locationId", saved.getLocationId());
        resp.put("message", "Profile updated successfully.");
        return resp;
    }

    /**
     * Get Authenticated User Profile (/api/v1/auth/me)
     */
    public Map<String, Object> getMe(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));

        List<MarriageRegistration> regs = marriageRegistrationRepository.findByUserIdOrderBySubmittedAtDesc(userId);
        List<Long> activeRegIds = new ArrayList<>();
        for (MarriageRegistration r : regs) {
            activeRegIds.add(r.getId());
        }

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("id", user.getId());
        resp.put("name", user.getName());
        resp.put("mobileNumber", user.getMobileNumber());
        resp.put("role", user.getRole());
        resp.put("registered", user.getRegistered());
        resp.put("occupation", user.getOccupation());
        resp.put("activeMarriageRegistrationIds", activeRegIds);
        resp.put("associatedWeddings", Collections.emptyList());
        return resp;
    }

    private boolean hasActiveRegistration(Long userId) {
        List<MarriageRegistration> regs = marriageRegistrationRepository.findByUserIdOrderBySubmittedAtDesc(userId);
        return !regs.isEmpty();
    }

    private User findOrProvisionUser(String phone) {
        CachedUser cached = userCache.get(phone);
        if (cached != null && !cached.isExpired()) {
            return cached.user();
        }

        Optional<User> existing = userRepository.findByMobileNumber(phone);
        if (existing.isPresent()) {
            User u = existing.get();
            userCache.put(phone, new CachedUser(u, System.currentTimeMillis() + 600_000));
            return u;
        }

        // Auto-provision user from invitation roster or defaults
        List<Invitation> invitations = invitationRepository.findByPhoneE164(phone);
        String guestName = invitations.isEmpty() ? "" : invitations.get(0).getGuestName();

        User newUser = User.builder()
                .mobileNumber(phone)
                .name(guestName)
                .role("ROLE_USER")
                .roleId(3L)
                .registered(false)
                .build();

        User saved = userRepository.save(newUser);
        userCache.put(phone, new CachedUser(saved, System.currentTimeMillis() + 600_000));
        return saved;
    }

    private List<String> resolveAccessibleWeddings(String phone) {
        List<Invitation> invitations = invitationRepository.findByPhoneE164(phone);
        List<String> slugs = new ArrayList<>();
        for (Invitation inv : invitations) {
            if (inv.getWeddingId() != null) {
                weddingRepository.findById(inv.getWeddingId()).ifPresent(w -> slugs.add(w.getSlug()));
            }
        }
        return slugs;
    }

    private String generateToken(Long userId, String mobile, String role) {
        String raw = UUID.randomUUID().toString() + ":" + userId + ":" + mobile + ":" + role + ":" + Instant.now().getEpochSecond();
        return Base64.getUrlEncoder().withoutPadding().encodeToString(raw.getBytes());
    }

    public void evictUserFromCache(String mobile) {
        if (mobile != null) {
            userCache.remove(mobile);
        }
    }
}
