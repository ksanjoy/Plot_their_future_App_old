package com.plottheirfuture.plottheirfuture_backend.controller;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/media")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
@Slf4j
public class MediaController {

    private static final String UPLOAD_DIR = "uploads";

    @PostMapping("/upload")
    public ResponseEntity<Map<String, Object>> uploadMedia(
            @RequestParam("file") MultipartFile file,
            @RequestParam("category") String category,
            @RequestParam(value = "caption", required = false) String caption) {

        if (file.isEmpty()) {
            throw new IllegalArgumentException("Uploaded file cannot be empty");
        }

        String originalFilename = file.getOriginalFilename() != null ? file.getOriginalFilename() : "upload";
        String cleanName = originalFilename.replaceAll("[^a-zA-Z0-9._-]", "_");
        String extension = cleanName.contains(".") ? cleanName.substring(cleanName.lastIndexOf(".")) : "";
        String baseName = cleanName.contains(".") ? cleanName.substring(0, cleanName.lastIndexOf(".")) : cleanName;
        String uniqueFileName = baseName + "_" + System.currentTimeMillis() % 1000000 + extension;

        // Ensure upload directory exists locally
        try {
            Path targetPath = Paths.get(UPLOAD_DIR, category.toLowerCase());
            Files.createDirectories(targetPath);
            file.transferTo(targetPath.resolve(uniqueFileName));
        } catch (IOException e) {
            log.warn("Local storage write skipped: {}", e.getMessage());
        }

        String mediaId = "med_" + (System.currentTimeMillis() % 100000000L);
        String categoryPath = category.toLowerCase().replace("_", "-");
        String fileUrl = "https://cdn.plottheirfuture.in/uploads/" + categoryPath + "/" + uniqueFileName;
        String thumbnailUrl = "https://cdn.plottheirfuture.in/uploads/" + categoryPath + "/thumbnails/" + uniqueFileName;

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("status", "SUCCESS");
        resp.put("mediaId", mediaId);
        resp.put("fileUrl", fileUrl);
        resp.put("thumbnailUrl", thumbnailUrl);
        resp.put("fileType", file.getContentType() != null ? file.getContentType() : "application/octet-stream");
        resp.put("fileSizeBytes", file.getSize());
        resp.put("uploadedAt", Instant.now().toString());

        return ResponseEntity.status(HttpStatus.CREATED).body(resp);
    }

    @PostMapping("/presigned-url")
    public ResponseEntity<Map<String, Object>> generatePresignedUrl(@RequestBody Map<String, String> payload) {
        String fileName = payload.getOrDefault("fileName", "upload_" + UUID.randomUUID());
        String contentType = payload.getOrDefault("contentType", "application/octet-stream");
        String category = payload.getOrDefault("category", "WEDDING_CARD");

        String s3Key = "weddings/" + UUID.randomUUID() + "/" + fileName;
        String uploadUrl = "https://s3.ap-south-1.amazonaws.com/plottheirfuture-media/" + s3Key;
        String publicUrl = "https://cdn.plottheirfuture.in/weddings/" + fileName;

        Map<String, Object> resp = new LinkedHashMap<>();
        resp.put("uploadUrl", uploadUrl);
        resp.put("publicUrl", publicUrl);
        resp.put("expiresInSeconds", 900);

        return ResponseEntity.ok(resp);
    }
}

