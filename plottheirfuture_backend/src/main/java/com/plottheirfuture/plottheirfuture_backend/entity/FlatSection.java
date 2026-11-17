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
@Table(name = "flat_sections", indexes = {
        @Index(name = "idx_section_flat", columnList = "flat_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class FlatSection {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "flat_id", nullable = false)
    private Long flatId;

    @Column(name = "section_name", nullable = false)
    private String sectionName;

    @Column(name = "section_image_url")
    private String sectionImageUrl;

    @Column(name = "description", length = 1000)
    private String description;

    @Column(name = "area_sft", nullable = false)
    private Integer areaSft;

    @Column(name = "length_ft")
    private Double lengthFt;

    @Column(name = "width_ft")
    private Double widthFt;

    @Column(name = "price_per_sft", nullable = false)
    private Double pricePerSft;

    @Column(name = "total_price", nullable = false)
    private Double totalPrice;

    @Column(name = "gifted_sft")
    @Builder.Default
    private Integer giftedSft = 0;

    @Column(name = "svg_element_id")
    private String svgElementId;

    public Integer getRemainingSft() {
        int gifted = (giftedSft != null) ? giftedSft : 0;
        int total = (areaSft != null) ? areaSft : 0;
        return Math.max(0, total - gifted);
    }
}
