package com.plottheirfuture.plottheirfuture_backend.controller;

import com.plottheirfuture.plottheirfuture_backend.dto.FlatDto;
import com.plottheirfuture.plottheirfuture_backend.dto.FlatSectionDto;
import com.plottheirfuture.plottheirfuture_backend.entity.FlatStatus;
import com.plottheirfuture.plottheirfuture_backend.service.FlatService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class FlatController {

    private final FlatService flatService;

    // Public / Shared: List approved flats
    @GetMapping("/flats")
    public ResponseEntity<List<FlatDto>> getApprovedFlats(
            @RequestParam(value = "status", required = false) FlatStatus status) {
        return ResponseEntity.ok(flatService.getAllFlats(status));
    }

    // Public / Shared: Get single flat with full sections
    @GetMapping("/flats/{id}")
    public ResponseEntity<FlatDto> getFlatById(@PathVariable Long id) {
        return ResponseEntity.ok(flatService.getFlatById(id));
    }

    // ==========================================
    // ADMIN ENDPOINTS (/api/v1/admin/flats)
    // ==========================================

    @GetMapping("/admin/flats")
    public ResponseEntity<Page<FlatDto>> searchAdminFlats(
            @RequestParam(value = "status", required = false) FlatStatus status,
            @RequestParam(value = "query", required = false) String query,
            @RequestParam(value = "page", defaultValue = "0") int page,
            @RequestParam(value = "size", defaultValue = "20") int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
        return ResponseEntity.ok(flatService.searchFlats(status, query, pageable));
    }

    @PostMapping("/admin/flats")
    public ResponseEntity<FlatDto> createFlat(@Valid @RequestBody FlatDto dto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(flatService.createFlat(dto));
    }

    @PutMapping("/admin/flats/{id}")
    public ResponseEntity<FlatDto> updateFlat(@PathVariable Long id, @RequestBody FlatDto dto) {
        return ResponseEntity.ok(flatService.updateFlat(id, dto));
    }

    @DeleteMapping("/admin/flats/{id}")
    public ResponseEntity<Map<String, String>> deleteFlat(@PathVariable Long id) {
        flatService.deleteFlat(id);
        return ResponseEntity.ok(Map.of("message", "Flat deleted successfully", "id", String.valueOf(id)));
    }

    // Dynamic Sections Management
    @PostMapping("/admin/flats/{id}/sections")
    public ResponseEntity<FlatSectionDto> addSection(@PathVariable Long id, @Valid @RequestBody FlatSectionDto secDto) {
        return ResponseEntity.status(HttpStatus.CREATED).body(flatService.addSection(id, secDto));
    }

    @PutMapping("/admin/flats/{id}/sections/{sectionId}")
    public ResponseEntity<FlatSectionDto> updateSection(@PathVariable Long id,
                                                        @PathVariable Long sectionId,
                                                        @RequestBody FlatSectionDto secDto) {
        return ResponseEntity.ok(flatService.updateSection(id, sectionId, secDto));
    }

    @DeleteMapping("/admin/flats/{id}/sections/{sectionId}")
    public ResponseEntity<Map<String, String>> deleteSection(@PathVariable Long id,
                                                             @PathVariable Long sectionId) {
        flatService.deleteSection(id, sectionId);
        return ResponseEntity.ok(Map.of("message", "Section removed successfully", "sectionId", String.valueOf(sectionId)));
    }

    // Workflow Actions
    @PostMapping("/admin/flats/{id}/submit")
    public ResponseEntity<FlatDto> submitForApproval(@PathVariable Long id) {
        return ResponseEntity.ok(flatService.submitForApproval(id));
    }

    @PostMapping("/admin/flats/{id}/approve")
    public ResponseEntity<FlatDto> approveFlat(@PathVariable Long id,
                                               @RequestParam(value = "adminId", defaultValue = "1") Long adminId) {
        return ResponseEntity.ok(flatService.approveFlat(id, adminId));
    }

    @PostMapping("/admin/flats/{id}/reject")
    public ResponseEntity<FlatDto> rejectFlat(@PathVariable Long id,
                                              @RequestBody(required = false) Map<String, String> body) {
        String reason = (body != null) ? body.get("reason") : "Section area mismatch or missing documentation";
        return ResponseEntity.ok(flatService.rejectFlat(id, reason));
    }

    @PostMapping("/admin/flats/{id}/assign-wedding")
    public ResponseEntity<FlatDto> assignFlatToWedding(@PathVariable Long id,
                                                       @RequestBody Map<String, Long> payload) {
        Long weddingId = payload.get("weddingId");
        if (weddingId == null) {
            throw new IllegalArgumentException("weddingId is required");
        }
        return ResponseEntity.ok(flatService.assignFlatToWedding(id, weddingId));
    }
}
