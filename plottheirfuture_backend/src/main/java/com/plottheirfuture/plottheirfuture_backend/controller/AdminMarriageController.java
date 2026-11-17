package com.plottheirfuture.plottheirfuture_backend.controller;

import com.plottheirfuture.plottheirfuture_backend.dto.ApproveFlatRequest;
import com.plottheirfuture.plottheirfuture_backend.dto.RejectSubmissionRequest;
import com.plottheirfuture.plottheirfuture_backend.service.MarriageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Base64;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/admin")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AdminMarriageController {

    private final MarriageService marriageService;

    @GetMapping("/dashboard/stats")
    public ResponseEntity<Map<String, Object>> getDashboardStats() {
        return ResponseEntity.ok(marriageService.getAdminDashboardStats());
    }

    @GetMapping("/marriages")
    public ResponseEntity<Map<String, Object>> listMarriages(
            @RequestParam(value = "status", required = false) String status,
            @RequestParam(value = "city", required = false) String city,
            @RequestParam(value = "query", required = false) String query,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "submittedAt"));
        return ResponseEntity.ok(marriageService.listAdminRegistrations(status, city, query, pageable));
    }

    @GetMapping("/marriages/{registrationId}")
    public ResponseEntity<Map<String, Object>> inspectSubmission(@PathVariable Long registrationId) {
        return ResponseEntity.ok(marriageService.getRegistrationById(registrationId));
    }

    @PostMapping("/marriages/{registrationId}/approve-and-assign-flat")
    public ResponseEntity<Map<String, Object>> approveAndAssignFlat(
            @PathVariable Long registrationId,
            @Valid @RequestBody ApproveFlatRequest request,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        Long adminId = extractAdminIdFromHeader(authHeader);
        return ResponseEntity.ok(marriageService.approveAndAssignFlat(registrationId, request, adminId));
    }

    @PostMapping("/marriages/{registrationId}/reject")
    public ResponseEntity<Map<String, Object>> rejectSubmission(
            @PathVariable Long registrationId,
            @Valid @RequestBody RejectSubmissionRequest request,
            @RequestHeader(value = "Authorization", required = false) String authHeader) {
        Long adminId = extractAdminIdFromHeader(authHeader);
        return ResponseEntity.ok(marriageService.rejectRegistration(registrationId, request, adminId));
    }

    @PutMapping("/marriages/{registrationId}/flat")
    public ResponseEntity<Map<String, Object>> reconfigureFlat(
            @PathVariable Long registrationId,
            @RequestBody ApproveFlatRequest request) {
        return ResponseEntity.ok(marriageService.reconfigureFlat(registrationId, request));
    }

    private Long extractAdminIdFromHeader(String authHeader) {
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

