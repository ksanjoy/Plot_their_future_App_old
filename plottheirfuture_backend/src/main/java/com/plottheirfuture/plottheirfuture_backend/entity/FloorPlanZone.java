package com.plottheirfuture.plottheirfuture_backend.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "floor_plan_zones", indexes = {
        @Index(name = "idx_zone_wedding", columnList = "wedding_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FloorPlanZone {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "wedding_id", nullable = false)
    private Long weddingId;

    @Column(name = "room_name", nullable = false)
    private String roomName;

    @Column(name = "total_sft", nullable = false)
    private Integer totalSft;

    @Column(name = "funded_sft")
    @Builder.Default
    private Integer fundedSft = 0;

    @Column(name = "color_hex")
    @Builder.Default
    private String colorHex = "#D4AF37";

    @Column(name = "rate_per_sft")
    @Builder.Default
    private Double ratePerSft = 4500.0;

    @Column(name = "svg_element_id")
    private String svgElementId;
}
