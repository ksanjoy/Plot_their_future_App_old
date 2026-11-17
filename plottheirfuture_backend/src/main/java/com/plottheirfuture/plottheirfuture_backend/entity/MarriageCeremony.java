package com.plottheirfuture.plottheirfuture_backend.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

import java.time.LocalDate;
import java.time.LocalTime;

@Entity
@Table(name = "marriage_ceremonies", indexes = {
        @Index(name = "idx_cer_reg_id", columnList = "registration_id")
})
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MarriageCeremony {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "registration_id", nullable = false)
    @JsonIgnore
    @ToString.Exclude
    private MarriageRegistration marriageRegistration;

    @Enumerated(EnumType.STRING)
    @Column(name = "ceremony_type", nullable = false)
    private CeremonyType ceremonyType;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "is_enabled")
    @Builder.Default
    private Boolean isEnabled = true;

    @Column(name = "event_date")
    private LocalDate eventDate;

    @Column(name = "start_time")
    private LocalTime startTime;

    @Column(name = "end_time")
    private LocalTime endTime;

    @Column(name = "venue_name")
    private String venueName;

    @Column(name = "venue_address", length = 1000)
    private String venueAddress;

    @Column(name = "venue_map_url")
    private String venueMapUrl;

    @Column(name = "ceremony_image_url")
    private String ceremonyImageUrl;

    @Column(name = "dress_code")
    private String dressCode;

    @Column(name = "notes", length = 1000)
    private String notes;
}

