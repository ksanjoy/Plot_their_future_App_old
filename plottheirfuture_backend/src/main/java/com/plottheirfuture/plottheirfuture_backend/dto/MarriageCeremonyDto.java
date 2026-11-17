package com.plottheirfuture.plottheirfuture_backend.dto;

import com.plottheirfuture.plottheirfuture_backend.entity.CeremonyType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class MarriageCeremonyDto {

    private Long id;

    private CeremonyType ceremonyType;

    private String name;

    @Builder.Default
    private Boolean isEnabled = true;

    private LocalDate eventDate;

    private LocalTime startTime;

    private LocalTime endTime;

    private String venueName;

    private String venueAddress;

    private String venueMapUrl;

    private String ceremonyImageUrl;

    private String dressCode;

    private String notes;
}

