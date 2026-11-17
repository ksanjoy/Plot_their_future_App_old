package com.plottheirfuture.plottheirfuture_backend.controller;

import com.plottheirfuture.plottheirfuture_backend.dto.SectionGiftingRequest;
import com.plottheirfuture.plottheirfuture_backend.service.SectionGiftingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/weddings")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class SectionGiftingController {

    private final SectionGiftingService sectionGiftingService;

    @GetMapping("/{slug}/sections")
    public ResponseEntity<Map<String, Object>> getWeddingSections(@PathVariable String slug) {
        return ResponseEntity.ok(sectionGiftingService.getWeddingSections(slug));
    }

    @PostMapping("/{slug}/gift-section")
    public ResponseEntity<Map<String, Object>> giftSection(@PathVariable String slug,
                                                           @Valid @RequestBody SectionGiftingRequest request) {
        return ResponseEntity.ok(sectionGiftingService.giftSection(slug, request));
    }
}
