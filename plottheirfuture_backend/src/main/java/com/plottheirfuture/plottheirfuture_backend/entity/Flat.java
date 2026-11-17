package com.plottheirfuture.plottheirfuture_backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "flats", indexes = {
        @Index(name = "idx_flat_code", columnList = "flat_id"),
        @Index(name = "idx_flat_status", columnList = "status"),
        @Index(name = "idx_flat_assigned_wedding", columnList = "assigned_wedding_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Flat {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "flat_id", unique = true, nullable = false, length = 64)
    private String flatId;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "description", length = 3000)
    private String description;

    @Column(name = "cover_image_url")
    private String coverImageUrl;

    @Column(name = "gallery_images_json", columnDefinition = "TEXT")
    private String galleryImagesJson;

    @Column(name = "built_up_area_sft", nullable = false)
    private Integer builtUpAreaSft;

    @Column(name = "carpet_area_sft", nullable = false)
    private Integer carpetAreaSft;

    @Column(name = "bedrooms")
    @Builder.Default
    private Integer bedrooms = 2;

    @Column(name = "bathrooms")
    @Builder.Default
    private Integer bathrooms = 2;

    @Column(name = "balconies")
    @Builder.Default
    private Integer balconies = 1;

    @Column(name = "halls")
    @Builder.Default
    private Integer halls = 1;

    @Column(name = "kitchens")
    @Builder.Default
    private Integer kitchens = 1;

    @Column(name = "location")
    private String location;

    @Column(name = "address", length = 1000)
    private String address;

    @Column(name = "price_per_sft")
    @Builder.Default
    private Double pricePerSft = 4500.0;

    @Column(name = "bricks_per_sft")
    @Builder.Default
    private Integer bricksPerSft = 10;

    @Column(name = "price_per_brick")
    @Builder.Default
    private Double pricePerBrick = 450.0;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    @Builder.Default
    private FlatStatus status = FlatStatus.DRAFT;

    @Column(name = "assigned_wedding_id")
    private Long assignedWeddingId;

    @Column(name = "assigned_wedding_slug")
    private String assignedWeddingSlug;

    @Column(name = "rejection_reason", length = 1000)
    private String rejectionReason;

    @Column(name = "created_at")
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    @Column(name = "approved_by_admin_id")
    private Long approvedByAdminId;
}
