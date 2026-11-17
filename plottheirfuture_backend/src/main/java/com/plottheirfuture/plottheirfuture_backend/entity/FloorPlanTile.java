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
import jakarta.persistence.Version;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "floor_plan_tiles", indexes = {
        @Index(name = "idx_tile_wedding_status", columnList = "wedding_id, status"),
        @Index(name = "idx_tile_wedding_zone", columnList = "wedding_id, zone_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FloorPlanTile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "wedding_id", nullable = false)
    private Long weddingId;

    @Column(name = "zone_id", nullable = false)
    private Long zoneId;

    @Column(name = "tile_number")
    private Integer tileNumber;

    @Column(name = "sft_size", nullable = false)
    @Builder.Default
    private Integer sftSize = 1;

    @Enumerated(EnumType.STRING)
    @Column(name = "status")
    @Builder.Default
    private TileStatus status = TileStatus.OPEN;

    @Column(name = "contributor_name")
    private String contributorName;

    @Column(name = "blessing", length = 1000)
    private String blessing;

    @Column(name = "locked_until")
    private LocalDateTime lockedUntil;

    @Column(name = "locked_by_phone")
    private String lockedByPhone;

    @Column(name = "donor_id")
    private Long donorId;

    @Version
    @Column(name = "version")
    private Long version;
}
