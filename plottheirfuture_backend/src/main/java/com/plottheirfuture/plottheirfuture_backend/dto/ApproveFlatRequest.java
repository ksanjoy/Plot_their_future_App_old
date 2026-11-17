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
public class ApproveFlatRequest {

    @NotBlank(message = "Slug is required")
    private String slug;

    @NotBlank(message = "Builder name is required")
    private String builderName;

    @NotBlank(message = "Project name is required")
    private String projectName;

    private String tower;

    @NotBlank(message = "Unit number is required")
    private String unitNumber;

    @NotBlank(message = "Configuration is required")
    private String configuration;

    @NotNull(message = "Target SFT is required")
    private Integer targetSft;

    @NotNull(message = "Rate per SFT is required")
    private Double rateSft;

    @NotBlank(message = "Builder RERA ID is required")
    private String builderReraId;

    private String reraProjectUrl;

    private EscrowBankDto escrowBank;

    private String floorPlanTemplate;

    private String videoStreamUrl;

    private String adminNotes;

    private String flatId;
}

