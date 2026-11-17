package com.plottheirfuture.plottheirfuture_backend.controller;

import com.plottheirfuture.plottheirfuture_backend.entity.Wedding;
import com.plottheirfuture.plottheirfuture_backend.entity.WeddingStatus;
import com.plottheirfuture.plottheirfuture_backend.service.WeddingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
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
@RequestMapping("/api/v1/weddings")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class WeddingController {

    private final WeddingService weddingService;

    @GetMapping
    public ResponseEntity<List<Wedding>> getAllWeddings() {
        return ResponseEntity.ok(weddingService.getAllWeddings());
    }

    @GetMapping("/{id}")
    public ResponseEntity<Wedding> getWeddingById(@PathVariable Long id) {
        return ResponseEntity.ok(weddingService.getWeddingById(id));
    }

    /**
     * Section 5.1: Get Public Wedding Details by Slug
     */
    @GetMapping("/slug/{slug}")
    public ResponseEntity<Map<String, Object>> getWeddingBySlug(@PathVariable String slug) {
        return ResponseEntity.ok(weddingService.getPublicWeddingDossier(slug));
    }

    /**
     * Section 5.2: Get Chronological Ceremony Itinerary
     */
    @GetMapping("/slug/{slug}/ceremonies")
    public ResponseEntity<List<Map<String, Object>>> getCeremoniesBySlug(@PathVariable String slug) {
        return ResponseEntity.ok(weddingService.getChronologicalCeremoniesBySlug(slug));
    }

    /**
     * Section 5.3: Get Interactive Floor Plan Grid & Zone Matrix by Slug
     */
    @GetMapping("/slug/{slug}/floor-plan-zones")
    public ResponseEntity<List<Map<String, Object>>> getFloorPlanZonesBySlug(@PathVariable String slug) {
        return ResponseEntity.ok(weddingService.getFloorPlanZonesBySlug(slug));
    }

    /**
     * Section 5.4: WhatsApp / Social Share Preview Metadata
     */
    @GetMapping("/slug/{slug}/share-preview")
    public ResponseEntity<Map<String, Object>> getSharePreview(@PathVariable String slug) {
        return ResponseEntity.ok(weddingService.getSharePreview(slug));
    }

    @GetMapping("/status")
    public ResponseEntity<List<Wedding>> getWeddingsByStatus(@RequestParam WeddingStatus status) {
        return ResponseEntity.ok(weddingService.getWeddingsByStatus(status));
    }

    @PostMapping
    public ResponseEntity<Wedding> createWedding(@Valid @RequestBody Wedding wedding) {
        return ResponseEntity.status(HttpStatus.CREATED).body(weddingService.createWedding(wedding));
    }

    @PutMapping("/{id}")
    public ResponseEntity<Wedding> updateWedding(@PathVariable Long id, @RequestBody Wedding wedding) {
        return ResponseEntity.ok(weddingService.updateWedding(id, wedding));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteWedding(@PathVariable Long id) {
        weddingService.deleteWedding(id);
        return ResponseEntity.noContent().build();
    }
}
