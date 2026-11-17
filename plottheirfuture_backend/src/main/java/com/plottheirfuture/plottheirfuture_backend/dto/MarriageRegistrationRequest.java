package com.plottheirfuture.plottheirfuture_backend.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MarriageRegistrationRequest {

    @NotNull(message = "Bride details are required")
    @Valid
    private PersonDto bride;

    @NotNull(message = "Groom details are required")
    @Valid
    private PersonDto groom;

    @NotBlank(message = "Primary contact number is required")
    private String primaryContactNumber;

    private String secondaryContactNumber;

    @NotNull(message = "Wedding date is required")
    private LocalDate weddingDate;

    @NotBlank(message = "City is required")
    private String city;

    private String coupleStory;

    private String coverImageUrl;

    @NotBlank(message = "Wedding card URL is required")
    private String weddingCardUrl;

    private String weddingCardThumbnailUrl;

    private String targetBhk;

    private String preferredArea;

    private String videoStreamUrl;

    private String invitationVideoUrl;

    @Builder.Default
    private List<MarriageCeremonyDto> functions = new ArrayList<>();
}

