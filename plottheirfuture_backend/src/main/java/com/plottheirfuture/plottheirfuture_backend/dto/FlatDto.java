package com.plottheirfuture.plottheirfuture_backend.dto;

import com.plottheirfuture.plottheirfuture_backend.entity.FlatStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class FlatDto {
    private Long id;
    private String flatId;

    @NotBlank(message = "Flat name is required")
    private String name;

    private String description;
    private String coverImageUrl;
    private List<String> galleryImages;

    @NotNull(message = "Built-up area is required")
    private Integer builtUpAreaSft;

    @NotNull(message = "Carpet area is required")
    private Integer carpetAreaSft;

    private Integer bedrooms;
    private Integer bathrooms;
    private Integer balconies;
    private Integer halls;
    private Integer kitchens;
    private String location;
    private String address;

    private Double pricePerSft;
    private Integer bricksPerSft;
    private Double pricePerBrick;

    private FlatStatus status;
    private Long assignedWeddingId;
    private String assignedWeddingSlug;
    private String rejectionReason;

    private List<FlatSectionDto> sections;
    private Integer totalSectionArea;
    private Boolean areaMatches;
    private Integer totalGiftedSft;
    private Integer totalRemainingSft;
    private Double totalTargetAmount;
    private Double totalGiftedAmount;
    private Integer totalBricksEquivalent;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private LocalDateTime approvedAt;
    private Long approvedByAdminId;
}
