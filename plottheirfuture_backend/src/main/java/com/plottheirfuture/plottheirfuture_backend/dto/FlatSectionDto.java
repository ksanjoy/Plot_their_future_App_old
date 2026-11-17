package com.plottheirfuture.plottheirfuture_backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FlatSectionDto {
    private Long id;
    private Long flatId;

    @NotBlank(message = "Section name is required")
    private String sectionName;

    private String sectionImageUrl;
    private String description;

    @NotNull(message = "Section area is required")
    private Integer areaSft;

    private Double lengthFt;
    private Double widthFt;

    private Double pricePerSft;
    private Double totalPrice;
    private Integer giftedSft;
    private Integer remainingSft;
    private Integer brickEquivalent;
    private Double giftProgressPercent;
    private String svgElementId;
}
