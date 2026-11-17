package com.plottheirfuture.plottheirfuture_backend.controller;

import com.plottheirfuture.plottheirfuture_backend.dto.MarriageRegistrationRequest;
import com.plottheirfuture.plottheirfuture_backend.service.MarriageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Base64;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/marriages")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class MarriageController {

    private final MarriageService marriageService;

    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> submitRegistration(
            @Valid @RequestBody MarriageRegistrationRequest request,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        Long userId = extractUserIdFromHeader(authHeader);
        return ResponseEntity.status(HttpStatus.CREATED).body(marriageService.submitRegistration(request, userId));
    }

    @GetMapping("/my-registrations")
    public ResponseEntity<List<Map<String, Object>>> getMyRegistrations(
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        Long userId = extractUserIdFromHeader(authHeader);
        return ResponseEntity.ok(marriageService.getMyRegistrations(userId));
    }

    @GetMapping("/{registrationId}")
    public ResponseEntity<Map<String, Object>> getRegistrationById(@PathVariable Long registrationId) {
        return ResponseEntity.ok(marriageService.getRegistrationById(registrationId));
    }

    @PutMapping("/{registrationId}")
    public ResponseEntity<Map<String, Object>> updateRegistration(
            @PathVariable Long registrationId,
            @RequestBody MarriageRegistrationRequest request) {
        return ResponseEntity.ok(marriageService.updateRegistration(registrationId, request));
    }

    @GetMapping("/{registrationId}/share-info")
    public ResponseEntity<Map<String, Object>> getShareInfo(@PathVariable Long registrationId) {
        return ResponseEntity.ok(marriageService.getShareInfo(registrationId));
    }

    private Long extractUserIdFromHeader(String authHeader) {
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            try {
                String decoded = new String(Base64.getUrlDecoder().decode(token));
                String[] parts = decoded.split(":");
                if (parts.length >= 2) {
                    return Long.parseLong(parts[1]);
                }
            } catch (Exception ignored) {}
        }
        return 1L;
    }
}

